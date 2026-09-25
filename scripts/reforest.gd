extends Node3D
## "Reforestación": a burnt patch of ground with holes dug ready. Take a young tree from the
## nursery (el vivero) - it floats over your head - and walk into a hole to plant it. It grows!
## Plant them all and the sweet appears.

const HOLES := [Vector2(-4.0, -2.5), Vector2(0.0, -4.0), Vector2(4.0, -2.5), Vector2(-3.0, 2.0), Vector2(3.0, 2.0)]

var sweet: Node3D
var done := false
var carrying := false
var planted := {}

var _carry: Node3D
var _count: Label3D
var _hole_nodes: Array[Node3D] = []


func setup() -> void:
	_flat(Vector3(13.0, 0.03, 11.0), Vector3(0, 0.015, -1.0), Props.mat(Color(0.2, 0.17, 0.17)))    # burnt ground
	for k in 6:
		var stump := Props.model("graveyard/pine-crooked")
		stump.scale = Vector3.ONE * 1.6
		stump.position = Vector3(-6.0 + k * 2.4, 0, -6.8 + (k % 2) * 0.6)
		stump.rotation.y = k * 1.3
		add_child(stump)
	for i in HOLES.size():
		var h := Node3D.new()
		add_child(h)
		h.position = Vector3(HOLES[i].x, 0, HOLES[i].y)
		var hole := CylinderMesh.new()
		hole.top_radius = 0.8
		hole.bottom_radius = 0.8
		hole.height = 0.05
		_mesh(h, hole, Vector3(0, 0.04, 0), Props.mat(Color(0.35, 0.22, 0.12)))
		var ring := TorusMesh.new()
		ring.inner_radius = 0.8
		ring.outer_radius = 1.0
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color(0.6, 1.0, 0.5)
		ring.material = rm
		var ri := MeshInstance3D.new()
		ri.mesh = ring
		ri.position.y = 0.06
		ri.name = "Ring"
		h.add_child(ri)
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 1.0
		sh.height = 2.0
		cs.shape = sh
		area.add_child(cs)
		area.position.y = 1.0
		h.add_child(area)
		area.body_entered.connect(_on_hole.bind(i))
		_hole_nodes.append(h)
	# The nursery: a little stall with saplings in pots.
	var stall := Node3D.new()
	add_child(stall)
	stall.position = Vector3(0, 0, 5.5)
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	stall.add_child(body)
	_mesh(body, _box(Vector3(3.6, 0.9, 1.0)), Vector3(0, 0.45, 0), Props.mat(Color(0.55, 0.4, 0.25)))
	var cs2 := CollisionShape3D.new()
	var sh2 := BoxShape3D.new()
	sh2.size = Vector3(3.6, 0.9, 1.0)
	cs2.shape = sh2
	cs2.position.y = 0.45
	body.add_child(cs2)
	for x in [-1.2, 0.0, 1.2]:
		var pot := Props.model("plant")
		pot.scale = Vector3.ONE * 1.2
		pot.position = Vector3(x, 0.9, 0)
		stall.add_child(pot)
	var sign := _label(stall, "El vivero", 64, Vector3(0, 2.6, 0), Color(0.6, 1.0, 0.5))
	sign.name = "Sign"
	_count = _label(self, "0 / %d" % HOLES.size(), 60, Vector3(0, 3.2, -1.0), Color.WHITE)
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := BoxShape3D.new()
	ash.size = Vector3(4.0, 2.0, 1.4)
	acs.shape = ash
	area.add_child(acs)
	area.position = Vector3(0, 1.0, 4.7)
	add_child(area)
	area.body_entered.connect(_on_nursery)


func nursery_spot() -> Vector3:
	return to_global(Vector3(0, 0.3, 4.3))


func hole_spot(i: int) -> Vector3:
	return to_global(Vector3(HOLES[i].x, 0.3, HOLES[i].y))


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 1.4, -1.0))


func _process(delta: float) -> void:
	if _carry and is_instance_valid(_carry):
		_carry.rotation.y += delta * 2.0


func _on_nursery(body: Node) -> void:
	if done or carrying or not body.is_in_group("player"):
		return
	carrying = true
	_carry = Props.model("plant")
	_carry.scale = Vector3.ONE * 1.1
	body.add_child(_carry)
	_carry.position = Vector3(0, 2.3, 0)
	Game.sfx("click", 1.2)
	Game.show_toast("¡Un arbolito! Plant it in one of the holes.")


func _on_hole(body: Node, i: int) -> void:
	if done or planted.has(i) or not body.is_in_group("player"):
		return
	if not carrying:
		Game.sfx("click")
		Game.show_toast("Fetch a young tree from el vivero first!")
		return
	carrying = false
	if _carry and is_instance_valid(_carry):
		_carry.queue_free()
	planted[i] = true
	var h: Node3D = _hole_nodes[i]
	(h.get_node("Ring") as Node3D).visible = false
	var tree := Props.model("tree")
	tree.scale = Vector3.ONE * 0.05
	h.add_child(tree)
	create_tween().tween_property(tree, "scale", Vector3.ONE * 1.9, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Game.sfx("correct", 1.0 + planted.size() * 0.08)
	_count.text = "%d / %d" % [planted.size(), HOLES.size()]
	if planted.size() < HOLES.size():
		Game.show_toast("¡Muy bien! %d / %d trees planted." % [planted.size(), HOLES.size()])
		return
	done = true
	_count.text = "¡Un bosque nuevo!"
	Game.sfx("win", 1.2)
	Game.show_toast("¡Fantástico! A new forest - a sweet has appeared among the trees!")
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _flat(size: Vector3, pos: Vector3, m: Material) -> void:
	var mi := _mesh(self, _box(size), pos, m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _label(parent: Node3D, text: String, size: int, pos: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 14
	l.modulate = col
	l.outline_modulate = Color(0.15, 0.25, 0.15)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
