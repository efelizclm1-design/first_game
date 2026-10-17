extends RefCounted
## Native 1280x720 combat canvas. The existing menus retain their 640x360 layout.
const World = preload("res://scripts/world.gd")
const WHITE = Color("fff1d6")
const MINT = Color("a6edd9")
const AMBER = Color("ffce81")
const HOT = Color("ff8278")
const INK = Color("101827")
var g

func _init(game) -> void:g=game

func rect(r: Rect2,c: Color) -> void:g.draw_rect(r,c)
func line(a: Vector2,b: Vector2,c: Color,w: float=1) -> void:g.draw_line(a,b,c,w,false)
func text(s: String,p: Vector2,size: int=18,c: Color=WHITE) -> void:
 g.draw_string(g.font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func center(s: String,p: Vector2,size: int=18,c: Color=WHITE) -> void:
 text(s,p-Vector2(g.font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),size,c)
func panel(r: Rect2,c: Color=Color(.04,.07,.12,.93),border: Color=Color("3b5067")) -> void:
 rect(Rect2(r.position+Vector2(0,3),r.size),Color(0,0,0,.24))
 rect(r,c)
 g.draw_rect(r,border,false,1)
func diamond(at: Vector2,r: float,c: Color) -> void:
 g.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-r),at+Vector2(r,0),at+Vector2(0,r),at+Vector2(-r,0)]),c)
func dotted(a: Vector2,b: Vector2,c: Color,width: float=1,step: float=18) -> void:
 var delta=b-a
 var length=delta.length()
 if length<1:return
 var unit=delta/length
 for k in range(int(length/step)):
  line(a+unit*k*step,a+unit*(k*step+step*.4),c,width)
func heart(at: Vector2,color: Color,scale: int=3) -> void:
 var pixels=["0110110","1111111","1111111","0111110","0011100","0001000"]
 for y in range(6):
  for x in range(7):
   if pixels[y][x]=="1":rect(Rect2(at+Vector2(x,y)*scale,Vector2.ONE*scale),color)

func paint() -> void:
 var offset=Vector2.ZERO if g.settings.low else Vector2(sin(g.clock*71),cos(g.clock*89))*g.shake
 g.draw_set_transform(offset)
 g.draw_texture_rect(g.scene_texture,Rect2(0,0,1280,720),false)
 weather()
 terrain()
 for platform in g.platforms:ledge(platform)
 if not g.boss.is_empty():boss()
 for e in g.enemies:enemy(e)
 for gift in g.pickups:pickup(gift)
 for h in g.hazards:
  if h.wait<=0:hazard(h)
 for b in g.bullets:
  var dir=b.v.normalized()
  line(b.p-dir*29,b.p-dir*4,Color(.35,.95,.86,.25),8)
  line(b.p-dir*20,b.p,MINT,4)
  line(b.p-dir*8,b.p+dir*4,WHITE,3)
 player()
 for q in g.particles:
  rect(Rect2(q.p,Vector2(3,3)),q.c)
 for f in g.floaters:center(f.text,f.p,16,f.c)
 # Telegraphs draw last within the world so scenery and actors never hide them.
 for h in g.hazards:
  if h.wait>0:warning(h)
 g.draw_set_transform(Vector2.ZERO)
 hud()
 if g.settings.touch:touch_controls()
 else:
  panel(Rect2(0,685,1280,35),Color(.025,.045,.08,.9),Color("2a3548"))
  center("A D  MOVER     ESPACIO  DOBLE SALTO     S  AGACHAR     J  DISPARAR     SHIFT  IMPULSO",Vector2(640,708),15,Color("b4c1cb"))
 if g.tutorial_active and g.state=="play":tutorial()
 # Shared menus, overlays and click rectangles still use the original UI space.
 g.draw_set_transform(Vector2.ZERO,0,Vector2(2,2))

