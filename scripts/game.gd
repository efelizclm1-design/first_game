extends Node2D
## Fixed-arena action. All simulation uses bounded lists and simple rectangles.
const World = preload("res://scripts/world.gd")
const Painter = preload("res://scripts/painter.gd")
const SAVE_PATH = "user://pixel_panic_save.json"
var save_path = SAVE_PATH
const FLOOR = 294.0
const MAX_HAZARDS = 46
const MAX_PARTICLES = 90

var painter
var font: FontFile
var textures = {}
var sounds = {}
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_cursor = 0
var state = "title"
var return_state = "title"
var clock = 0.0
var state_time = 0.0
var selected = 0
var unlocked = 0
var medals = {}
var settings = {"music":true, "sound":true, "taunts":true, "low":false, "touch":false, "auto_fire":false}
var buttons: Array = []
var pointer = Vector2(-100, -100)
var touches = {}
var touch_actions = {}
var touch_was_jump = false
var touch_was_dash = false
var mouse_action = ""
var level_data = {}
var zone = 0
var elapsed = 0.0
var duration = 45.0
var hp = 3
var score = 0
var kills = 0
var hits = 0
var p = Vector2(170, FLOOR)
var velocity = Vector2.ZERO
var facing = 1
var ducking = false
var jumps = 0
var invincible = 0.0
var dash_time = 0.0
var dash_cooldown = 0.0
var shot_cooldown = 0.0
var shield = 0
var slow_time = 0.0
var rapid_time = 0.0
var spawn_clock = 1.8
var enemy_clock = 5.0
var gift_clock = 6.0
var arena_clock = 11.0
var arena_phase = "stable"
var arena_timer = 0.0
var arena_left = 24.0
var arena_right = 616.0
var target_left = 24.0
var target_right = 616.0
var hazards: Array = []
var enemies: Array = []
var bullets: Array = []
var pickups: Array = []
var particles: Array = []
var floaters: Array = []
var boss = {}
var boss_clock = 2.0
var boss_pattern = 0
var shake = 0.0
var toast = ""
var toast_timer = 0.0
var death_message = ""
var damage_source = ""
var result_stars = 0
var tutorial_step = 0
var tutorial_active = false
var tutorial_clock = 0.0
var save_enabled = true
var rng = RandomNumberGenerator.new()
var capture_path = ""
var capture_at = 0
var capture_mode = false
var test_mode = false
var test_axis = 0.0
var quitting = false

