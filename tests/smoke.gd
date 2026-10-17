extends SceneTree
## Integration tests with a separate save file. Difficulty/physics are real production code.
const Game=preload("res://scripts/game.gd")
const World=preload("res://scripts/world.gd")
var g
var passed=0
var failed=0
var peak_hazards=0
var peak_enemies=0

func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok:
  passed+=1
  print("PASS ",label)
 else:
  failed+=1
  push_error("FAIL "+label)
func arena(index: int=0) -> void:
 g.begin_level(index)
 g.change_state("play")
 g.tutorial_active=false
 g.invincible=0
 g.test_axis=0
 g.test_actions={}
 g.settings.auto_fire=false
func tick(seconds: float) -> void:
 for k in range(int(seconds*60)):
  if g.state=="play":g.step_game(1.0/60)
  g.step_particles(1.0/60)
func quiet() -> void:
 g.spawn_clock=999
 g.enemy_clock=999
 g.gift_clock=999
 g.arena_clock=999
 g.lava_clock=999

func run() -> void:
 g=Game.new()
 g.test_mode=true
 g.save_enabled=false
 root.add_child(g)
 g.settings.sound=false
 g.set_process(false)
 g.set_physics_process(false)
 check(g.state=="title","Project boots into retained title")
 check(ProjectSettings.get_setting("display/window/size/viewport_width")==1280,"Combat renders at 1280 x 720")
 check(not ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"),"Touch cannot generate duplicate mouse attacks")
 check(World.SCENES.size()==20 and World.TAUNTS.size()>15,"Twenty scene identities and original defeat phrases preserved")
 for z in range(5):check(World.ZONES[z].objects.size()==16,"Zone %d preserves 16 threat variants" % z)
 for index in range(20):
  var d=World.level(index)
  var start=World.pressure(index,0)
  var finish=World.pressure(index,d.duration)
  var monotonic=true
  var gradual=true
  var minimum_warning=true
  var last=start
  for k in range(1,601):
   var t=d.duration*k/600.0
   var current=World.pressure(index,t)
   monotonic=monotonic and current.speed>=last.speed and current.interval<=last.interval and current.enemy_interval<=last.enemy_interval
   gradual=gradual and current.speed-last.speed<.5
   minimum_warning=minimum_warning and current.warning>=.85
   last=current
  check(monotonic and gradual and minimum_warning,"Level %02d accelerates smoothly and retains reaction time" % (index+1))
  check(finish.speed>start.speed and finish.interval<start.interval,"Level %02d is harder at the end than its own start" % (index+1))
  if index>0:
   var previous=World.level(index-1)
   check(start.speed>World.pressure(index-1,0).speed and finish.speed>World.pressure(index-1,previous.duration).speed and start.interval<World.pressure(index-1,0).interval,"Level %02d grows harder at both endpoints, with no biome reset" % (index+1))
  check(ResourceLoader.exists("res://assets/combat/arena_%02d.png" % index),"Level %02d has its own background asset" % (index+1))
  check(ResourceLoader.exists("res://assets/combat/inhabitants_%02d.png" % index) and World.ENEMIES[index].size()==3,"Level %02d has local enemy artwork and identities" % (index+1))
 arena()
 quiet()
 g.test_axis=-1
 tick(.3)
 check(g.p.x<210 and g.facing==-1,"Moving left changes position and facing")
 g.shoot()
 check(g.bullets[-1].v.x<0 and g.muzzle_flash>0,"Left-facing shot and visible muzzle feedback")
 g.test_axis=1
 tick(.3)
 g.shoot()
 check(g.facing==1 and g.bullets[-1].v.x>0,"Moving right flips both character and attack")
 g.test_axis=0
 g.jump()
 tick(.12)
 check(g.p.y<g.FLOOR-30,"Jump has visible height")
 g.jump()
 check(g.jumps==2 and g.velocity.y<0,"Double jump re-launches the player")
 g.jump()
 check(g.jumps==2,"A third jump is rejected")
 tick(1.5)
 check(g.grounded and g.jumps==0 and g.p.y==g.FLOOR,"Landing resets jump budget")
 g.dash()
 check(g.dash_time>0 and g.invincible>0,"Dash begins with invulnerability")
 var cd=g.dash_cooldown
 g.dash()
 check(g.dash_cooldown==cd,"Dash cannot bypass its recharge")
 arena(1)
 quiet()
 var platform=g.platforms[0]
 g.p=Vector2(platform.get_center().x,platform.position.y-45)
 g.velocity=Vector2(0,130)
 g.grounded=false
 tick(.3)
 check(g.grounded and g.p.y==platform.position.y,"Player lands on a one-way platform")
 g.test_actions.duck=true
 g.jump()
 tick(.5)
 check(g.p.y>platform.position.y+20,"Down plus jump drops through the platform")
 arena()
 var upper=Rect2(g.p.x-10,g.FLOOR-54,20,20)
 check(g.player_rect().intersects(upper),"High attack hits standing hitbox")
 g.ducking=true
 check(not g.player_rect().intersects(upper),"High attack clears crouched hitbox")
 g.ducking=false
 g.hurt("test")
 check(g.hp==2 and g.invincible>0 and g.hurt_flash>0,"Damage removes one heart and flashes visibly")
 g.hurt("test")
 check(g.hp==2,"Recovery frames prevent repeat contact damage")
 g.invincible=0
 g.apply_pickup("shield")
 g.hurt("test")
 check(g.hp==2 and g.shield==0,"Shield absorbs one hit")
 g.apply_pickup("heal")
 g.apply_pickup("heal")
 check(g.hp==3,"Healing remains capped at three hearts")
 g.apply_pickup("slow")
 g.apply_pickup("rapid")
 check(g.slow_time==6 and g.rapid_time==7,"Slow and rapid pickups work")
 for k in range(3):
  g.invincible=0
  g.hurt("test")
 check(g.state=="dead" and g.hp==0 and not g.death_message.is_empty(),"Three hits lead to defeat and a phrase")
 g.activate("retry")
 check(g.hp==3 and g.state=="loading","Retry restores three lives")
 arena()
 quiet()
 g.spawn_hazard(2,1,g.p.x)
 g.step_hazards(.5)
 check(g.hp==3 and g.hazards[0].wait>0,"Telegraphed spikes cannot damage early")
 g.hazards[0].wait=0
 g.step_hazards(.01)
 check(g.hp==2,"Active spikes collide")
 arena(19)
 quiet()
 g.boss={}
 g.spawn_hazard(0,1,100)
 g.hazards[0].wait=0
 g.hazards[0].p.y=120
 var first_speed=g.hazards[0].v.y
 g.elapsed=g.duration*.8
 tick(.1)
 check(g.hazards[0].v.y>first_speed,"Existing hazards accelerate with the live level curve")
 arena()
 quiet()
 g.spawn_hazard(0,1,100)
 g.hazards[0].wait=0
 g.hazards[0].p.y=100
 tick(.1)
 var normal_distance=g.hazards[0].p.y-100
 arena()
 quiet()
 g.spawn_hazard(0,1,100)
 g.hazards[0].wait=0
 g.hazards[0].p.y=100
 g.slow_time=6
 tick(.1)
 check(absf((g.hazards[0].p.y-100)/normal_distance-.5)<.02,"Slow pickup actually halves threat travel")
 check(Game.segment_hits_rect(Vector2(0,20),Vector2(100,20),Rect2(40,10,5,20)),"Swept collision catches fast projectiles crossing a thin target")
 check(not Game.segment_hits_rect(Vector2(0,40),Vector2(100,40),Rect2(40,10,5,20)),"Swept collision rejects a nearby miss")
 arena(2)
 g.arena_clock=0
 g.step_arena(.01)
 check(g.arena_phase=="warning" and g.arena_left==36,"Terrain warns before its boundary moves")
 g.step_arena(1.66)
 g.step_arena(.35)
 check(g.arena_phase=="shrinking" and g.arena_left>36 and g.arena_left<g.target_left,"Terrain collapses progressively")
 g.step_arena(.36)
 check(g.arena_phase=="small","Terrain reaches its reduced size")
 g.step_arena(6.1)
 g.step_arena(.81)
 check(g.arena_phase=="stable" and g.arena_left==36,"Terrain restores smoothly")
 # Hell floor changes are harmless during warning and only burn at floor contact.
 arena(16)
 quiet()
 g.ignite_floor(g.p.x)
 var patch=g.lava_patches[0]
 g.step_lava(1.0)
 check(patch.state=="warning" and g.hp==3,"Lava warns before damaging the player")
 check(patch.rect.size.x<200 and not g.level_data.shrink,"Lava leaves broad safe floor and does not overlap collapsing edges")
 g.jump()
 tick(.5)
 g.step_lava(.31)
 check(patch.state=="active" and g.hp==3 and g.p.y<g.FLOOR-30,"Jumping from the warned patch avoids active lava without immunity")
 g.p.y=g.FLOOR
 g.grounded=true
 g.invincible=0
 g.step_lava(.01)
 check(g.hp==2 and g.damage_source=="Suelo de lava","Landing on active lava loses a heart")
 g.p.x=patch.rect.end.x+40
 g.invincible=0
 g.step_lava(.02)
 check(g.hp==2,"Standing beside the lava is safe")
 g.step_lava(2.9)
 g.step_lava(.7)
 check(g.lava_patches.is_empty(),"Lava cools and restores ordinary floor")
 # Paradise uses actual thematic attacks, with action-specific counterplay.
 arena(12)
 quiet()
 g.spawn_hazard(1,1,-1,{"left":true,"high":false})
 check(g.hazards[0].name=="Piano celestial" and g.hazards[0].variant==1,"Low heavenly lane uses a piano and its matching sprite")
 g.hazards[0].p=Vector2(g.p.x-115,g.FLOOR-18)
 g.hazards[0].wait=0
 g.jump()
 tick(.42)
 check(g.hp==3,"A timed jump clears a piano without invulnerability")
 arena(12)
 quiet()
 g.spawn_hazard(1,1,-1,{"left":true,"high":true})
 check(g.hazards[0].name=="Flecha angelical","High heavenly lane uses an angel arrow")
 g.hazards[0].p.x=g.p.x-110
 g.hazards[0].wait=0
 g.test_actions.duck=true
 tick(.5)
 check(g.hp==3,"Crouching clears an angel arrow without invulnerability")
 arena()
 quiet()
 g.spawn_enemy(0)
 var e=g.enemies[0]
 var initial=e.p
 g.step_enemies(.3)
 check(e.state=="spawn" and g.hazards.is_empty(),"Enemy arrival is telegraphed before attacks")
 e.state="patrol"
 e.timer=.001
 g.step_enemies(.01)
 check(e.state=="windup" and e.timer>=.86 and g.hazards.is_empty(),"Enemy visibly winds up before shooting")
 var locked=e.locked
 g.p.x+=140
 g.step_enemies(e.timer+.01)
 check(e.state=="attack" and g.hazards.size()==1,"Enemy attack really emits a damaging projectile")
 check(g.hazards[0].base_v.normalized().is_equal_approx(locked),"Enemy locks its aim during warning, allowing a skill dodge")
 arena()
 quiet()
 g.spawn_enemy(0,true)
 e=g.enemies[0]
 e.state="patrol"
 e.p=Vector2(g.p.x+180,g.FLOOR)
 e.hp=1
 g.shoot()
 for k in range(30):g.step_bullets(1.0/60)
 check(g.enemies.is_empty() and g.kills==1 and g.score==100,"Forward bullets kill an enemy and award points")
 arena()
 quiet()
 g.spawn_enemy(0,true)
 g.enemies[0].state="patrol"
 g.enemies[0].p=Vector2(g.p.x-130,g.FLOOR)
 g.facing=1
 g.shoot()
 check(g.bullets[-1].v.x>0,"Aim assist never fires backwards at an enemy")
 g.facing=-1
 g.shoot()
 check(g.bullets[-1].v.x<0,"Turning allows attacking the enemy behind")
 arena()
 g.pickups.append({"p":g.p-Vector2(0,22),"kind":"shield","life":5.0})
 g.step_pickups(.01)
 check(g.pickups.is_empty() and g.shield==1,"Gift collection works with the new hitbox")
 # Full interactive tutorial: no timeout skip, no fake target kill.
 g.tutorial_seen=false
 g.begin_level(0)
 g.change_state("play")
 g.invincible=0
 g.hurt("practice")
 check(g.hp==3 and g.tutorial_active,"First-level practice is safe")
 check(g.guide_page==0,"First level opens the detailed guide before practice")
 g.test_axis=1
 var guide_position=g.p
 tick(3)
 check(g.elapsed==0 and g.p==guide_position,"Guide freezes simulation and cannot expose the player to attacks")
 for page in range(3):g.activate("guide_next")
 check(g.guide_page==-1 and g.tutorial_active,"All three guide pages lead to interactive practice")
 g.step_tutorial(20)
 check(g.tutorial_step==0,"Tutorial waits for the action instead of timing out")
 g.test_axis=1
 tick(.4)
 check(g.tutorial_step==1,"Tutorial advances after moving")
 g.test_axis=0
 g.jump()
 tick(.05)
 g.jump()
 tick(.05)
 check(g.tutorial_step==2,"Tutorial requires the second jump")
 tick(1.4)
 g.test_actions.duck=true
 tick(.6)
 check(g.tutorial_step==3 and not g.enemies.is_empty(),"Crouch lesson introduces a real practice enemy")
 g.test_actions.duck=false
 g.facing=1 if g.enemies[0].p.x>g.p.x else -1
 g.settings.auto_fire=true
 tick(3)
 check(g.tutorial_step==4 and g.kills>=1,"Shooting lesson requires an actual kill")
 g.settings.auto_fire=false
 g.dash()
 check(g.tutorial_step==5 and not g.pickups.is_empty(),"Dash lesson introduces an actual shield")
 g.p=g.pickups[0].p
 g.step_pickups(.01)
 check(not g.tutorial_active and g.tutorial_seen and g.hp==3 and g.elapsed==0,"Collecting shield finishes teaching and starts the easy arena fresh")
 g.begin_level(0)
 check(g.tutorial_active and g.guide_page==0,"Re-entering level one always shows the guide, even after completion")
 g.activate("skip_tutorial")
 check(not g.tutorial_active and g.guide_page==-1,"Experienced players can explicitly skip the guide")
 arena(1)
 check(not g.tutorial_active,"The introductory guide does not interrupt later levels")
 # Replaying a level produces the same patterns, unaffected by cosmetic particles.
 arena(12)
 for k in range(8):g.spawn_wave()
 var signature=[]
 for h in g.hazards:signature.append([h.kind,h.p,h.variant])
 arena(12)
 for k in range(100):g.burst(Vector2.ZERO,Color.WHITE,3)
 for k in range(8):g.spawn_wave()
 var repeat=[]
 for h in g.hazards:repeat.append([h.kind,h.p,h.variant])
 check(signature==repeat,"Attack practice is repeatable and independent of cosmetic randomness")
 var side_count=0
 for h in g.hazards:
  if h.kind==1:side_count+=1
 check(side_count<=1,"Director does not stack incompatible high and low lateral lanes")
 # Full campaign scheduler and real shooting, with immunity only to isolate long-run behavior.
 for index in range(20):
  arena(index)
  g.invincible=1000
  g.settings.auto_fire=true
  var boss_mode=g.level_data.boss
  var seconds=115.0 if boss_mode else g.duration+1
  for frame in range(int(seconds*60)):
   if g.state!="play":break
   g.test_axis=1 if (frame/240)%2==0 else -1
   if frame%80==0:g.jump()
   # Turn toward the current enemy/boss without teleporting, preserving forward-shot rules.
   if not g.enemies.is_empty():g.test_axis=signf(g.enemies[0].p.x-g.p.x)
   elif boss_mode:g.test_axis=signf(g.boss.p.x-g.p.x) if absf(g.boss.p.x-g.p.x)>350 else 0
   if boss_mode and g.enemies.is_empty():g.facing=1 if g.boss.p.x>g.p.x else -1
   g.step_game(1.0/60)
   g.step_particles(1.0/60)
   peak_hazards=maxi(peak_hazards,g.hazards.size())
   peak_enemies=maxi(peak_enemies,g.enemies.size())
  if boss_mode and g.state=="play":
   check(g.boss_pattern>=8 and g.boss.hp<g.boss.max_hp,"Boss %02d exercises attacks and takes directional damage" % (index+1))
   g.boss.hp=0
   g.step_game(.01)
  check(g.state=="victory","Full level %02d scheduler completes" % (index+1))
  check(g.hazards.size()<=g.MAX_HAZARDS and g.enemies.size()<=g.level_data.enemy_limit and g.particles.size()<=g.MAX_PARTICLES,"Level %02d respects object budgets" % (index+1))
 check(g.medals.size()==20 and g.unlocked==19,"All levels preserve unlock progression")
 g.activate("next")
 check(g.state=="ending","Final victory opens the retained ending")
 g.save_enabled=true
 g.settings.low=true
 g.tutorial_seen=true
 g.save_progress()
 g.unlocked=0
 g.medals={}
 g.tutorial_seen=false
 g.load_progress()
 check(g.unlocked==19 and g.medals.size()==20 and g.settings.low and g.tutorial_seen,"Save restores progress, new tutorial completion and existing settings")
 check(g.save_path!=g.SAVE_PATH,"Test writes to an isolated save filename")
 g.save_enabled=false
 g.settings.low=false
 arena()
 g.test_mode=false
 for pair in [[0,Vector2(164,652)],[1,Vector2(1180,652)],[2,Vector2(1028,652)]]:
  var event=InputEventScreenTouch.new()
  event.index=pair[0]
  event.position=pair[1]
  event.pressed=true
  g._input(event)
 check(g.down("right") and g.down("shoot") and g.jumps==1,"Native 1280px three-finger input maps to the retained UI coordinates")
 g.touches.clear()
 g.refresh_touches()
 check(not g.down("right") and not g.down("shoot"),"Touch release clears held actions")
 g.test_mode=true
 g.change_state("pause")
 var frozen=g.elapsed
 g._physics_process(.1)
 check(g.elapsed==frozen,"Pause freezes fixed-rate simulation")
 g.activate("resume")
 check(g.state=="play","Pause resumes gameplay")
 g.change_state("map")
 g.unlocked=0
 g.selected=19
 g.activate("start")
 check(g.state=="map","Locked nodes cannot launch a level")
 print("RESULT: %d passed, %d failed; peak hazards %d, peak enemies %d." % [passed,failed,peak_hazards,peak_enemies])
 g.queue_free()
 await process_frame
 await create_timer(.15).timeout
 quit(1 if failed else 0)
