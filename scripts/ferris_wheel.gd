extends Node3D
## "La noria": a Ferris wheel. Hop into a gondola at the bottom, ride it up, and jump off
## at the top onto the lookout platform behind the wheel, where the sweet is.
## The wheel turns in the local XY plane; the lookout is behind it (local -Z).

const R := 7.5
const SPEED := 0.17          # radians per second
const GONDOLAS := 8
const HANG := 1.4            # gondola floor below its pin on the rim
const LOOKOUT_Z := -2.5

var sweet: Node3D

var _wheel: Node3D           # the spinning rims and spokes (visual only)
var _gondolas: Array[AnimatableBody3D] = []
var _angle := 0.0


func center_y() -> float:
	return R + HANG + 0.35


func setup() -> void:
	var cy := center_y()
	var frame := Props.mat(Color(0.95, 0.95, 1.0))
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	# A-frame legs on both sides holding the axle.
	for z in [-1.9, 1.9]:
		for sx in [-1.0, 1.0]:
			var leg := _mesh(body, _box(Vector3(0.35, cy / cos(0.28) + 0.4, 0.35)), Vector3(sx * cy * tan(0.28) / 2.0, cy / 2.0, z), frame)
			leg.rotation.z = sx * 0.28
		_solid(body, Vector3(cy * tan(0.28) * 2.0 + 0.8, 0.4, 0.8), Vector3(0, 0.2, z), Props.mat(Color(0.5, 0.45, 0.6)))
	_mesh(body, _cyl(0.35, 4.2), Vector3(0, cy, 0), Props.mat(Color(0.5, 0.45, 0.6))).rotation.x = PI / 2
	# The wheel itself: two rims, spokes and light bulbs.
	_wheel = Node3D.new()
	add_child(_wheel)
	_wheel.position = Vector3(0, cy, 0)
	var rim_mat := Props.mat(Color(1.0, 0.45, 0.65))
	for z in [-1.2, 1.2]:
		var rim := TorusMesh.new()
		rim.inner_radius = R - 0.15
		rim.outer_radius = R + 0.15
		rim.rings = 48
		rim.ring_segments = 8
		var rm := _mesh(_wheel, rim, Vector3(0, 0, z), rim_mat)
		rm.rotation.x = PI / 2
		for k in GONDOLAS:
			var a := TAU * k / GONDOLAS
			var spoke := _mesh(_wheel, _box(Vector3(R, 0.12, 0.12)), Vector3(cos(a), sin(a), 0) * R / 2.0 + Vector3(0, 0, z), frame)
			spoke.rotation.z = a
			var bulb := SphereMesh.new()
			bulb.radius = 0.2
			bulb.height = 0.4
			var bm := StandardMaterial3D.new()
			bm.albedo_color = Color(1, 0.9, 0.5)
			bm.emission_enabled = true
			bm.emission = Color(1, 0.85, 0.4)
			bm.emission_energy_multiplier = 1.2
			bulb.material = bm
			var bi := MeshInstance3D.new()
			bi.mesh = bulb
			bi.position = Vector3(cos(a + PI / GONDOLAS), sin(a + PI / GONDOLAS), 0) * R + Vector3(0, 0, z)
			_wheel.add_child(bi)
	# The gondolas: level platforms that go round with the wheel.
	var colors := [Color(1.0, 0.4, 0.45), Color(0.35, 0.65, 1.0), Color(1.0, 0.8, 0.3), Color(0.45, 0.85, 0.5)]
	for k in GONDOLAS:
		var g := AnimatableBody3D.new()
		g.add_to_group("moving")
		add_child(g)
		var col: Color = colors[k % colors.size()]
		_solid(g, Vector3(1.9, 0.2, 1.7), Vector3.ZERO, Props.mat(col))
		for sx in [-0.9, 0.9]:
			_mesh(g, _box(Vector3(0.08, HANG, 0.08)), Vector3(sx, HANG / 2.0, 0), frame)
		_mesh(g, _box(Vector3(1.9, 0.1, 0.1)), Vector3(0, HANG, 0), frame)
		_gondolas.append(g)
	# The lookout platform behind the top of the wheel, on a tall post.
	var top := cy + R - HANG
	_solid(body, Vector3(3.0, 0.3, 2.2), Vector3(0, top + 0.1, LOOKOUT_Z - 1.1), Props.mat(Color(0.95, 0.75, 0.3)))
	_solid(body, Vector3(0.5, top, 0.5), Vector3(0, top / 2.0, LOOKOUT_Z - 1.6), frame)
	var sign := Label3D.new()
	sign.text = "La noria"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 90
	sign.pixel_size = 0.006
	sign.outline_size = 16
	sign.modulate = Color(1, 0.85, 0.4)
	sign.outline_modulate = Color(0.4, 0.15, 0.4)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(-cy * tan(0.28) - 1.5, 3.0, 2.2)
	add_child(sign)
	_place(0.0)


func lookout() -> Vector3:
	return to_global(Vector3(0, center_y() + R - HANG + 0.3, LOOKOUT_Z - 1.1))


func sweet_spot() -> Vector3:
	return to_global(Vector3(0.8, center_y() + R - HANG + 1.2, LOOKOUT_Z - 1.3))


## The gondola nearest the bottom right now, in world space (for the test).
func bottom_gondola() -> AnimatableBody3D:
	var best: AnimatableBody3D = _gondolas[0]
	for g in _gondolas:
		if g.position.y < best.position.y:
			best = g
	return best


func top_gondola() -> AnimatableBody3D:
	var best: AnimatableBody3D = _gondolas[0]
	for g in _gondolas:
		if g.position.y > best.position.y:
			best = g
	return best


func _physics_process(delta: float) -> void:
	_angle += SPEED * delta
	_place(_angle)


func _place(a0: float) -> void:
	_wheel.rotation.z = a0
	for k in _gondolas.size():
		var a := a0 + TAU * k / GONDOLAS
		_gondolas[k].position = Vector3(cos(a) * R, center_y() + sin(a) * R - HANG, 0)


func _solid(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	_mesh(parent, _box(size), pos, m)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	parent.add_child(cs)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi
