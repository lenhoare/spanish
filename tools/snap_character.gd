extends SceneTree
## Dev tool: renders close-ups of a character in a few animations.
## godot --path . --script res://tools/snap_character.gd

func _init() -> void:
	var root3d := Node3D.new()
	get_root().add_child(root3d)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.8, 0.85, 0.95)
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	root3d.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0)
	root3d.add_child(sun)
	var cam := Camera3D.new()
	root3d.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.0, 4.2), Vector3(0, 0.75, 0))
	var names := ["../platformer/chest", "../platformer/character-oobi", "../platformer/character-oodi", "../platformer/character-ooli", "../platformer/character-oopi", "../platformer/character-oozi"]
	for i in names.size():
		var c: Node3D = load("res://assets/characters/%s.glb" % names[i]).instantiate()
		root3d.add_child(c)
		c.position = Vector3(-2.5 + (i % 6) * 1.0, 1.0 - (i / 6) * 1.0, 0)
		c.scale = Vector3.ONE * (1.5 if i == 0 else 0.9)
		var l := Label3D.new()
		l.text = names[i].replace("character-", "")
		l.font_size = 24
		l.pixel_size = 0.004
		l.position.y = -0.08
		c.add_child(l)
	for f in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_user_data_dir().path_join("shots/char.png"))
	quit()