func weather() -> void:
 var count=12 if g.settings.low else 30
 for i in range(count):
  var x=fmod(i*137.0+g.clock*(8+i%5),1280)
  var y=120+fmod(i*57.0+g.clock*(10+i%7),465)
  if g.zone==1:
   rect(Rect2(x,y,2,2),Color(.7,.9,1,.35))
  elif g.zone==3:
   if i<9:
    var by=205+fmod(i*59.0,220)
    var wing=sin(g.clock*6+i)*4
    line(Vector2(x-8,by+wing),Vector2(x,by+3),Color("f9f5e3"),2)
    line(Vector2(x,by+3),Vector2(x+8,by+wing),Color("f9f5e3"),2)
    line(Vector2(x-3,by+3),Vector2(x+3,by+3),Color("6887a3"),1)
  elif g.zone==2:
   line(Vector2(x,y),Vector2(x-3,y+12),Color(.6,.75,.9,.12),1)
  else:
   rect(Rect2(x,y,2,2),Color(1,.68,.45,.28))

func ledge(r: Rect2) -> void:
 var c=Color(World.ZONES[g.zone].color)
 rect(Rect2(r.position+Vector2(0,5),r.size+Vector2(0,9)),Color("151d2c"))
 rect(r,Color("354153"))
 line(r.position,r.position+Vector2(r.size.x,0),c,2)
 line(r.position+Vector2(3,3),r.position+Vector2(r.size.x-3,3),c.darkened(.5))
 for x in range(int(r.position.x)+8,int(r.end.x)-3,18):
  line(Vector2(x,r.position.y+6),Vector2(x,r.position.y+15),Color("566273"),2)

func terrain() -> void:
 for patch in g.lava_patches:
  var r=patch.rect
  var left=r.position.x
  var right=r.end.x
  if patch.state=="warning":
   rect(Rect2(left,g.FLOOR-4,r.size.x,15),Color(.95,.46,.12,.35))
   for x in range(int(left)+3,int(right)-9,18):
    line(Vector2(x,g.FLOOR+10),Vector2(x+7,g.FLOOR+2),AMBER,2)
    line(Vector2(x+7,g.FLOOR+2),Vector2(x+13,g.FLOOR+7),AMBER,2)
   badge(Vector2(r.get_center().x,g.FLOOR-73),patch.timer/patch.duration)
   panel(Rect2(r.get_center().x-73,g.FLOOR-126,146,25),INK,AMBER)
   center("¡EL SUELO ARDE!",Vector2(r.get_center().x,g.FLOOR-108),13,AMBER)
  else:
   var active=patch.state=="active"
   rect(Rect2(left-3,g.FLOOR-4,r.size.x+6,29),Color("432b34"))
   rect(Rect2(left,g.FLOOR-2,r.size.x,22),Color("c74428") if active else Color("765048"))
   for x in range(int(left)+2,int(right)-3,7):
    var wave=sin(g.clock*7+x*.11)*3
    line(Vector2(x,g.FLOOR+wave),Vector2(x+6,g.FLOOR-wave),Color("ffe096") if active else Color("bd8564"),3)
    if active and x%3==0:rect(Rect2(x,g.FLOOR-8-fmod(g.clock*29+x,15),2,3),Color("ffc060"))
   if active:
    panel(Rect2(r.get_center().x-29,g.FLOOR+28,58,22),INK,HOT)
    center("LAVA",Vector2(r.get_center().x,g.FLOOR+44),12,AMBER)
 if g.arena_phase=="warning":
  for r in [Rect2(0,g.FLOOR-4,g.target_left,12),Rect2(g.target_right,g.FLOOR-4,1280-g.target_right,12)]:
   rect(r,Color(1,.4,.35,.28))
   for x in range(int(r.position.x),int(r.end.x)-9,18):line(Vector2(x,g.FLOOR+5),Vector2(x+10,g.FLOOR-4),HOT,3)
  badge(Vector2(g.target_left*.5,g.FLOOR-50),g.arena_timer/1.65,"!")
  badge(Vector2((g.target_right+1280)*.5,g.FLOOR-50),g.arena_timer/1.65,"!")
 if g.arena_phase in ["shrinking","small","restoring"]:
  for r in [Rect2(0,g.FLOOR,g.arena_left,118),Rect2(g.arena_right,g.FLOOR,1280-g.arena_right,118)]:
   rect(r,Color("080d19"))
  line(Vector2(g.arena_left,g.FLOOR),Vector2(g.arena_left,g.FLOOR+44),HOT,2)
  line(Vector2(g.arena_right,g.FLOOR),Vector2(g.arena_right,g.FLOOR+44),HOT,2)
  for i in range(10):
   var x=14+i*17
   if x<g.arena_left:rect(Rect2(x,g.FLOOR+24+fmod(g.clock*31+i*9,66),3,2),Color("8c5552"))
   if 1280-x>g.arena_right:rect(Rect2(1280-x,g.FLOOR+24+fmod(g.clock*31+i*9,66),3,2),Color("8c5552"))

