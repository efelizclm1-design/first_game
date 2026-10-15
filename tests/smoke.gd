extends SceneTree
## Deterministic integration suite. No user save is read or written.
const Game = preload("res://scripts/game.gd")
const World = preload("res://scripts/world.gd")
var g
var passed = 0
var failed = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL " + label)

func arena(index: int = 0) -> void:
	g.begin_level(index)
	g.change_state("play")
	g.tutorial_active = false
	g.invincible = 0
	g.test_axis = 0
	g.settings.auto_fire = false
	g.rng.seed = 1200+index

func tick(seconds: float) -> void:
	for i in range(int(seconds*60)):
		if g.state=="play":g.step_game(1.0/60)
		g.step_particles(1.0/60)

func run() -> void:
	g = Game.new()
	g.test_mode = true
	g.save_enabled = false
	root.add_child(g)
	g.settings.sound = false
	g.set_process(false)
	check(g.state=="title","Project boots into title")
	check(not ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"),"Native touch does not also trigger mouse actions")
	check(World.TAUNTS.size()>15,"More than 15 defeat phrases")
	for z in range(5):check(World.ZONES[z].objects.size()==16,"Zone %d has 16 named hazard variants" % z)
	var boss_count = 0
	for i in range(20):
		var d = World.level(i)
		if d.boss:boss_count += 1
		check(d.zone == i/4 and d.duration>0,"Level %02d configuration" % (i+1))
	check(boss_count==5,"Five zone-final bosses")
	arena()
	g.test_axis = 1
	tick(.3)
	check(g.p.x>195,"Movement advances player")
	g.jump()
	tick(.12)
	var before = g.p.y
	check(before<g.FLOOR-20,"Jump leaves ground")
	g.jump()
	check(g.jumps==2 and g.velocity.y<0,"Second jump re-launches player")
	g.jump()
	check(g.jumps==2,"Third air jump is rejected")
	g.test_axis = 0
	tick(1.3)
	check(g.p.y==g.FLOOR and g.jumps==0,"Landing resets jump budget")
	g.dash()
	check(g.dash_time>0 and g.invincible>0,"Dash starts with invulnerability")
	var cooldown = g.dash_cooldown
	g.dash()
	check(g.dash_cooldown==cooldown,"Dash cannot bypass cooldown")
	arena()
	var upper = Rect2(g.p.x-8,252,16,16)
	check(g.player_rect().intersects(upper),"Upper shot hits standing hitbox")
	g.ducking = true
	check(not g.player_rect().intersects(upper),"Crouching avoids upper shot")
	g.ducking = false
	g.hurt("test")
	check(g.hp==2 and g.invincible>0,"Damage removes exactly one heart")
	g.hurt("test")
	check(g.hp==2,"Recovery frames prevent repeated contact damage")
	g.invincible = 0
	g.apply_pickup("shield")
	g.hurt("test")
	check(g.hp==2 and g.shield==0,"Shield absorbs one hit")
	g.apply_pickup("heal")
	g.apply_pickup("heal")
	check(g.hp==3,"Healing is capped at three hearts")
	g.apply_pickup("slow")
	g.apply_pickup("rapid")
	check(g.slow_time==6 and g.rapid_time==7,"Slow time and rapid fire activate")
	for i in range(3):
		g.invincible = 0
		g.hurt("test")
	check(g.state=="dead" and g.hp==0,"Three hits lead to defeat")
	check(not g.death_message.is_empty(),"Defeat chooses a phrase")
	g.activate("retry")
	check(g.hp==3 and g.state=="loading","Retry resets lives and loads same arena")
	arena()
	g.spawn_hazard(2,1,g.p.x)
	g.step_hazards(.2)
	check(g.hp==3,"Telegraphed hazards do not damage early")
	g.hazards[0].wait = 0
	g.step_hazards(.01)
	check(g.hp==2,"Active ground spikes collide")
	arena()
	g.spawn_hazard(0,1,100)
	g.hazards[0].wait=0
	var y0=g.hazards[0].p.y
	g.step_hazards(.1)
	var normal_distance=g.hazards[0].p.y-y0
	arena()
	g.spawn_hazard(0,1,100)
	g.hazards[0].wait=0
	g.slow_time=6
	tick(.1)
	check(g.hazards[0].p.y+20<normal_distance*.6,"Slow powerup actually reduces hazard movement")
	arena(2)
	g.arena_clock=0
	g.step_arena(.01)
	check(g.arena_phase=="warning" and g.arena_left==24,"Terrain warns before shrinking")
	g.step_arena(1.26)
	check(g.arena_phase=="small" and g.arena_left>24,"Terrain shrinks after warning")
	g.step_arena(6.01)
	check(g.arena_phase=="stable" and g.arena_left==24,"Terrain restores after six seconds")
	arena()
	g.spawn_enemy()
	g.enemies[0].age=1
	g.enemies[0].p=Vector2(220,g.FLOOR)
	g.enemies[0].hp=1
	g.shoot()
	for i in range(30):g.step_bullets(1.0/60)
	check(g.enemies.is_empty() and g.kills==1 and g.score==100,"Aimed bullets defeat an enemy and award score")
	arena()
	g.pickups.append({"p":g.p-Vector2(0,12),"kind":"shield","life":5.0})
	g.step_pickups(.01)
	check(g.pickups.is_empty() and g.shield==1,"Touching a falling gift collects it")
	arena(3)
	g.boss.hp=g.boss.max_hp*.4
	g.step_boss(.1,1)
	check(g.boss.phase==2,"Boss switches to second phase below half HP")
	g.boss.hp=0
	g.step_game(.01)
	check(g.state=="victory" and g.unlocked>=4,"Boss defeat unlocks next zone")
	# Run complete survival levels, and 55 seconds of every boss simulation.
	# Invulnerability here deliberately isolates campaign scheduling, separately from damage tests.
	var peak_hazards=0
	var peak_enemies=0
	for index in range(20):
		arena(index)
		g.invincible=1000
		g.settings.auto_fire=true
		var seconds=55 if g.level_data.boss else g.duration+1
		for frame in range(int(seconds*60)):
			if g.state!="play":break
			g.test_axis=1 if (frame/150)%2==0 else -1
			if frame%65==0:g.jump()
			g.step_game(1.0/60)
			g.step_particles(1.0/60)
			peak_hazards=maxi(peak_hazards,g.hazards.size())
			peak_enemies=maxi(peak_enemies,g.enemies.size())
		if g.level_data.boss and g.state=="play":
			check(g.boss_pattern>5,"Boss %d emits repeated attack patterns" % index)
			g.boss.hp=0
			g.step_game(.01)
		check(g.state=="victory","Full level %02d simulation completes" % (index+1))
		check(g.hazards.size()<=g.MAX_HAZARDS and g.enemies.size()<=6 and g.particles.size()<=g.MAX_PARTICLES,"Level %02d keeps entity budgets" % (index+1))
	check(g.medals.size()==20 and g.unlocked==19,"Campaign stores all 20 medals and final unlock")
	g.activate("next")
	check(g.state=="ending","Last victory reaches ending")
	# Save/reload in an isolated user-data directory supplied by the runner.
	g.save_enabled=true
	g.settings.low=true
	g.save_progress()
	g.unlocked=0
	g.medals={}
	g.settings.low=false
	g.load_progress()
	check(g.unlocked==19 and g.medals.size()==20 and g.settings.low,"Save/reload preserves campaign and settings")
	g.save_enabled=false
	g.settings.low=false
	# Independent, simultaneous touch controls are mapped without needing a physical phone.
	arena()
	g.test_mode=false
	g.touches={0:Vector2(82,326),1:Vector2(590,326),2:Vector2(514,326)}
	g.refresh_touches()
	check(g.down("right") and g.down("shoot") and g.jumps==1,"Three-finger input moves, jumps and shoots")
	g.touches.clear()
	g.refresh_touches()
	check(not g.down("right") and not g.down("shoot"),"Touch release clears held actions")
	g.test_mode=true
	g.change_state("pause")
	var frozen=g.elapsed
	g._process(.05)
	check(g.elapsed==frozen,"Pause freezes game timer")
	g.activate("resume")
	check(g.state=="play","Pause resumes the arena")
	g.change_state("map")
	g.unlocked=0
	g.selected=19
	g.activate("start")
	check(g.state=="map","Locked levels cannot be launched from map")
	print("RESULT: %d passed, %d failed. Peak hazards: %d; peak enemies: %d" % [passed,failed,peak_hazards,peak_enemies])
	g.painter.g=null
	g.painter=null
	g.queue_free()
	await process_frame
	await create_timer(.15).timeout
	quit(1 if failed>0 else 0)
