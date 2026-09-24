extends SceneTree
## Dev tool: measures the pirate ship's deck heights and renders it next to a character.
## godot --path . --script res://tools/probe_ship.gd

const SCALE := 1.6

func _init() -> void:
	var root3d := Node3D.new()
	get_root().add_child(root3d)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.7, 0.85, 1.0)
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	root3d.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0)
	root3d.add_child(sun)

	var ship: Node3D = load("res://assets/pirate/ship-pirate-large.glb").instantiate()
	ship.scale = Vector3.ONE * SCALE
	root3d.add_child(ship)
	await process_frame
	var body := StaticBody3D.new()
	root3d.add_child(body)
	for mi in ship.find_children("*", "MeshInstance3D", true, false):
		print("mesh part: ", mi.name, "  aabb ", (mi as MeshInstance3D).get_aabb())
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		body.add_child(cs)
		cs.global_transform = (mi as MeshInstance3D).global_transform

	var guy: Node3D = load("res://assets/characters/character-female-f.glb").instantiate()
	guy.scale = Vector3.ONE * 1.6
	root3d.add_child(guy)
	guy.position = Vector3(5.5, 0, 0)

	var cam := Camera3D.new()
	root3d.add_child(cam)
	cam.look_at_from_position(Vector3(26, 6, 0), Vector3(0, 6, 0))

	for f in 3:
		await physics_frame
	var space := root3d.get_world_3d().direct_space_state
	for z in [-10.0, -8.0, -6.0, -4.0, -2.0, -1.0, 0.0, 1.0, 2.0, 4.0, 6.0, 8.0, 10.0]:
		for x in [0.0, 1.5, 3.0]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -5, z))
			var hit := space.intersect_ray(q)
			print("ray x=%.1f z=%.1f -> %s" % [x, z, ("%.2f" % hit.position.y) if hit else "none"])
	for f in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_user_data_dir().path_join("shots/ship.png"))
	quit()