func badge(at: Vector2,remaining: float,label: String="!") -> void:
 var pulse=.65+sin(g.clock*12)*.15
 diamond(at,27,Color(.04,.05,.08,.95))
 diamond(at,24,AMBER)
 diamond(at,20,INK)
 center(label,at+Vector2(0,8),26,AMBER)
 g.draw_arc(at,29,-PI*.5,-PI*.5+TAU*clampf(remaining,0,1),24,Color(AMBER,pulse),2,false)

func warning(h: Dictionary) -> void:
 var progress=h.wait/maxf(.01,h.warning)
 match h.kind:
  0:
   var x=h.p.x
   rect(Rect2(x-18,201,36,g.FLOOR-201),Color(1,.65,.3,.035))
   dotted(Vector2(x,201),Vector2(x,g.FLOOR-9),Color(1,.75,.4,.48),1,20)
   line(Vector2(x-24,g.FLOOR-3),Vector2(x+24,g.FLOOR-3),AMBER,3)
   badge(Vector2(x,166),progress)
   g.draw_colored_polygon(PackedVector2Array([Vector2(x-7,198),Vector2(x+7,198),Vector2(x,207)]),AMBER)
  1:
   var left=h.base_v.x>0
   var x=32 if left else 1248
   var y=h.p.y
   rect(Rect2(54,y-6,1172,12),Color(1,.6,.35,.045))
   dotted(Vector2(65,y),Vector2(1215,y),Color(1,.72,.4,.4),1,25)
   badge(Vector2(x,y),progress,">" if left else "<")
   if g.selected<3 or g.tutorial_active:
    panel(Rect2(70 if left else 1080,y-48,130,25),INK,Color("966b4b"))
    center("AGÁCHATE" if y<g.FLOOR-30 else "SALTA",Vector2(135 if left else 1145,y-30),14,AMBER)
  2:
   var x=h.p.x
   rect(Rect2(x-28,g.FLOOR-7,56,11),Color(1,.55,.32,.4))
   line(Vector2(x-28,g.FLOOR-5),Vector2(x+28,g.FLOOR-5),AMBER,2)
   for j in range(3):
    var xx=x-17+j*17
    g.draw_colored_polygon(PackedVector2Array([Vector2(xx-9,g.FLOOR),Vector2(xx,g.FLOOR-50),Vector2(xx+9,g.FLOOR)]),Color(1,.65,.36,.11))
   badge(Vector2(x,g.FLOOR-86),progress)
  3:
   g.draw_arc(h.p,17,0,TAU,16,AMBER,2,false)
   dotted(h.p,h.p+h.base_v.normalized()*100,Color(1,.6,.35,.5),2,18)

