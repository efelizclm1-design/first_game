extends SceneTree
## A small reactive player checks the opening arenas without changing game rules.
## It holds fire, reads nearby trajectories and uses the same move/jump/crouch inputs.
const Game=preload("res://scripts/game.gd")
var g
var failed=false
var evade_until=0.0
var evade_target=640.0

func _init() -> void:call_deferred("run")

func decide() -> void:
 g.test_actions={"shoot":true}
 g.test_axis=0
 var desired=640.0
 if not g.enemies.is_empty():
  var enemy=g.enemies[0]
  desired=enemy.p.x-330 if enemy.p.x>g.p.x else enemy.p.x+330
  g.test_axis=signf(enemy.p.x-g.p.x)
 if absf(desired-g.p.x)>40:g.test_axis=signf(desired-g.p.x)
 else:g.test_axis=0
 if g.elapsed<evade_until:
  g.test_axis=signf(evade_target-g.p.x) if absf(evade_target-g.p.x)>15 else 0
 for h in g.hazards:
  if h.kind==0:
   if h.p.y>g.FLOOR-300 and absf(h.p.x-g.p.x)<90:
    var direction=-1 if g.p.x<h.p.x else 1
    if absf(g.p.x-h.p.x)<1:direction=1 if g.p.x<640 else -1
    evade_target=clampf(h.p.x+direction*155,120,1160)
    evade_until=g.elapsed+2.0
    g.test_axis=signf(evade_target-g.p.x)
  elif h.kind==2 and absf(h.p.x-g.p.x)<75:
   evade_target=clampf(h.p.x+(-130 if g.p.x<h.p.x else 130),120,1160)
   evade_until=g.elapsed+1.7
   g.test_axis=signf(evade_target-g.p.x)
   if h.wait<.25 and g.grounded:g.jump()
  elif h.kind in [1,3] and h.wait<=0:
   var approaching=(g.p.x-h.p.x)*h.v.x>0
   var close=absf(h.p.x-g.p.x)<absf(h.v.x)*.27+25
   if h.kind==1 and h.p.y<g.FLOOR-30 and g.grounded and (approaching or absf(h.p.x-g.p.x)<50):
    if absf(h.p.x-g.p.x)<220:g.test_actions.duck=true
   elif approaching and close and absf(h.p.y-g.p.y)<65 and g.grounded:g.jump()
 # The held direction is the actual aim input; turn without approaching a nearby enemy.
 if g.test_axis==0 and not g.enemies.is_empty():
  var needed=signf(g.enemies[0].p.x-g.p.x)
  if g.facing!=needed:g.test_axis=needed

func run() -> void:
 g=Game.new()
 g.test_mode=true
 g.save_enabled=false
 root.add_child(g)
 g.set_process(false)
 g.set_physics_process(false)
 for index in [0,1]:
  g.begin_level(index)
  if g.tutorial_active:g.activate("skip_tutorial")
  g.change_state("play")
  g.settings.auto_fire=false
  evade_until=0
  for frame in range(int((g.duration+1)*60)):
   if g.state!="play":break
   decide()
   var hits=g.hits
   g.step_game(1.0/60)
   if g.hits>hits:print("CONTACT level=%d t=%.2f source=%s position=%s" % [index+1,g.elapsed,g.damage_source,g.p])
   g.step_particles(1.0/60)
  var ok=g.state=="victory" and g.hp>0 and g.kills>0 and g.shots_fired>0
  print("PLAYABILITY %s level %d: hp=%d hits=%d kills=%d shots=%d" % ["PASS" if ok else "FAIL",index+1,g.hp,g.hits,g.kills,g.shots_fired])
  if not ok:failed=true
 g.queue_free()
 await process_frame
 quit(1 if failed else 0)
