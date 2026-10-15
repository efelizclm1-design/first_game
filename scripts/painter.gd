extends RefCounted
## Immediate-mode pixel UI. No Control tree churn, shaders, or dynamic lights.
const World = preload("res://scripts/world.gd")
const INK = Color("101726")
const PANEL = Color("182333")
const EDGE = Color("344457")
const CREAM = Color("fff0cc")
const MUTED = Color("9aa9b6")
const MINT = Color("a6e4c5")
const CORAL = Color("ef827b")
var g

func _init(game) -> void:
	g = game

func rect(x: float,y: float,w: float,h: float,c: Color) -> void:
	g.draw_rect(Rect2(floor(x),floor(y),w,h),c)

func line(a: Vector2,b: Vector2,c: Color,width: float=1) -> void:
	g.draw_line(a.floor(),b.floor(),c,width,false)

func text(s: String,x: float,y: float,size: int=12,c: Color=CREAM) -> void:
	g.draw_string(g.font,Vector2(floor(x),floor(y)),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)

func center(s: String,x: float,y: float,size: int=12,c: Color=CREAM) -> void:
	text(s,x-g.font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,y,size,c)

func fitted(s: String,x: float,y: float,width: float,size: int=12,c: Color=CREAM) -> void:
	while g.font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and size>8:
		size -= 1
	text(s,x,y,size,c)

func panel(r: Rect2,c: Color=PANEL,border: Color=EDGE) -> void:
	g.draw_rect(Rect2(r.position+Vector2(0,3),r.size),Color(0,0,0,.25))
	g.draw_rect(r,c)
	g.draw_rect(r,border,false,1)
	g.draw_rect(Rect2(r.position+Vector2(2,2),Vector2(r.size.x-4,1)),Color(1,1,1,.035))

func button(label: String,r: Rect2,action: String,primary: bool=false,enabled: bool=true) -> void:
	var hover = r.has_point(g.pointer)
	var bg = MINT if primary else PANEL
	var fg = INK if primary else CREAM
	if not enabled:
		bg = Color("202a37")
		fg = Color("687888")
	elif hover:
		bg = Color("d0f2d7") if primary else Color("304152")
	rect(r.position.x,r.position.y+3,r.size.x,r.size.y,Color("0b101b"))
	g.draw_rect(r,bg)
	g.draw_rect(r,Color("c4efd4") if primary and enabled else EDGE,false,1)
	center(label,r.get_center().x,r.position.y+r.size.y/2+4,11,fg)
	if enabled:g.buttons.append({"rect":r,"action":action})

func tex(key: String,r: Rect2,modulate: Color=Color.WHITE) -> void:
	g.draw_texture_rect(g.textures[key],r,false,modulate)

func diamond(at: Vector2,size: float,c: Color) -> void:
	g.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-size),at+Vector2(size,0),at+Vector2(0,size),at+Vector2(-size,0)]),c)

func star(at: Vector2,c: Color,size: float=3) -> void:
	line(at-Vector2(size,0),at+Vector2(size,0),c)
	line(at-Vector2(0,size),at+Vector2(0,size),c)
	rect(at.x-1,at.y-1,3,3,c)

func heart(at: Vector2,c: Color,scale: int=1) -> void:
	var pattern = ["0110110","1111111","1111111","0111110","0011100","0001000"]
	for y in range(6):
		for x in range(7):
			if pattern[y][x]=="1":rect(at.x+x*scale,at.y+y*scale,scale,scale,c)