func hazard(h: Dictionary) -> void:
 if h.kind==2:
  var colors=[Color("dda766"),Color("99eff8"),Color("ed9bff"),Color("ffe4a3"),Color("ff984e")]
  for j in range(3):
   var x=h.p.x-19+j*19
   var top=g.FLOOR-(64 if j==1 else 49)
   if g.zone==2:
    line(Vector2(x,g.FLOOR),Vector2(x-7,top+28),INK,9)
    line(Vector2(x-7,top+28),Vector2(x+7,top+23),colors[g.zone],4)
    line(Vector2(x+7,top+23),Vector2(x,top),colors[g.zone],3)
   else:
    g.draw_colored_polygon(PackedVector2Array([Vector2(x-12,g.FLOOR),Vector2(x,top),Vector2(x+12,g.FLOOR)]),Color("343548"))
    g.draw_colored_polygon(PackedVector2Array([Vector2(x-8,g.FLOOR-2),Vector2(x,top+5),Vector2(x+8,g.FLOOR-2)]),colors[g.zone])
    line(Vector2(x,top+5),Vector2(x+5,g.FLOOR-7),WHITE,2)
    if g.zone==0:line(Vector2(x,top+22),Vector2(x-12,top+14),colors[0],3)
 elif h.kind==3:
  var dir=h.v.normalized()
  line(h.p-dir*18,h.p,Color(1,.35,.3,.25),12)
  if g.zone==3:
   g.draw_set_transform(h.p,h.v.angle())
   g.draw_texture_rect_region(g.textures.threats_3,Rect2(-24,-24,48,48),Rect2(96,0,48,48))
   g.draw_set_transform(Vector2.ZERO)
  else:
   g.draw_circle(h.p,12,Color("34243c"))
   g.draw_circle(h.p,9,HOT)
   g.draw_circle(h.p-Vector2(2,2),4,WHITE)
 else:
  var dir=h.v.normalized()
  if not g.settings.low:line(h.p-dir*30,h.p-dir*12,Color(1,.6,.35,.22),8)
  # Thin warm outline makes hostile objects distinct from blue/green gifts.
  g.draw_arc(h.p,20,0,TAU,16,Color(1,.66,.43,.25),1,false)
  if g.zone==3 and h.kind==1 and h.variant==2:
   g.draw_set_transform(h.p,0,Vector2(signf(h.v.x),1))
   g.draw_texture_rect_region(g.textures.threats_3,Rect2(-24,-24,48,48),Rect2(96,0,48,48))
   g.draw_set_transform(Vector2.ZERO)
  else:g.draw_texture_rect_region(g.textures["threats_%d" % g.zone],Rect2(h.p-Vector2(24,24),Vector2(48,48)),Rect2(h.variant*48,0,48,48))

func player() -> void:
 var at=g.p
 var row=0
 var frame=int(g.clock*6)%8
 if g.ducking:
  row=3
 elif g.dash_time>0:
  row=4
 elif not g.grounded:
  row=2
  frame=0 if g.velocity.y<0 else 4
 elif absf(g.velocity.x)>8:
  row=1
  frame=int(g.run_cycle)%8
 if g.hurt_flash>0:row=5
 var alpha=.48 if g.invincible>0 and g.hurt_flash<=0 and int(g.clock*16)%2==0 else 1.0
 var modulate=Color(1,1,1,alpha)
 g.draw_set_transform(at,0,Vector2(g.facing,1))
 g.draw_texture_rect_region(g.textures.nilo_actions,Rect2(-32,-64,64,64),Rect2(frame*64,row*64,64,64),modulate)
 g.draw_set_transform(Vector2.ZERO)
 var shoulder=at+Vector2(g.facing*8,-21 if g.ducking else -31)
 var angle=g.aim_direction.angle()
 g.draw_set_transform(shoulder,angle,Vector2(1,1 if g.facing>0 else -1))
 g.draw_texture_rect(g.textures.nilo_arm,Rect2(-2,-9,34,18),false,modulate)
 if g.muzzle_flash>0:
  var length=18+g.muzzle_flash*120
  g.draw_colored_polygon(PackedVector2Array([Vector2(30,-8),Vector2(42,-3),Vector2(35,-12),Vector2(31+length,0),Vector2(35,10),Vector2(40,3),Vector2(30,7)]),MINT)
  line(Vector2(31,0),Vector2(41,0),WHITE,5)
 g.draw_set_transform(Vector2.ZERO)
 if g.shield>0:
  g.draw_arc(at-Vector2(0,29),37,0,TAU,32,Color(.55,.94,.86,.7),1,false)
  diamond(at+Vector2(30,-56),4,MINT)

