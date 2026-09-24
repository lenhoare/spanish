extends Node3D
## "Tienda de dulces": a round candy-striped hut with a locked door.
## Find the key somewhere on the island to get in. The roof stops anyone jumping in.
## The door faces local +Z.

const R := 4.0
const WALL_H := 3.2
const DOOR_W := 2.4

var opened := false

var _door_pivot: Node3D
var _door_body: StaticBody3D
var _lock: Node3D
var _nag := 0.0


func setup() -> void:
	var cream := Props.mat(Color(1.0, 0.95, 0.85))
	var pink := Props.mat(Color(1.0, 0.55, 0.72))
	var roof_mat := Props.mat(Color(0.93, 0.3, 0.45))

	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)

	# Striped wall ring with a gap for the door (door is at angle PI/2 = +Z).
	var n := 22
	var seg_w := TAU * R / n * 1.08
	for i in n:
		var a := TAU * i / n
		var gap := absf(wrapf(a - PI / 2, -PI, PI))
		if gap < (DOOR_W / 2.0) / R:
			continue
		var pos := Vector3(cos(a) * R, WALL_H / 2.0, sin(a) * R)
		var box := BoxMesh.new()
		box.size = Vector3(seg_w, WALL_H, 0.45)
		box.material = pink if i % 2 == 0 else cream
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.position = pos
		mi.rotation.y = -a + PI / 2
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = box.size
		cs.shape = sh
		cs.position = pos
		cs.rotation.y = mi.rotation.y
		body.add_child(cs)

	# Lintel above the door so the gap is only door-shaped.
	var lintel := BoxMesh.new()
	lintel.size = Vector3(DOOR_W + 0.6, 0.5, 0.5)
	lintel.material = cream
	var lm := MeshInstance3D.new()
	lm.mesh = lintel
	lm.position = Vector3(0, WALL_H - 0.25, R)
	body.add_child(lm)

	# Pointy roof with a cherry on top.
	var roof := CylinderMesh.new()
	roof.top_radius = 0.05
	roof.bottom_radius = R + 1.2
	roof.height = 3.2
	roof.radial_segments = 22
	roof.rings = 1
	roof.material = roof_mat
	var rm := MeshInstance3D.new()
	rm.mesh = roof
	rm.position.y = WALL_H + 1.6
	body.add_child(rm)
	var rcs := CollisionShape3D.new()
	rcs.shape = roof.create_convex_shape()
	rcs.position = rm.position
	body.add_child(rcs)
	var cherry := SphereMesh.new()
	cherry.radius = 0.45
	cherry.height = 0.9
	cherry.material = Props.mat(Color(0.85, 0.1, 0.2))
	var cm := MeshInstance3D.new()
	cm.mesh = cherry
	cm.position.y = WALL_H + 3.3
	body.add_child(cm)

	# Floor
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = R
	floor_mesh.bottom_radius = R
	floor_mesh.height = 0.1
	floor_mesh.material = Props.mat(Color(0.98, 0.85, 0.9))
	var fm := MeshInstance3D.new()
	fm.mesh = floor_mesh
	fm.position.y = 0.03
	add_child(fm)

	# Sign
	var sign := Label3D.new()
	sign.text = "Tienda de dulces"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 72
	sign.pixel_size = 0.006
	sign.outline_size = 16
	sign.modulate = Color(1, 1, 1)
	sign.outline_modulate = Color(0.8, 0.2, 0.45)
	sign.position = Vector3(0, WALL_H + 0.45, R + 0.5)
	add_child(sign)

	# The door (hinged on its left edge) with a big padlock.
	_door_pivot = Node3D.new()
	_door_pivot.position = Vector3(-DOOR_W / 2.0, 0, R)
	add_child(_door_pivot)
	_door_body = StaticBody3D.new()
	_door_pivot.add_child(_door_body)
	var door := BoxMesh.new()
	door.size = Vector3(DOOR_W, WALL_H - 0.5, 0.25)
	door.material = Props.mat(Color(0.6, 0.35, 0.22))
	var dm := MeshInstance3D.new()
	dm.mesh = door
	dm.position = Vector3(DOOR_W / 2.0, (WALL_H - 0.5) / 2.0, 0)
	_door_body.add_child(dm)
	var dcs := CollisionShape3D.new()
	var dsh := BoxShape3D.new()
	dsh.size = door.size
	dcs.shape = dsh
	dcs.position = dm.position
	_door_body.add_child(dcs)
	_lock = Props.model("lock")
	_lock.scale = Vector3.ONE * 2.2
	_lock.position = Vector3(DOOR_W / 2.0, 1.1, 0.2)
	_door_pivot.add_child(_lock)

	# Knock on the door (stand in front of it) to use the key.
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := BoxShape3D.new()
	ash.size = Vector3(DOOR_W + 1.0, 2.5, 2.0)
	acs.shape = ash
	acs.position = Vector3(0, 1.25, R + 1.0)
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_door)


func _process(delta: float) -> void:
	_nag -= delta


func _on_door(body: Node) -> void:
	if opened or not body.is_in_group("player"):
		return
	if not Game.has_key:
		if _nag <= 0:
			_nag = 3.0
			Game.sfx("wrong", 1.2, -6)
			Game.show_toast("The sweet shop is locked! Find the key somewhere on the island...")
		return
	opened = true
	Game.has_key = false
	Game.key_changed.emit()
	Game.sfx("build", 0.9)
	Game.show_toast("Click! The key opens the sweet shop!")
	var t := create_tween()
	t.tween_property(_lock, "position:y", 3.0, 0.3)
	t.parallel().tween_property(_lock, "scale", Vector3.ONE * 0.01, 0.3)
	t.tween_property(_door_pivot, "rotation:y", deg_to_rad(105), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _door_body.collision_layer = 0)
