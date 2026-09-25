extends Node3D
## "La grúa": a port crane lifting a container up and down beside a tall stack of containers.
## Hop onto the container at the bottom, ride it up, and step across onto the top of the
## stack, where the sweet is. The lift is at local x=0; the stack is at +X.

const S := 2.4                    # container scale
const CONT_H := 1.1 * S           # one container's height
const STACK := 4
const BOTTOM := -1.6              # lift container's base at the bottom (sunk, so its top is easy to reach)
const WAIT_BOTTOM := 2.5
const WAIT_TOP := 3.0
const MOVE := 5.0

var sweet: Node3D
var lift: AnimatableBody3D

var _cable: MeshInstance3D
var _t := 0.0


func top_y() -> float:
	return CONT_H * STACK                  # the top of the stack


func lift_base(t: float) -> float:
	# The lift's base height over one cycle: wait, up, wait, down.
	var cycle := WAIT_BOTTOM + MOVE + WAIT_TOP + MOVE
	var k := fmod(t, cycle)
	var high := top_y() - CONT_H + 0.15     # its top ends a touch above the stack top
	if k < WAIT_BOTTOM:
		return BOTTOM
	k -= WAIT_BOTTOM
	if k < MOVE:
		return lerpf(BOTTOM, high, smoothstep(0.0, 1.0, k / MOVE))
	k -= MOVE
	if k < WAIT_TOP:
		return high
	k -= WAIT_TOP
	return lerpf(high, BOTTOM, smoothstep(0.0, 1.0, k / MOVE))


func setup() -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	# The stack of containers.
	var names := ["water/cargo-container-a", "water/cargo-container-b", "water/cargo-container-c"]
	for k in STACK:
		var c := Props.model(names[k % 3])
		c.scale = Vector3.ONE * S
		c.position = Vector3(3.5, k * CONT_H, 0)
		add_child(c)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.38 * S, CONT_H * STACK, 2.76 * S)
	cs.shape = sh
	cs.position = Vector3(3.5, CONT_H * STACK / 2.0, 0)
	body.add_child(cs)
	# The crane: a lattice tower, a long jib over the lift, and a cable.
	var orange := Props.mat(Color(1.0, 0.6, 0.15))
	var tower_h := top_y() + 6.0
	_solid(body, Vector3(1.4, tower_h, 1.4), Vector3(-3.4, tower_h / 2.0, 0), orange)
	for y in range(1, int(tower_h), 2):
		_mesh(self, _box(Vector3(1.5, 0.12, 1.5)), Vector3(-3.4, y, 0), Props.mat(Color(0.3, 0.3, 0.35)))
	_mesh(self, _box(Vector3(9.0, 0.9, 1.0)), Vector3(-0.6, tower_h + 0.45, 0), orange)
	_mesh(self, _box(Vector3(1.6, 1.4, 1.6)), Vector3(-3.4, tower_h + 1.3, 0), Props.mat(Color(0.95, 0.95, 1.0)))   # cab
	_cable = _mesh(self, _box(Vector3(0.08, 1.0, 0.08)), Vector3.ZERO, Props.mat(Color(0.2, 0.2, 0.25)))
	# The lift: a container on the hook.
	lift = AnimatableBody3D.new()
	lift.add_to_group("moving")
	lift.position = Vector3(0, BOTTOM, 0)
	add_child(lift)
	var lc := Props.model("water/cargo-container-b")
	lc.scale = Vector3.ONE * S
	lift.add_child(lc)
	var lcs := CollisionShape3D.new()
	var lsh := BoxShape3D.new()
	lsh.size = Vector3(1.38 * S, CONT_H, 2.76 * S)
	lcs.shape = lsh
	lcs.position.y = CONT_H / 2.0
	lift.add_child(lcs)
	var sign := Label3D.new()
	sign.text = "La grúa"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 110
	sign.pixel_size = 0.007
	sign.outline_size = 18
	sign.modulate = Color(1, 0.75, 0.3)
	sign.outline_modulate = Color(0.25, 0.2, 0.3)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(-3.4, tower_h + 3.2, 0)
	add_child(sign)
	_place()


func sweet_spot() -> Vector3:
	return to_global(Vector3(3.5, top_y() + 0.9, 0.8))


func stack_top() -> Vector3:
	return to_global(Vector3(3.5, top_y() + 0.3, -1.5))


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	var y := lift_base(_t)
	lift.position = Vector3(0, y, 0)
	var jib := top_y() + 6.0
	var top := y + CONT_H
	_cable.scale.y = maxf(0.1, jib - top)
	_cable.position = Vector3(0, (jib + top) / 2.0, 0)


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


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi
