extends SceneTree
## Dev tool: renders a model from the side (+X) and front (+Z) with axis markers.
## godot --path . --script res://tools/snap_model.gd -- water/boat-row-large

func _init() -> void:
	var name := OS.get_cmdline_user_args()[0]
	var root3d := Node3D.new()
	get_root().add_child(root3d)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.8, 0.88, 1.0)
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	root3d.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.6, 0)
	root3d.add_child(sun)
	for i in 2:
		var m: Node3D = load("res://assets/%s.glb" % name).instantiate()
		root3d.add_child(m)
		m.position.x = -2.2 + i * 4.4
		m.rotation.y = 0.0 if i == 0 else PI / 2
		# red marker = +Z of the model
		var mk := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.15
		s.height = 0.3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.RED
		s.material = mat
		mk.mesh = s
		mk.position = Vector3(0, 0.5, 2.0)
		m.add_child(mk)
	var cam := Camera3D.new()
	root3d.add_child(cam)
	cam.look_at_from_position(Vector3(0, 6, 7), Vector3(0, 0.3, 0))
	for f in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_user_data_dir().path_join("shots/model.png"))
	quit()