func _ready() -> void:
	rng.randomize()
	get_tree().auto_accept_quit = false
	font = load("res://assets/interface.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	for key in ["logo", "map", "hero_idle", "hero_run1", "hero_run2", "hero_jump", "hero_duck", "hero_hurt"]:
		textures[key] = load("res://assets/art/%s.png" % key)
	for z in range(5):
		for prefix in ["zone", "hazards", "boss"]:
			var key = "%s_%d" % [prefix,z]
			textures[key] = load("res://assets/art/%s.png" % key)
	for key in ["jump", "shoot", "hit", "pickup", "dash", "click", "warning", "win", "lose", "laugh"]:
		sounds[key] = load("res://assets/audio/%s.wav" % key)
	for i in range(8):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -7
		add_child(voice)
		voices.append(voice)
	music = AudioStreamPlayer.new()
	music.volume_db = -12
	add_child(music)
	painter = Painter.new(self)
	for arg in OS.get_cmdline_user_args():
		if arg == "--test":
			test_mode = true
			save_enabled = false
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
			capture_mode = true
			save_enabled = false
	if test_mode:
		save_path = "user://pixel_panic_test_save.json"
	load_progress()
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		settings.touch = true
	apply_settings()
	play_music(0)
	if capture_mode:
		setup_showcase()
	queue_redraw()

func load_progress() -> void:
	if not save_enabled or not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path,FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	unlocked = clampi(int(data.get("unlocked",0)),0,19)
	if data.get("medals",{}) is Dictionary:
		medals = data.get("medals",{})
	if data.get("settings",{}) is Dictionary:
		for key in settings:
			if data.settings.get(key) is bool:
				settings[key] = data.settings[key]
	selected = unlocked

func save_progress() -> void:
	if not save_enabled:
		return
	var file = FileAccess.open(save_path + ".tmp",FileAccess.WRITE)
	if file == null:
		notify("No se pudo guardar el progreso.")
		return
	file.store_string(JSON.stringify({"version":1,"unlocked":unlocked,"medals":medals,"settings":settings}))
	file.close()
	var error = DirAccess.rename_absolute(save_path + ".tmp",save_path)
	if error != OK:
		notify("No se pudo guardar el progreso.")

func apply_settings() -> void:
	Engine.max_fps = 30 if settings.low else 60
	if music:
		music.volume_db = -12 if settings.music else -80

func play_music(z: int) -> void:
	if test_mode:
		return
	var stream: AudioStreamWAV = load("res://assets/audio/music_%d.wav" % z).duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music.stream = stream
	music.play()

func sound(key: String) -> void:
	if not settings.sound or test_mode:
		return
	var voice = voices[voice_cursor % voices.size()]
	voice_cursor += 1
	voice.stream = sounds[key]
	voice.play()

func notify(message: String) -> void:
	toast = message
	toast_timer = 3.0

func change_state(next: String) -> void:
	state = next
	state_time = 0.0
	buttons.clear()
	touches.clear()
	touch_actions.clear()
	mouse_action = ""
	touch_was_jump = false
	touch_was_dash = false
	queue_redraw()

func begin_level(index: int) -> void:
	selected = clampi(index,0,19)
	level_data = World.level(selected)
	zone = level_data.zone
	elapsed = 0
	duration = level_data.duration
	hp = 3
	score = 0
	kills = 0
	hits = 0
	p = Vector2(160,FLOOR)
	velocity = Vector2.ZERO
	facing = 1
	ducking = false
	jumps = 0
	invincible = 1.5
	dash_time = 0
	dash_cooldown = 0
	shot_cooldown = 0
	shield = 0
	slow_time = 0
	rapid_time = 0
	spawn_clock = 1.8
	enemy_clock = 4.2
	gift_clock = 6
	arena_clock = 10
	arena_phase = "stable"
	arena_left = 24
	arena_right = 616
	target_left = 24
	target_right = 616
	hazards.clear()
	enemies.clear()
	bullets.clear()
	pickups.clear()
	particles.clear()
	floaters.clear()
	boss = {}
	boss_clock = 2.5
	boss_pattern = 0
	shake = 0
	damage_source = ""
	if level_data.boss:
		boss = {"p":Vector2(492,140),"hp":float(level_data.boss_hp),"max_hp":float(level_data.boss_hp),"flash":0.0,"phase":1}
	tutorial_active = selected == 0 and not medals.has("0") and not capture_mode
	tutorial_step = 0
	tutorial_clock = 0
	play_music(zone)
	change_state("loading")

func _process(dt: float) -> void:
	dt = minf(dt,0.05)
	clock += dt
	state_time += dt
	toast_timer = maxf(0,toast_timer-dt)
	if state == "loading" and state_time >= 1.5:
		change_state("play")
	elif state == "play" and not capture_mode:
		step_game(dt)
	if state == "dead" and state_time-dt < .4 and state_time >= .4 and settings.taunts:
		sound("laugh")
	if state not in ["pause","settings"]:
		step_particles(dt)
	queue_redraw()
	if capture_mode:
		capture_at += 1
		if capture_at == 10:
			await RenderingServer.frame_post_draw
			var img = get_viewport().get_texture().get_image()
			var err = img.save_png(capture_path)
			print("CAPTURE ",capture_path," error=",err)
			quit_cleanly(err)

func down(action: String) -> bool:
	if test_mode:
		return false
	if touch_actions.get(action,false) or mouse_action == action:
		return true
	match action:
		"left": return Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
		"right": return Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
		"duck": return Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
		"shoot": return Input.is_physical_key_pressed(KEY_J) or Input.is_physical_key_pressed(KEY_Z)
	return false

func jump() -> void:
	if state != "play" or jumps >= 2:
		return
	velocity.y = -315 if jumps == 0 else -290
	jumps += 1
	ducking = false
	burst(p,Color("a6e4c5"),8)
	sound("jump")
	if tutorial_active and tutorial_step == 1:
		tutorial_step = 2
		tutorial_clock = 0

func dash() -> void:
	if state != "play" or dash_cooldown > 0:
		return
	dash_time = .18
	dash_cooldown = 1.15
	invincible = maxf(invincible,.24)
	velocity.y = minf(velocity.y,0)
	sound("dash")
	if tutorial_active and tutorial_step == 4:
		tutorial_active = false
		notify("¡Ya estás listo! Sobrevive y no dejes de moverte.")

func player_rect() -> Rect2:
	return Rect2(p.x-8,p.y-(15 if ducking else 29),16,15 if ducking else 29)

func step_game(dt: float) -> void:
	var tutorial_before = tutorial_active
	if tutorial_active:
		tutorial_clock += dt
		if tutorial_clock > 12:
			tutorial_active = false
			notify("Consejo: revisa los controles desde la pausa.")
	else:
		elapsed += dt
	var ramp = 1.0 + minf(elapsed / duration,1.0) * .85
	if not boss.is_empty():
		ramp = 1.0 + minf(elapsed / 70.0,1.0) * .8
	var world_dt = dt * (.48 if slow_time > 0 else 1.0)
	invincible = maxf(0,invincible-dt)
	dash_cooldown = maxf(0,dash_cooldown-dt)
	dash_time = maxf(0,dash_time-dt)
	shot_cooldown = maxf(0,shot_cooldown-dt)
	slow_time = maxf(0,slow_time-dt)
	rapid_time = maxf(0,rapid_time-dt)
	shake = maxf(0,shake-dt*20)
	var axis = test_axis if test_mode else float(down("right"))-float(down("left"))
	ducking = down("duck") and p.y >= FLOOR-1 and dash_time <= 0
	if axis != 0:
		facing = 1 if axis > 0 else -1
		if tutorial_active and tutorial_step == 0:
			tutorial_step = 1
			tutorial_clock = 0
	if ducking and tutorial_active and tutorial_step == 2:
		tutorial_step = 3
		tutorial_clock = 0
	var target_speed = axis * (77 if ducking else 177)
	if dash_time > 0:
		velocity.x = facing * 470
		if not settings.low:
			burst(p-Vector2(0,14),Color("a6e4c5"),1)
	elif zone == 1:
		velocity.x = move_toward(velocity.x,target_speed,dt*570)
	else:
		velocity.x = move_toward(velocity.x,target_speed,dt*1800)
	velocity.y += dt * (180 if dash_time > 0 else 850)
	p += velocity * dt
	p.x = clampf(p.x,12,628)
	if p.y >= FLOOR:
		p.y = FLOOR
		velocity.y = 0
		jumps = 0
		if p.x < arena_left or p.x > arena_right:
			hurt("El vacío")
			if state != "play":
				return
			p.x = clampf(p.x,arena_left+24,arena_right-24)
	if (down("shoot") or settings.auto_fire) and shot_cooldown <= 0:
		shoot()
		if tutorial_active and tutorial_step == 3:
			tutorial_step = 4
			tutorial_clock = 0
	if tutorial_before:
		step_bullets(dt)
		return
	spawn_clock -= world_dt
	enemy_clock -= world_dt
	gift_clock -= dt
	if spawn_clock <= 0:
		spawn_hazard(rng.randi_range(0,2),ramp)
		spawn_clock = maxf(.32,level_data.interval / ramp)
	if enemy_clock <= 0:
		spawn_enemy()
		enemy_clock = level_data.enemy_interval / sqrt(ramp)
	if gift_clock <= 0:
		spawn_pickup()
		gift_clock = rng.randf_range(7.0,10.0)
	step_arena(dt)
	step_hazards(world_dt)
	if state != "play":return
	step_enemies(world_dt,ramp)
	if state != "play":return
	step_boss(world_dt,ramp)
	step_bullets(dt)
	step_pickups(dt)
	if state != "play":return
	if level_data.boss:
		if not boss.is_empty() and boss.hp <= 0:
			complete_level()
	elif elapsed >= duration:
		complete_level()

func shoot() -> void:
	if bullets.size() >= 36:
		return
	shot_cooldown = .13 if rapid_time > 0 else .27
	var origin = p + Vector2(facing*10,-12 if ducking else -21)
	var target = origin + Vector2(facing*640,0)
	var best = INF
	for e in enemies:
		if e.age < 0:continue
		var distance = origin.distance_squared_to(e.p)
		if distance < best:
			best = distance
			target = e.p + Vector2(0,-12)
	if not boss.is_empty() and origin.distance_squared_to(boss.p) < best:
		target = boss.p
	var dir = (target-origin).normalized()
	bullets.append({"p":origin,"v":dir*400,"life":1.8})
	sound("shoot")

func spawn_hazard(kind: int, ramp: float = 1.0, fixed_x: float = -1) -> void:
	if hazards.size() >= MAX_HAZARDS:return
	var variant = rng.randi_range(0,15)
	var x = fixed_x if fixed_x >= 0 else rng.randf_range(arena_left+18,arena_right-18)
	var speed = level_data.speed * ramp
	var h = {"kind":kind,"p":Vector2(x,-20),"v":Vector2.ZERO,"wait":.85,"age":0.0,"life":9.0,"variant":variant,"r":9.0,"name":World.ZONES[zone].objects[variant]}
	match kind:
		0:
			h.v = Vector2(rng.randf_range(-8,8),speed*1.2)
		1:
			var left = rng.randf() < .5
			# Upper projectiles can be crouched under; lower ones require a jump.
			h.p = Vector2(-18 if left else 658,260 if rng.randf()<.55 else 282)
			h.v = Vector2(speed*1.6*(1 if left else -1),0)
			h.wait = .95
		2:
			h.p = Vector2(x,FLOOR)
			h.wait = .95
			h.life = .85
			h.name = ["Raíces espinosas","Estalagmita","Descarga eléctrica","Pilar de viento","Géiser de lava"][zone]
	hazards.append(h)

func hazard_rect(h: Dictionary) -> Rect2:
	if h.kind == 2:
		return Rect2(h.p.x-10,FLOOR-39,20,39)
	return Rect2(h.p-Vector2(8,8),Vector2(16,16))

func step_hazards(dt: float) -> void:
	for i in range(hazards.size()-1,-1,-1):
		var h = hazards[i]
		if h.wait > 0:
			h.wait -= dt
			continue
		h.age += dt
		h.life -= dt
		h.p += h.v * dt
		if h.kind == 0 and h.p.y > FLOOR-5:
			burst(h.p,Color(World.ZONES[zone].color),5)
			hazards.remove_at(i)
			continue
		if h.life <= 0 or h.p.x < -45 or h.p.x > 685:
			hazards.remove_at(i)
			continue
		if player_rect().intersects(hazard_rect(h)):
			hurt(h.name)
			if state != "play":return

func spawn_enemy() -> void:
	if enemies.size() >= 6:return
	var left = rng.randf() < .5
	var flying = zone in [2,3] or rng.randf() < .25
	enemies.append({"p":Vector2(38 if left else 602,215 if flying else FLOOR),"hp":2+zone/2,"age":-.9,"dir":1 if left else -1,"flying":flying,"shot":2.8,"flash":0.0,"seed":rng.randf()*6})

func step_enemies(dt: float, ramp: float) -> void:
	for i in range(enemies.size()-1,-1,-1):
		var e = enemies[i]
		e.age += dt
		e.flash = maxf(0,e.flash-dt)
		if e.age < 0:continue
		e.p.x += e.dir*(19+zone*4)*dt
		if e.p.x > arena_right-15:e.dir = -1
		if e.p.x < arena_left+15:e.dir = 1
		if e.flying:e.p.y = 211+sin(elapsed*2+e.seed)*18
		e.shot -= dt
		if e.shot <= 0 and hazards.size()<MAX_HAZARDS:
			var dir = (p-Vector2(0,20)-e.p).normalized()
			hazards.append({"kind":3,"p":e.p-Vector2(0,14),"v":dir*(80+zone*9)*sqrt(ramp),"wait":.65,"age":0.0,"life":7.0,"variant":3,"r":7.0,"name":World.ZONES[zone].enemy})
			e.shot = 3.2/sqrt(ramp)
		if player_rect().intersects(Rect2(e.p-Vector2(11,25),Vector2(22,25))):
			hurt(World.ZONES[zone].enemy)
			if state != "play":return

func step_boss(dt: float, ramp: float) -> void:
	if boss.is_empty():return
	boss.p = Vector2(477+sin(elapsed*.7)*52,130+sin(elapsed*1.4)*24)
	boss.flash = maxf(0,boss.flash-dt)
	var phase = 2 if boss.hp < boss.max_hp*.5 else 1
	if phase != boss.phase:
		boss.phase = phase
		notify("¡FASE 2! " + World.ZONES[zone].boss)
		sound("warning")
		burst(boss.p,Color(World.ZONES[zone].color),25)
	boss_clock -= dt
	if boss_clock > 0:return
	boss_clock = (3.0 if phase == 1 else 2.15)/sqrt(ramp)
	boss_pattern += 1
	# Each biome has a different signature plus a shared readable fan pattern.
	if boss_pattern%3 == 0:
		for k in range(5+phase):
			if hazards.size()>=MAX_HAZARDS:break
			var angle = PI*.26 + k*PI*.52/(4+phase)
			hazards.append({"kind":3,"p":boss.p+Vector2(0,25),"v":Vector2(cos(angle),sin(angle))*(80+zone*10),"wait":.8,"age":0.0,"life":7.0,"variant":zone+8,"r":7.0,"name":World.ZONES[zone].boss})
	else:
		match zone:
			0:
				for k in range(3+phase):spawn_hazard(0,ramp,clampf(p.x-65+k*36,40,600))
			1:
				for k in range(3+phase):spawn_hazard(2,ramp,65+k*112)
			2:
				for k in range(2+phase):spawn_hazard(1,ramp)
			3:
				for k in range(3+phase):spawn_hazard(0,ramp,80+k*105)
				spawn_enemy()
			4:
				for k in range(3):spawn_hazard(2,ramp,clampf(p.x-75+k*75,40,600))
				spawn_hazard(1,ramp)

func step_bullets(dt: float) -> void:
	for i in range(bullets.size()-1,-1,-1):
		var b = bullets[i]
		b.p += b.v*dt
		b.life -= dt
		var consumed = false
		for j in range(enemies.size()-1,-1,-1):
			var e = enemies[j]
			if e.age >= 0 and Rect2(e.p-Vector2(14,28),Vector2(28,32)).grow(3).has_point(b.p):
				e.hp -= 1
				e.flash = .1
				burst(b.p,Color("ffe4af"),4)
				consumed = true
				if e.hp <= 0:
					kills += 1
					score += 100
					floating(e.p,"+100",Color("a6e4c5"))
					burst(e.p,Color(World.ZONES[zone].color),12)
					enemies.remove_at(j)
				break
		if not consumed and not boss.is_empty() and Rect2(boss.p-Vector2(35,33),Vector2(70,70)).has_point(b.p):
			boss.hp -= 1
			boss.flash = .08
			consumed = true
			burst(b.p,Color("ffe4af"),3)
		if consumed or b.life <= 0 or b.p.x < -20 or b.p.x > 660 or b.p.y < -30:
			bullets.remove_at(i)

func spawn_pickup(forced: String = "") -> void:
	if pickups.size()>=5:return
	var kind = forced
	if kind.is_empty():
		var choices = ["shield","heal","slow","rapid"]
		kind = choices[rng.randi_range(0,3)]
	pickups.append({"p":Vector2(rng.randf_range(arena_left+32,arena_right-32),-12),"kind":kind,"life":12.0,"landed":false})

func apply_pickup(kind: String) -> void:
	match kind:
		"shield":shield = 1
		"heal":hp = mini(3,hp+1)
		"slow":slow_time = 6
		"rapid":rapid_time = 7
	var labels = {"shield":"ESCUDO +1","heal":"CORAZÓN +1","slow":"TIEMPO LENTO","rapid":"DISPARO RÁPIDO"}
	floating(p-Vector2(0,40),labels[kind],Color("a6e4c5"))
	score += 25
	sound("pickup")
	burst(p-Vector2(0,15),Color("a6e4c5"),14)

func step_pickups(dt: float) -> void:
	for i in range(pickups.size()-1,-1,-1):
		var gift = pickups[i]
		gift.life -= dt
		gift.p.y = minf(FLOOR-14,gift.p.y+72*dt)
		if player_rect().grow(8).has_point(gift.p):
			apply_pickup(gift.kind)
			pickups.remove_at(i)
		elif gift.life <= 0:
			pickups.remove_at(i)

func step_arena(dt: float) -> void:
	if not level_data.shrink:return
	arena_clock -= dt
	if arena_phase == "stable" and arena_clock <= 0:
		arena_phase = "warning"
		arena_timer = 1.25
		var inset = 65 + level_data.part*19 + zone*7
		target_left = float(inset)
		target_right = 640.0-inset
		notify("¡CUIDADO! Los bordes desaparecen.")
		sound("warning")
	elif arena_phase == "warning":
		arena_timer -= dt
		if arena_timer <= 0:
			arena_phase = "small"
			arena_timer = 6
			arena_left = target_left
			arena_right = target_right
			shake = 2
	elif arena_phase == "small":
		arena_timer -= dt
		if arena_timer <= 0:
			arena_phase = "stable"
			arena_clock = 10
			arena_left = 24
			arena_right = 616
			notify("El terreno vuelve. Por ahora.")

func hurt(source: String) -> void:
	if invincible > 0 or state != "play":return
	if shield > 0:
		shield = 0
		invincible = 1.2
		burst(p-Vector2(0,15),Color("8ce5df"),18)
		sound("pickup")
		return
	hp -= 1
	hits += 1
	invincible = 1.65
	shake = 4
	damage_source = source
	burst(p-Vector2(0,15),Color("f47d7b"),18)
	sound("hit")
	if hp <= 0:
		death_message = World.TAUNTS[rng.randi_range(0,World.TAUNTS.size()-1)] if settings.taunts else "Cada intento cuenta. ¡Puedes lograrlo!"
		change_state("dead")
		sound("lose")

func complete_level() -> void:
	if state != "play":return
	result_stars = 3 if hits == 0 else 2 if hits <= 2 else 1
	score += 500 + hp*100 + (1000 if level_data.boss else 0)
	medals[str(selected)] = maxi(int(medals.get(str(selected),0)),result_stars)
	unlocked = maxi(unlocked,mini(19,selected+1))
	save_progress()
	change_state("victory")
	sound("win")
	burst(Vector2(320,150),Color("f6ba70"),50)

func burst(at: Vector2, color: Color, count: int) -> void:
	if settings.low:count = int(ceil(count*.4))
	for i in range(mini(count,MAX_PARTICLES-particles.size())):
		particles.append({"p":at,"v":Vector2(rng.randf_range(-65,65),rng.randf_range(-90,25)),"life":rng.randf_range(.2,.7),"c":color})

func floating(at: Vector2, message: String, color: Color) -> void:
	if floaters.size()<12:floaters.append({"p":at,"text":message,"c":color,"life":1.2})

func step_particles(dt: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		var q = particles[i]
		q.p += q.v*dt
		q.v.y += 150*dt
		q.life -= dt
		if q.life <= 0:particles.remove_at(i)
	for i in range(floaters.size()-1,-1,-1):
		floaters[i].p.y -= dt*24
		floaters[i].life -= dt
		if floaters[i].life<=0:floaters.remove_at(i)

func _draw() -> void:
	if painter:painter.paint()

func _exit_tree() -> void:
	if painter:
		painter.g = null
		painter = null
	if music:
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_cleanly()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and not capture_mode:
		change_state("pause")

func quit_cleanly(code: int = 0) -> void:
	if quitting:return
	quitting = true
	set_process(false)
	music.stop()
	for voice in voices:voice.stop()
	# Allow the audio thread to retire active playback before resources are freed.
	await get_tree().create_timer(.12).timeout
	get_tree().quit(code)

func touch_action(at: Vector2) -> String:
	for pair in touch_rects():
		if pair[1].has_point(at):return pair[0]
	return ""

func touch_rects() -> Array:
	return [["left",Rect2(10,302,49,51)],["right",Rect2(64,302,49,51)],["duck",Rect2(122,302,49,51)],
		["dash",Rect2(423,302,58,51)],["shoot",Rect2(486,302,64,51)],["jump",Rect2(555,302,75,51)]]

func refresh_touches() -> void:
	touch_actions.clear()
	for pos in touches.values():
		var action = touch_action(pos)
		if not action.is_empty():touch_actions[action] = true
	var j = touch_actions.get("jump",false)
	var d = touch_actions.get("dash",false)
	if j and not touch_was_jump:jump()
	if d and not touch_was_dash:dash()
	touch_was_jump = j
	touch_was_dash = d

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:pointer = get_global_mouse_position()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE, KEY_P:
				if state == "play":change_state("pause")
				elif state == "pause":change_state("play")
				elif state == "settings":change_state(return_state)
				elif state == "map":change_state("title")
			KEY_SPACE, KEY_W, KEY_UP:
				if state == "play":jump()
			KEY_SHIFT, KEY_K, KEY_X:
				if state == "play":dash()
			KEY_ENTER:
				if state == "title":change_state("map")
				elif state == "map" and selected <= unlocked:begin_level(selected)
				elif state == "dead":begin_level(selected)
				elif state == "victory":activate("next")
				elif state == "pause":change_state("play")
			KEY_R:
				if state in ["dead","pause"]:begin_level(selected)
			KEY_LEFT,KEY_A:
				if state == "map":selected = maxi(0,selected-1)
			KEY_RIGHT,KEY_D:
				if state == "map":selected = mini(19,selected+1)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = get_global_mouse_position()
		if event.pressed:
			if state == "play" and settings.touch:
				mouse_action = touch_action(pointer)
				if mouse_action == "jump":jump()
				if mouse_action == "dash":dash()
			click_at(pointer)
		else:mouse_action = ""
	if event is InputEventScreenTouch:
		if event.pressed:
			if not settings.touch:settings.touch = true
			if state == "play":
				touches[event.index] = event.position
				refresh_touches()
			click_at(event.position)
		else:
			touches.erase(event.index)
			refresh_touches()
	if event is InputEventScreenDrag and state == "play":
		touches[event.index] = event.position
		refresh_touches()

func click_at(at: Vector2) -> void:
	for b in buttons.duplicate():
		if b.rect.has_point(at):
			sound("click")
			activate(b.action)
			return

func activate(action: String) -> void:
	if action.begins_with("level:"):
		selected = int(action.split(":")[1])
		return
	if action.begins_with("toggle:"):
		var key = action.split(":")[1]
		settings[key] = not settings[key]
		apply_settings()
		save_progress()
		return
	match action:
		"map":change_state("map")
		"title":change_state("title")
		"start":
			if selected <= unlocked:begin_level(selected)
			else:notify("Supera el nivel anterior para desbloquearlo.")
		"retry":begin_level(selected)
		"next":
			if selected == 19:change_state("ending")
			else:begin_level(selected+1)
		"pause":change_state("pause")
		"resume":change_state("play")
		"settings":
			return_state = state
			change_state("settings")
		"back":change_state(return_state)
		"skip_tutorial":tutorial_active = false
		"quit":quit_cleanly()

func setup_showcase() -> void:
	var screen = "title"
	var which = 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):screen = arg.trim_prefix("--screen=")
		if arg.begins_with("--level="):which = int(arg.trim_prefix("--level="))
		if arg == "--touch":settings.touch = true
	if screen == "map":
		unlocked = 19
		selected = which
		for k in range(which):medals[str(k)] = 3 if k%3==0 else 2
		change_state("map")
	elif screen in ["play","dead","victory","loading"]:
		begin_level(which)
		change_state(screen)
		elapsed = 21
		p = Vector2(244,272)
		velocity = Vector2(90,-30)
		invincible = 0
		shield = 1
		for i in range(6):
			spawn_hazard(0,1,80+i*83)
			hazards[-1].wait = 0
			hazards[-1].p.y = 86+i%3*43
		spawn_hazard(2,1,350)
		hazards[-1].wait = 0
		spawn_hazard(2,1,128)
		spawn_hazard(1)
		for i in range(2):
			spawn_enemy()
			enemies[-1].age = 1
			enemies[-1].p = Vector2(410+i*140,FLOOR)
		spawn_pickup("heal")
		pickups[-1].p = Vector2(290,171)
		for i in range(4):bullets.append({"p":Vector2(280+i*25,246-i*9),"v":Vector2(100,0),"life":1.0})
		death_message = World.TAUNTS[3]
		damage_source = World.ZONES[zone].objects[2]
		result_stars = 3
		tutorial_active = false
	else:change_state(screen)
