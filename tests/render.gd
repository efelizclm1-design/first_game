extends SceneTree
## Render regression: every arena and every UI screen, without modifying player saves.
const Game = preload("res://scripts/game.gd")
var game
var output = "/tmp/pixel-panic-renders"
var captures = 0

func _init() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	assert(not img.is_empty(),"Renderer returned an empty image")
	var err = img.save_png(output.path_join(name+".png"))
	assert(err==OK,"Screenshot could not be saved")
	captures += 1

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	game = Game.new()
	game.test_mode = true
	game.save_enabled = false
	game.capture_mode = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.settings.sound = false
	game.unlocked=0
	game.change_state("title")
	await capture("title")
	game.unlocked=19
	game.selected=8
	game.change_state("map")
	await capture("map")
	for index in range(20):
		game.begin_level(index)
		game.change_state("play")
		game.tutorial_active=false
		game.invincible=1000
		game.settings.auto_fire=true
		for frame in range(21*60):
			if game.state!="play":break
			game.test_axis=1 if (frame/90)%2==0 else -1
			if frame%75==0:game.jump()
			game.step_game(1.0/60)
			game.step_particles(1.0/60)
		# Bosses can legitimately die during simulation; render their remaining or victory state.
		await capture("level_%02d" % (index+1))
	game.begin_level(19)
	game.settings.touch=true
	game.change_state("play")
	await capture("mobile")
	game.settings.touch=false
	game.capture_mode=false
	game.begin_level(0)
	game.change_state("play")
	for page in range(3):
		game.guide_page=page
		await capture("guide_%d" % page)
	game.activate("guide_next")
	await capture("practice")
	game.begin_level(19)
	for screen in ["loading","pause","dead","victory","settings","ending"]:
		game.change_state(screen)
		game.state_time=.8
		game.death_message="Tres corazones. Cero excusas."
		game.damage_source="Obsidiana"
		game.result_stars=3
		await capture(screen)
	print("RENDER PASS: ",captures," non-empty framebuffers saved; all 20 arenas and UI states.")
	game.queue_free()
	await process_frame
	quit()
