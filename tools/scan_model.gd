extends SceneTree
## Dev tool: prints a height map of a model's top surfaces (headless, no window).
##   godot --headless --path . --script res://tools/scan_model.gd -- water/ship-ocean-liner 2.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var name := args[0] if args.size() > 0 else "water/ship-ocean-liner"
	var s := float(args[1]) if args.size() > 1 else 1.0
	var root := Node3D.new()
	get_root().add_child(root)
	var m: Node3D = (load("res://assets/%s.glb" % name) as PackedScene).instantiate()
	m.scale = Vector3.ONE * s
	root.add_child(m)
	var body := StaticBody3D.new()
	root.add_child(body)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		cs.transform = m.transform * (mi as MeshInstance3D).transform
		body.add_child(cs)
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	for x in [0.0, 1.5, 3.0, 4.2]:
		var row := PackedStringArray()
		for z in range(-22, 23, 2):
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, 40, z), Vector3(x, -5, z))
			var hit := space.intersect_ray(q)
			row.append("%5.1f" % (hit.position.y if hit else -9.0))
		print("x=%3.1f %s" % [x, " ".join(row)])
	quit()