func paint() -> void:
	g.buttons.clear()
	rect(0,0,640,360,INK)
	match g.state:
		"title":title()
		"map":world_map()
		"loading":loading()
		"play":arena()
		"pause":
			arena()
			pause_menu()
		"dead":
			arena()
			result(false)
		"victory":
			arena()
			result(true)
		"settings":settings_menu()
		"ending":ending()
	if g.toast_timer>0 and g.state not in ["loading","dead","victory"]:
		var w = minf(590,g.font.get_string_size(g.toast,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+24)
		panel(Rect2(320-w/2,84 if g.state=="play" else 336,w,20),INK,EDGE)
		center(g.toast,320,98 if g.state=="play" else 350,10,MINT)

func ambient(z: int,amount: int=22) -> void:
	if g.settings.low:amount = 8
	var c = Color(World.ZONES[z].color)
	for i in range(amount):
		var x = fmod(i*73.0+g.clock*(4+i%4),640)
		var y = fmod(i*43.0+g.clock*(5+i%3),277)
		var alpha = .25+sin(g.clock*1.3+i)*.15
		rect(x,y,2 if i%5==0 else 1,2 if i%5==0 else 1,Color(c,alpha))

func title() -> void:
	tex("zone_0",Rect2(0,0,640,360))
	# Dark vignette in discrete bands, preserving the pixel look.
	for i in range(10):rect(i*34,0,34,360,Color(.045,.065,.105,.94-i*.065))
	rect(0,0,640,34,Color(.04,.06,.10,.75))
	star(Vector2(25,17),MINT,3)
	text("UN PEQUEÑO GUARDIÁN. UNA LARGA NOCHE.",37,21,9,MUTED)
	text("VOL. 01 / LA MALDICIÓN",476,21,8,Color("b2999d"))
	tex("logo",Rect2(28,65,278,119))
	text("VEINTE ARENAS. TRES CORAZONES.",48,207,10,CREAM)
	text("La oscuridad también sabe reír.",48,224,10,MUTED)
	button("CONTINUAR LA AVENTURA  >" if g.unlocked>0 else "EMPEZAR LA AVENTURA  >",Rect2(48,243,243,34),"map",true)
	button("AJUSTES Y CONTROLES",Rect2(48,288,243,28),"settings")
	# Hero and a magic doorway are part of the actual title scene.
	var pulse = sin(g.clock*1.5)*.05
	g.draw_arc(Vector2(464,204),66,PI,TAU,24,Color(.65,.89,.77,.25+pulse),3,false)
	g.draw_arc(Vector2(464,204),73,PI,TAU,24,Color(.65,.89,.77,.12),1,false)
	line(Vector2(398,204),Vector2(398,267),Color("637d72"),2)
	line(Vector2(530,204),Vector2(530,267),Color("637d72"),2)
	for i in range(5):star(Vector2(400+i*31,130+sin(i*2.2)*23),MINT,2)
	rect(412,282,102,9,Color("171d29"))
	rect(421,280,84,4,Color("47564a"))
	hero(Vector2(464,282),2.3,true)
	panel(Rect2(415,312,99,21),INK,Color("5b6259"))
	center("NILO / GUARDIÁN",464,326,9,CREAM)
	ambient(0)
	text("PIXEL ART ORIGINAL  /  GODOT 4",18,347,8,MUTED)
	text("MOVER · SALTAR · SOBREVIVIR",438,347,8,MUTED)

func level_position(index: int) -> Vector2:
	var z = int(index/4)
	var cy = [164,144,164,144,164][z]
	var part = index%4
	return Vector2(76+z*122+[-34,-12,12,34][part],cy+[-6,-24,-6,-24][part])

func world_map() -> void:
	tex("map",Rect2(0,0,640,360))
	rect(0,0,640,68,Color(.04,.06,.1,.88))
	text("EL ATLAS DEL PÁNICO",24,31,20,CREAM)
	var completed = g.medals.size()
	text("5 MUNDOS  /  20 DESAFÍOS  /  UNA SOLA BUFANDA",25,49,9,MUTED)
	panel(Rect2(436,18,104,30))
	center("%02d / 20  SUPERADOS" % completed,488,37,9,MINT)
	button("< INICIO",Rect2(551,18,65,30),"title")
	for i in range(19):
		var a = level_position(i)
		var b = level_position(i+1)
		var steps = int(a.distance_to(b)/5)
		for j in range(steps):
			var pos = a.lerp(b,float(j)/maxi(1,steps))
			rect(pos.x,pos.y,2,2,Color("7f9d96") if i<g.unlocked else Color("344557"))
	for z in range(5):
		var c = Color(World.ZONES[z].color)
		center("0%d" % (z+1),76+z*122,88,9,c)
		center(World.ZONES[z].short,76+z*122,236,10,c)
	for i in range(20):
		var at = level_position(i)
		var active = i<=g.unlocked
		var c = Color(World.ZONES[i/4].color)
		var selected = i == g.selected
		var r = Rect2(at-Vector2(10,10),Vector2(20,20))
		if selected:
			g.draw_rect(r.grow(3),c,false,1)
			line(at+Vector2(-3,-18),at+Vector2(3,-18),CREAM,2)
			line(at+Vector2(0,-16),at+Vector2(0,-14),CREAM,2)
		if i%4==3:
			diamond(at,13,c if active else Color("3b4556"))
			diamond(at,10,INK)
		else:
			g.draw_rect(r,c if active else Color("3b4556"))
			g.draw_rect(r.grow(-2),INK)
		center(str(i+1).pad_zeros(2),at.x,at.y+3,8,CREAM if active else MUTED)
		if g.medals.has(str(i)):
			for k in range(int(g.medals[str(i)])):rect(at.x-5+k*4,at.y+13,3,2,c)
		g.buttons.append({"rect":r.grow(2),"action":"level:%d" % i})
	var data = World.level(g.selected)
	var theme = World.ZONES[data.zone]
	var tint = Color(theme.color)
	panel(Rect2(20,253,600,78),Color("182433"),Color("415162"))
	rect(20,253,3,78,tint)
	text("NIVEL %02d  /  %s" % [g.selected+1,"JEFE DE ZONA" if data.boss else theme.name],35,270,8,tint)
	fitted(data.name,35,291,350,17,CREAM)
	text("3 VIDAS  ·  " + ("DERROTA AL JEFE" if data.boss else "SOBREVIVE %d s" % int(data.duration)),35,310,9,MUTED)
	if g.selected<=g.unlocked:
		button("ENTRAR  >",Rect2(468,272,133,38),"start",true)
	else:
		button("BLOQUEADO",Rect2(468,272,133,38),"start",false,false)
	text("FLECHAS: ELEGIR     ENTER: JUGAR",22,348,8,MUTED)
	text("EL PROGRESO SE GUARDA SOLO",441,348,8,MUTED)

func loading() -> void:
	var c = Color(World.ZONES[g.zone].color)
	tex("zone_%d" % g.zone,Rect2(0,0,640,360),Color(.34,.38,.47))
	rect(0,0,640,360,Color(.03,.05,.09,.4))
	text("PREPARANDO EL DESASTRE",42,51,10,c)
	text("%02d" % (g.selected+1),40,114,50,CREAM)
	text(World.ZONES[g.zone].name,43,142,12,c)
	fitted(g.level_data.name,43,177,440,23,CREAM)
	text("TRES CORAZONES. HAZ QUE CUENTEN.",44,205,9,MUTED)
	if g.level_data.boss:
		tex("boss_%d" % g.zone,Rect2(484,81,112,112))
	else:hero(Vector2(537,190),2.6,true)
	panel(Rect2(43,250,554,10),INK,EDGE)
	var t = clampf(g.state_time/1.45,0,1)
	rect(46,253,548*t,4,c)
	text("ENTRANDO EN LA ARENA",43,280,9,MUTED)
	text("%02d %%" % int(t*100),555,280,9,c)
	center(World.TIPS[g.selected%World.TIPS.size()],320,326,9,CREAM)

func hero(at: Vector2,scale: float=1.0,portrait: bool=false) -> void:
	var pose = "idle"
	if not portrait:
		if g.ducking:pose = "duck"
		elif g.p.y<g.FLOOR-1:pose = "jump"
		elif absf(g.velocity.x)>12:pose = "run1" if int(g.clock*12)%2==0 else "run2"
		if g.invincible>0 and int(g.clock*16)%2==0:pose = "hurt"
	var bob = sin(g.clock*2)*1.0 if portrait else 0.0
	tex("hero_"+pose,Rect2((at-Vector2(16*scale,39*scale+floor(bob))).floor(),Vector2(32,40)*scale))
	if not portrait and g.shield>0:
		g.draw_arc(at-Vector2(0,19),24,0,TAU,16,Color("8ce5df"),1,false)
		star(at+Vector2(20,-31),MINT,2)

func arena() -> void:
	var c = Color(World.ZONES[g.zone].color)
	var shake_offset = Vector2.ZERO if g.settings.low else Vector2(sin(g.clock*70),cos(g.clock*91))*g.shake
	g.draw_set_transform(shake_offset.floor())
	tex("zone_%d" % g.zone,Rect2(0,0,640,360))
	ambient(g.zone)
	# Additional scenery differentiates the four arenas within each zone.
	for k in range(g.level_data.get("part",0)):
		var x = 210+k*83
		line(Vector2(x,294),Vector2(x,276-k*3),c.darkened(.4),3)
		diamond(Vector2(x,272-k*3),4,c.darkened(.2))
	if g.arena_phase == "warning":
		for r in [Rect2(0,284,g.target_left,15),Rect2(g.target_right,284,640-g.target_right,15)]:
			g.draw_rect(r,Color(.9,.25,.3,.3+sin(g.clock*20)*.1))
			for x in range(int(r.position.x),int(r.end.x),12):line(Vector2(x,294),Vector2(x+7,286),CORAL,2)
		center("¡ATRÁS!",g.target_left/2,276,9,CREAM)
		center("¡ATRÁS!",(g.target_right+640)/2,276,9,CREAM)
	if g.arena_phase == "small":
		rect(0,294,g.arena_left,66,Color("0b0f1e"))
		rect(g.arena_right,294,640-g.arena_right,66,Color("0b0f1e"))
		line(Vector2(g.arena_left,294),Vector2(g.arena_left,326),c,2)
		line(Vector2(g.arena_right,294),Vector2(g.arena_right,326),c,2)
		for i in range(6):
			rect(10+i*11,315+i%3*12,3,2,c.darkened(.5))
			rect(575+i*11,315+i%3*12,3,2,c.darkened(.5))
	if not g.boss.is_empty():boss_art()
	for h in g.hazards:hazard(h,c)
	for e in g.enemies:enemy(e,c)
	for gift in g.pickups:pickup(gift)
	for b in g.bullets:
		var dir = b.v.normalized()
		line(b.p-dir*8,b.p,MINT,2)
		rect(b.p.x-1,b.p.y-1,3,3,CREAM)
	# Small flat shadow; no expensive dynamic lighting.
	rect(g.p.x-12,g.FLOOR-1,24,3,Color(.03,.04,.07,.65))
	hero(g.p)
	for q in g.particles:rect(q.p.x,q.p.y,2,2,q.c)
	for f in g.floaters:center(f.text,f.p.x,f.p.y,9,f.c)
	g.draw_set_transform(Vector2.ZERO)
	hud()
	if g.settings.touch:touch_controls()
	else:
		rect(0,337,640,23,Color(.035,.05,.08,.88))
		center("A D  MOVER    ESPACIO  SALTO ×2    S  AGACHAR    J  DISPARAR    SHIFT  IMPULSO",320,351,8,MUTED)
	if g.tutorial_active and g.state=="play":tutorial()

func hazard(h: Dictionary,c: Color) -> void:
	if h.wait>0:
		var pulse = .4+abs(sin(g.clock*10))*.4
		if h.kind==0:
			line(Vector2(h.p.x,60),Vector2(h.p.x,286),Color(c,.12))
			g.draw_arc(Vector2(h.p.x,290),12,PI,TAU,12,Color(c,pulse),2,false)
			text("!",h.p.x-2,278,10,c)
		elif h.kind==1:
			var x = 12 if h.p.x<0 else 619
			text(">>" if h.p.x<0 else "<<",x,h.p.y+3,10,CORAL)
		elif h.kind==2:
			line(Vector2(h.p.x-15,291),Vector2(h.p.x+15,291),CORAL,2)
			text("!",h.p.x-2,280,12,CORAL)
		else:
			diamond(h.p,5,Color(c,pulse))
		return
	if h.kind==2:
		for j in range(3):
			var x = h.p.x-10+j*8
			var height = 31 if j!=1 else 43
			g.draw_colored_polygon(PackedVector2Array([Vector2(x-5,294),Vector2(x,294-height),Vector2(x+6,294)]),c.darkened(.3))
			line(Vector2(x,293-height),Vector2(x+3,288),c)
	elif h.kind==3:
		diamond(h.p,7,c.darkened(.4))
		diamond(h.p,4,c)
		rect(h.p.x-1,h.p.y-1,2,2,CREAM)
	else:
		if not g.settings.low:
			var dir = h.v.normalized()
			line(h.p-dir*14,h.p-dir*7,Color(c,.3),2)
		g.draw_texture_rect_region(g.textures["hazards_%d" % g.zone],Rect2((h.p-Vector2(12,12)).floor(),Vector2(24,24)),Rect2(h.variant*24,0,24,24))

func enemy(e: Dictionary,c: Color) -> void:
	var p = e.p.floor()
	if e.age<0:
		g.draw_arc(p-Vector2(0,10),16,0,TAU,12,Color(c,.5),1,false)
		center("!",p.x,p.y-5,13,c)
		return
	var tint = Color.WHITE if e.flash>0 else c
	if e.flying:
		var flap = int(sin(g.clock*12)*4)
		rect(p.x-20,p.y-20+flap,10,5,c.darkened(.5))
		rect(p.x+10,p.y-20-flap,10,5,c.darkened(.5))
	else:
		rect(p.x-10,p.y-3,7,4,INK)
		rect(p.x+3,p.y-3,7,4,INK)
	rect(p.x-13,p.y-26,26,22,INK)
	rect(p.x-10,p.y-24,20,17,tint.darkened(.45))
	rect(p.x-10,p.y-24,20,3,tint)
	rect(p.x-7,p.y-18,4,4,CREAM)
	rect(p.x+3,p.y-18,4,4,CREAM)
	rect(p.x-4,p.y-10,8,2,INK)
	diamond(p+Vector2(-9,-28),4,tint)
	diamond(p+Vector2(9,-28),4,tint)

func boss_art() -> void:
	var b = g.boss
	var c = Color(World.ZONES[g.zone].color)
	var at = b.p
	g.draw_arc(at,57,0,TAU,24,Color(c,.15),2,false)
	for i in range(6):
		var a = i*TAU/6+g.clock*.3
		diamond(at+Vector2(cos(a),sin(a))*57,3,Color(c,.5))
	tex("boss_%d" % g.zone,Rect2((at-Vector2(48,48)).floor(),Vector2(96,96)),Color(1.8,1.8,1.8) if b.flash>0 else Color.WHITE)
	if b.phase==2:
		for i in range(4):star(at+Vector2(-36+i*24,-50-abs(sin(g.clock*4+i))*8),c,2)

func pickup(gift: Dictionary) -> void:
	var at = gift.p.floor()
	var c = MINT
	g.draw_arc(at,12,0,TAU,12,Color(c,.55),1,false)
	diamond(at,9,Color("244d51"))
	match gift.kind:
		"heal":heart(at-Vector2(3,3),CORAL)
		"shield":
			g.draw_colored_polygon(PackedVector2Array([at+Vector2(-5,-5),at+Vector2(5,-5),at+Vector2(4,2),at+Vector2(0,6),at+Vector2(-4,2)]),MINT)
			line(at+Vector2(0,-3),at+Vector2(0,3),Color("337074"))
		"slow":
			g.draw_arc(at,5,0,TAU,12,CREAM,1,false)
			line(at,at+Vector2(0,-4),CREAM)
			line(at,at+Vector2(3,0),CREAM)
		"rapid":
			line(at+Vector2(2,-5),at+Vector2(-2,0),CREAM,2)
			line(at+Vector2(-2,0),at+Vector2(2,0),CREAM,2)
			line(at+Vector2(2,0),at+Vector2(-2,5),CREAM,2)
	star(at+Vector2(13,-9),c,1)

func hud() -> void:
	var c = Color(World.ZONES[g.zone].color)
	panel(Rect2(10,9,164,35),INK,EDGE)
	for i in range(3):heart(Vector2(20+i*21,19),CORAL if i<g.hp else Color("3c3947"),2)
	text("%06d" % g.score,94,30,12,CREAM)
	panel(Rect2(183,9,272,35),INK,EDGE)
	text("%02d" % (g.selected+1),193,31,18,c)
	fitted(g.level_data.get("name",""),227,30,218,11,CREAM)
	panel(Rect2(464,9,113,35),INK,EDGE)
	if g.level_data.get("boss",false):
		center("JEFE · FASE %d" % g.boss.get("phase",1),520,30,10,c)
	else:
		var remain = maxi(0,int(ceil(g.duration-g.elapsed)))
		center("%02d:%02d" % [remain/60,remain%60],520,32,17,CREAM)
	button("II",Rect2(586,9,44,35),"pause")
	var progress = minf(g.elapsed/g.duration,1)
	rect(11,48,566,3,Color("273447"))
	rect(11,48,566*progress,3,c)
	if not g.boss.is_empty():
		var b = g.boss
		panel(Rect2(210,60,220,18),INK,EDGE)
		rect(213,63,214*maxf(0,b.hp/b.max_hp),3,c)
		center(World.ZONES[g.zone].boss,320,74,8,CREAM)
	# Dash status is visible without covering the arena.
	panel(Rect2(12,60,97,17),INK,EDGE)
	var ready = g.dash_cooldown<=0
	text("IMPULSO" if ready else "RECARGANDO",18,72,8,MINT if ready else MUTED)
	rect(76,66,26*(1-clampf(g.dash_cooldown/1.15,0,1)),4,MINT)
	if g.slow_time>0:
		panel(Rect2(12,82,97,17),INK,EDGE)
		text("TIEMPO LENTO  %d" % int(ceil(g.slow_time)),18,94,8,MINT)
	if g.rapid_time>0:
		panel(Rect2(12,104,97,17),INK,EDGE)
		text("RÁFAGA  %d" % int(ceil(g.rapid_time)),18,116,8,MINT)
	if g.shield>0:
		text("ESCUDO ACTIVO",516,67,8,MINT)

func touch_controls() -> void:
	var labels = {"left":"<","right":">","duck":"ABAJO","dash":"IMPULSO","shoot":"FUEGO","jump":"SALTO"}
	for pair in g.touch_rects():
		var r = pair[1]
		var active = g.touch_actions.get(pair[0],false) or g.mouse_action==pair[0]
		panel(r,Color("33514e") if active else Color(.06,.10,.15,.84),Color("57776f"))
		center(labels[pair[0]],r.get_center().x,r.get_center().y+4,9,MINT)

func tutorial() -> void:
	var messages = ["MUÉVETE  /  A D o flechas", "SALTA DOS VECES  /  ESPACIO", "AGÁCHATE  /  S o flecha abajo", "DISPARA  /  Mantén J", "IMPÚLSATE  /  SHIFT o K"]
	if g.settings.touch:
		messages = ["MUÉVETE  /  Botones < y >", "SALTA DOS VECES  /  SALTO", "AGÁCHATE  /  Mantén ABAJO", "DISPARA  /  Mantén FUEGO", "ESQUIVA  /  Botón IMPULSO"]
	panel(Rect2(135,108,370,63),INK,Color("789c8c"))
	center("PRIMEROS PASOS  %d / 5" % (g.tutorial_step+1),320,124,8,MINT)
	center(messages[g.tutorial_step],320,145,13,CREAM)
	button("SALTAR GUÍA",Rect2(266,177,108,23),"skip_tutorial")

func dim() -> void:
	rect(0,0,640,360,Color(.025,.035,.065,.84))
	g.buttons.clear()

func pause_menu() -> void:
	dim()
	panel(Rect2(173,44,294,273),PANEL,EDGE)
	center("TOMA AIRE.",320,79,25,CREAM)
	center("El pánico puede esperar un momento.",320,101,10,MUTED)
	button("SEGUIR JUGANDO",Rect2(210,121,220,34),"resume",true)
	button("VOLVER A INTENTAR",Rect2(210,167,220,31),"retry")
	button("AJUSTES Y CONTROLES",Rect2(210,209,220,31),"settings")
	button("VOLVER AL MAPA",Rect2(210,251,220,31),"map")
	center("ESC / P PARA CONTINUAR",320,301,8,MUTED)

func result(won: bool) -> void:
	dim()
	var color = MINT if won else CORAL
	panel(Rect2(107,37,426,286),PANEL,EDGE)
	rect(108,38,424,3,color)
	center("ARENA SUPERADA" if won else "TE GANÓ EL PÁNICO",320,71,22,color)
	if won:
		for i in range(3):star(Vector2(280+i*40,102),Color("f6ba70") if i<g.result_stars else EDGE,10)
		center("IMPECABLE." if g.result_stars==3 else "SIGUES EN PIE. ESO CUENTA.",320,136,15,CREAM)
		center("%06d PUNTOS   ·   %d ENEMIGOS" % [g.score,g.kills],320,160,11,MUTED)
		center("Progreso guardado · El siguiente desafío te espera.",320,181,9,MUTED)
	else:
		tex("boss_%d" % g.zone,Rect2(285,83,70,70))
		center(g.death_message,320,176,11,CREAM)
		center("TE ALCANZÓ: " + g.damage_source,320,198,9,MUTED)
		center("Pista: " + ["sal de los avisos dorados.","agáchate ante los proyectiles altos.","reserva el impulso para emergencias."][g.selected%3],320,218,9,MUTED)
	button(("FINAL  >" if g.selected==19 else "SIGUIENTE NIVEL  >") if won else "OTRA VEZ. AHORA SÍ.  >",Rect2(150,235,340,33),"next" if won else "retry",true)
	button("VOLVER AL MAPA",Rect2(150,280,340,25),"map")

func settings_menu() -> void:
	tex("map",Rect2(0,0,640,360),Color(.38,.45,.54))
	panel(Rect2(25,18,590,323),INK,EDGE)
	text("A TU MANERA",44,47,23,CREAM)
	text("PEQUEÑO EN RECURSOS. GRANDE EN PÁNICO.",45,65,8,MUTED)
	button("< VOLVER",Rect2(516,32,80,29),"back")
	var rows = [["music","Música"],["sound","Efectos de sonido"],["taunts","Burlas y risas"],["low","Modo ligero · 30 FPS"],["touch","Controles táctiles"],["auto_fire","Disparo automático"]]
	for i in range(rows.size()):
		var y = 88+i*35
		text(rows[i][1],46,y+17,11,CREAM)
		button("SÍ" if g.settings[rows[i][0]] else "NO",Rect2(243,y,49,25),"toggle:"+rows[i][0],g.settings[rows[i][0]])
	line(Vector2(313,87),Vector2(313,307),EDGE)
	text("TU PEQUEÑO ARSENAL",333,101,11,MINT)
	var controls = [["A D / ← →","Moverte"],["ESPACIO / W","Doble salto"],["S / ↓","Agacharte"],["J / Z","Disparar"],["SHIFT / K / X","Impulso"],["ESC / P","Pausa"]]
	for i in range(controls.size()):
		text(controls[i][0],333,126+i*24,9,CREAM)
		text(controls[i][1],457,126+i*24,9,MUTED)
	text("MÓVIL: JUEGA EN HORIZONTAL",333,285,9,MINT)
	text("El disparo apunta al enemigo cercano.",333,303,8,MUTED)
	text("Sin conexión · Sin anuncios · Sin compras",45,325,8,MUTED)

func ending() -> void:
	tex("zone_3",Rect2(0,0,640,360))
	rect(0,0,640,360,Color(.04,.05,.10,.7))
	for i in range(20):star(Vector2(30+i*31,45+sin(i*2+g.clock)*12),Color("f6ba70"),2)
	center("EL PÁNICO TAMBIÉN TIEMBLA.",320,107,24,CREAM)
	center("20 niveles. 5 mundos. Un guardián que nunca se rindió.",320,138,11,MINT)
	hero(Vector2(320,238),2.3,true)
	center("Gracias por acompañar a Nilo.",320,268,12,CREAM)
	button("VOLVER AL ATLAS  >",Rect2(203,291,234,34),"map",true)
	center("Repite las arenas para conseguir las tres estrellas.",320,349,9,MUTED)