func enemy(e: Dictionary) -> void:
 var at=e.p
 if e.state=="spawn":
  var t=clampf(1-e.timer/1.1,0,1)
  g.draw_arc(at-Vector2(0,27),31,0,TAU,24,Color(AMBER,.35+t*.4),2,false)
  badge(at-Vector2(0,78),1-t)
  return
 var frame=int(g.sim_time*8+e.phase)%4
 if e.state=="windup":frame=4+int(g.clock*10)%2
 elif e.state in ["attack","charge"]:frame=6+int(g.clock*12)%2
 g.draw_set_transform(at,0,Vector2(e.dir,1))
 g.draw_texture_rect_region(g.inhabitant_texture,Rect2(-36,-69,72,72),Rect2(frame*72,e.role*72,72,72),Color(1.7,1.7,1.7) if e.flash>0 else Color.WHITE)
 g.draw_set_transform(Vector2.ZERO)
 if e.hp<e.max_hp:
  rect(Rect2(at.x-24,at.y-79,48,4),INK)
  rect(Rect2(at.x-24,at.y-79,48*e.hp/e.max_hp,4),HOT)
 if e.state=="windup":
  badge(at-Vector2(0,110),e.timer/maxf(.86,g.pressure.warning))
  var origin=at-Vector2(0,31)
  if e.role!=1:
   dotted(origin,origin+e.locked*200,Color(1,.65,.42,.55),1,16)
   g.draw_circle(origin,6+sin(g.clock*20)*2,AMBER)
  else:
   dotted(at-Vector2(0,9),at+Vector2(e.dir*190,-9),Color(1,.65,.42,.6),2,20)
 if e.state=="attack":
  var muzzle=at-Vector2(0,31)
  diamond(muzzle,16,Color(1,.75,.5,.8))
  diamond(muzzle,7,WHITE)
 if e.practice:
  center("OBJETIVO DE PRÁCTICA",at-Vector2(0,94),13,MINT)

func boss() -> void:
 var b=g.boss
 var frame=int(g.sim_time*3)%2
 if b.state=="windup":frame=2
 if b.state=="attack":frame=3
 g.draw_texture_rect_region(g.textures["guardian_%d" % g.zone],Rect2(b.p-Vector2(96,96),Vector2(192,192)),Rect2(frame*192,0,192,192),Color(1.6,1.6,1.6) if b.flash>0 else Color.WHITE)
 if b.state=="windup":
  g.draw_arc(b.p,102,0,TAU,40,Color(1,.67,.43,.35),2,false)
  badge(b.p-Vector2(0,125),b.timer/1.15)
 if b.state=="attack":
  diamond(b.p+Vector2(0,55),20,Color(1,.65,.4,.6))
  diamond(b.p+Vector2(0,55),10,WHITE)

func pickup(gift: Dictionary) -> void:
 var at=gift.p
 var bob=sin(g.clock*3+at.x)*2
 at.y+=bob
 g.draw_circle(at,19,Color("123d42"))
 g.draw_arc(at,19,0,TAU,24,MINT,2,false)
 g.draw_arc(at,25,g.clock*.8,g.clock*.8+PI*.7,20,Color(.5,.9,.8,.28),1,false)
 match gift.kind:
  "heal":heart(at-Vector2(7,6),HOT,2)
  "shield":
   g.draw_colored_polygon(PackedVector2Array([at+Vector2(-9,-10),at+Vector2(9,-10),at+Vector2(7,4),at+Vector2(0,12),at+Vector2(-7,4)]),MINT)
   line(at+Vector2(0,-6),at+Vector2(0,6),Color("327c83"),2)
  "slow":
   g.draw_arc(at,10,0,TAU,20,WHITE,2,false)
   line(at,at+Vector2(0,-7),WHITE,2)
   line(at,at+Vector2(5,0),WHITE,2)
  "rapid":
   g.draw_colored_polygon(PackedVector2Array([at+Vector2(3,-12),at+Vector2(-7,2),at+Vector2(1,2),at+Vector2(-3,12),at+Vector2(8,-3),at+Vector2(1,-3)]),WHITE)

