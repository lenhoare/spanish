extends Node3D
## A bridge built from sections. Each solved question card adds a section.
## Unbuilt sections show as faint "ghost" planks so players know what's missing.

signal completed

var sections := 1
var built := 0
var length := 10.0
var width := 3.0

var _ghosts: Array[Node3D] = []
var _wood: StandardMaterial3D
var _rope: StandardMaterial3D


## Bridge runs from local origin along -Z for `length` metres.
func setup(n_sections: int, bridge_length: float) -> void:
	sections = maxi(n_sections, 1)
	length = bridge_length
	_wood = Props.mat(Color(0.78, 0.52, 0.3))
	_rope = Props.mat(Color(0.95, 0.85, 0.6))
	var ghost_mat := Props.unshaded(Color(1, 1, 1, 0.22))
	for i in sections:
		var g := _make_section(i, ghost_mat, false)
		_ghosts.append(g)


func section_center(i: int) -> Vector3:
	var seg := length / sections
	return to_global(Vector3(0, 0, -(i + 0.5) * seg))


func build_next() -> void:
	if built >= sections:
		return
	var i := built
	built += 1
	_ghosts[i].queue_free()
	var s := _make_section(i, _wood, true)
	s.scale = Vector3(0.01, 0.01, 0.01)
	var t := create_tween()
	t.tween_property(s, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Game.sfx("build")
	if built == sections:
		completed.emit()


func _make_section(i: int, m: Material, solid: bool) -> Node3D:
	var seg := length / sections
	var root: Node3D
	if solid:
		var body := StaticBody3D.new()
		body.add_to_group("solid_ground")
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, 0.3, seg + 0.05)
		cs.shape = shape
		cs.position.y = -0.15
		body.add_child(cs)
		# Side rails stop accidental falls.
		for side in [-1, 1]:
			var rail := CollisionShape3D.new()
			var rs := BoxShape3D.new()
			rs.size = Vector3(0.2, 1.2, seg)
			rail.shape = rs
			rail.position = Vector3(side * (width / 2.0 + 0.1), 0.6, 0)
			body.add_child(rail)
		root = body
	else:
		root = Node3D.new()
	add_child(root)
	root.position = Vector3(0, 0, -(i + 0.5) * seg)

	var planks := int(seg / 0.55)
	for p in planks:
		var box := BoxMesh.new()
		box.size = Vector3(width, 0.2, 0.45)
		box.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.position = Vector3(randf_range(-0.05, 0.05), -0.1, -seg / 2.0 + 0.28 + p * (seg / planks))
		mi.rotation.y = randf_range(-0.04, 0.04)
		root.add_child(mi)
	if solid:
		for side in [-1, 1]:
			var post := CylinderMesh.new()
			post.top_radius = 0.1
			post.bottom_radius = 0.1
			post.height = 1.1
			post.material = _wood
			var pm := MeshInstance3D.new()
			pm.mesh = post
			pm.position = Vector3(side * (width / 2.0 + 0.05), 0.45, -seg / 2.0 + 0.1)
			root.add_child(pm)
			var rope := BoxMesh.new()
			rope.size = Vector3(0.08, 0.08, seg)
			rope.material = _rope
			var rm := MeshInstance3D.new()
			rm.mesh = rope
			rm.position = Vector3(side * (width / 2.0 + 0.05), 0.9, 0)
			root.add_child(rm)
	return root