func hud() -> void:
 panel(Rect2(18,16,250,63))
 for i in range(3):heart(Vector2(32+i*35,30),HOT if i<g.hp else Color("424050"),3)
 text("%06d" % g.score,Vector2(151,53),19,WHITE)
 panel(Rect2(281,16,530,63))
 text("%02d" % (g.selected+1),Vector2(296,58),32,Color(World.ZONES[g.zone].color))
 text(g.level_data.name,Vector2(352,43),19)
 text(World.ZONES[g.zone].name,Vector2(353,64),12,Color("a7b5c6"))
 panel(Rect2(824,16,190,63))
 text("RITMO",Vector2(840,37),12,Color("aab8c7"))
 text("%.2f×" % g.pressure.rate,Vector2(840,64),24,AMBER)
 for i in range(11):
  var bright=g.pressure.rate>1+i*.18
  rect(Rect2(932+i*6,58-i*.9,4,7+i*.9),AMBER if bright else Color("324154"))
 panel(Rect2(1027,16,144,63))
 if g.level_data.boss and not g.boss.is_empty():center("JEFE  /  %d" % g.boss.phase,Vector2(1099,54),17,HOT)
 else:
  var remain=maxi(0,int(ceil(g.duration-g.elapsed)))
  center("%02d:%02d" % [remain/60,remain%60],Vector2(1099,55),26)
 g.draw_set_transform(Vector2.ZERO,0,Vector2(2,2))
 g.painter.button("II",Rect2(592,8,39,31),"pause")
 g.draw_set_transform(Vector2.ZERO)
 rect(Rect2(18,86,1153,3),Color("27394d"))
 rect(Rect2(18,86,1153*g.pressure.progress,3),Color(World.ZONES[g.zone].color))
 if not g.boss.is_empty():
  panel(Rect2(435,100,410,36))
  rect(Rect2(442,107,396,4),Color("452f41"))
  rect(Rect2(442,107,396*maxf(0,g.boss.hp/g.boss.max_hp),4),HOT)
  center(World.ZONES[g.zone].boss,Vector2(640,129),13,WHITE)
 panel(Rect2(18,102,157,28))
 text("IMPULSO",Vector2(27,121),13,MINT if g.dash_cooldown<=0 else Color("8fa2b3"))
 rect(Rect2(104,112,59*(1-clampf(g.dash_cooldown/1.05,0,1)),6),MINT)
 if g.shield>0:text("ESCUDO",Vector2(1197,112),11,MINT)
 if g.slow_time>0:text("TIEMPO LENTO  %d" % int(ceil(g.slow_time)),Vector2(23,154),12,MINT)
 if g.rapid_time>0:text("RÁFAGA  %d" % int(ceil(g.rapid_time)),Vector2(23,176),12,MINT)
 if not g.tutorial_active and g.no_shot_time>6 and not g.enemies.is_empty() and g.state=="play":
  panel(Rect2(450,643,380,29),INK,Color("677e87"))
  center("MANTÉN J PARA DISPARAR HACIA DELANTE",Vector2(640,663),13,MINT)

func touch_controls() -> void:
 var labels={"left":"<","right":">","duck":"ABAJO","dash":"IMPULSO","shoot":"FUEGO","jump":"SALTO"}
 for pair in g.touch_rects():
  var r=Rect2(pair[1].position*2,pair[1].size*2)
  var active=g.touch_actions.get(pair[0],false) or g.mouse_action==pair[0]
  panel(r,Color("30534f") if active else Color(.04,.075,.12,.88),Color("647d88"))
  center(labels[pair[0]],r.get_center()+Vector2(0,7),18,MINT)

func tutorial() -> void:
 if g.guide_page>=0:
  guide()
  return
 var titles=["01 / MOVERSE", "02 / DOBLE SALTO", "03 / AGACHARSE", "04 / DISPARAR", "05 / IMPULSO", "06 / RECOGER AYUDAS"]
 var messages=["Muévete con A D o las flechas.","Pulsa ESPACIO dos veces. Salta sobre la ráfaga baja.","Mantén S. La ráfaga alta pasa por encima.","Mira al enemigo y mantén J hasta derrotarlo.","Pulsa SHIFT para atravesar el peligro.","Acércate al escudo verde para recogerlo."]
 if g.settings.touch:messages=["Muévete con los botones < y >.","Toca SALTO dos veces.","Mantén ABAJO. Evita la ráfaga alta.","Mira al enemigo y mantén FUEGO.","Toca IMPULSO para esquivar.","Recoge el escudo verde."]
 panel(Rect2(377,169,526,108),Color(.035,.065,.11,.96),Color("78988d"))
 center(titles[g.tutorial_step],Vector2(640,194),14,MINT)
 center(messages[g.tutorial_step],Vector2(640,224),16,WHITE)
 center("PRÁCTICA SEGURA · El tiempo espera a que aprendas",Vector2(640,253),12,Color("9caebe"))
 g.draw_set_transform(Vector2.ZERO,0,Vector2(2,2))
 g.painter.button("YA SÉ JUGAR",Rect2(272,144,96,24),"skip_tutorial")
 g.draw_set_transform(Vector2.ZERO)

func guide() -> void:
 rect(Rect2(0,0,1280,720),Color(.02,.04,.07,.66))
 panel(Rect2(210,126,860,473),Color("142439"),Color("7faeae"))
 rect(Rect2(210,126,860,5),MINT)
 text("PIXEL PANIC  /  GUÍA DEL PRIMER NIVEL",Vector2(248,165),14,MINT)
 var titles=["Aprende a moverte y a luchar", "Lee las señales. Después, esquiva.", "Tres corazones. Veinte desafíos."]
 text(titles[g.guide_page],Vector2(248,206),27,WHITE)
 var rows=[]
 if g.guide_page==0:
  rows=[
   ["A D / FLECHAS", "Muévete. Nilo mira y dispara hacia el lado al que caminas."],
   ["ESPACIO / W", "Salta; pulsa otra vez en el aire para un segundo salto."],
   ["S / ABAJO", "Agáchate ante ataques altos. Abajo + salto baja de una plataforma."],
   ["J / Z", "Mantén pulsado para disparar. Gira si el enemigo está detrás."],
   ["SHIFT / K", "Impulso: atraviesa el peligro con una breve protección; luego recarga."],
   ["ESC / P", "Pausa y ajustes. En celular, usa los botones de la pantalla."]]
  if g.settings.touch:
   rows[0][0]="<  /  >"
   rows[1][0]="SALTO ×2"
   rows[2][0]="ABAJO"
   rows[3][0]="FUEGO"
   rows[4][0]="IMPULSO"
   rows[5][0]="II / PAUSA"
 elif g.guide_page==1:
  rows=[
   ["!  AMARILLO", "Avisa antes del golpe. El aro indica cuánto falta para que se active."],
   ["LÍNEA VERTICAL", "Algo caerá por esa columna: sal a un lado antes del impacto."],
   [">  /  <", "Ataque lateral: salta si viene bajo; agáchate si pasa alto."],
   ["SUELO MARCADO", "Raíces, pinchos o lava: abandona la zona antes de que se encienda."],
   ["ENEMIGO + !", "Está preparando un ataque. Lee su dirección y cambia de posición."],
   ["PRÁCTICA SEGURA", "Ahora probarás cada movimiento. Aquí no pierdes corazones."]]
 else:
  rows=[
   ["3 CORAZONES", "Cada golpe quita uno. Al perderlos, puedes reintentar el nivel."],
   ["ESCUDO / CORAZÓN", "El escudo absorbe un golpe; el corazón cura uno, hasta tres."],
   ["RELOJ / RÁFAGA", "Ralentiza los peligros 6 s o dispara más rápido durante 7 s."],
   ["META", "Sobrevive al tiempo indicado. En cada cuarto nivel, derrota al jefe."],
   ["TERRENO", "Usa las plataformas. Los bordes y las zonas de lava siempre avisan."],
   ["DIFICULTAD", "Cada arena acelera suavemente; cada nuevo nivel exige más habilidad."]]
 for i in range(rows.size()):
  var y=246+i*43
  text(rows[i][0],Vector2(249,y),13,AMBER)
  text(rows[i][1],Vector2(249,y+19),16,WHITE)
 text("%d / 3   ·   Esta guía aparece cada vez que entras al nivel 1." % (g.guide_page+1),Vector2(249,535),13,Color("acbdca"))
 g.draw_set_transform(Vector2.ZERO,0,Vector2(2,2))
 g.painter.button("OMITIR GUÍA",Rect2(124,277,109,21),"skip_tutorial")
 g.painter.button("PRACTICAR" if g.guide_page==2 else "SIGUIENTE",Rect2(421,277,95,21),"guide_next")
 g.draw_set_transform(Vector2.ZERO)
