extends Node3D
## "El remolcador": drive the little green tug out to the big yellow container ship waiting
## at sea. Get close to its bow and the tow rope is thrown across; then the ship follows you.
## Bring it into the port (the marked berth behind the crane) and a sweet appears on the quay.
## Lives at the world origin; everything is placed in world space.

const HOOK_R := 9.0          # how close the tug must get to the ship's bow
const ROPE := 11.0           # tow rope length
const BERTH_R := 7.0

var tug: Node3D
var ship: Node3D
var berth := Vector3.ZERO
var sweet: Node3D
var hooked := false
var done := false
var keep_out_r := 0.0        # the ship stays at least this far from the island's middle
var quay: Array = []         # the quay as a solid rectangle - the ship can't be dragged through it

const HALF := Vector2(4.3, 11.6)   # the ship's half width and half length

var _rope: MeshInstance3D
var _ship_vel := Vector3.ZERO


func setup(ship_pos: Vector3, ship_yaw: float, berth_pos: Vector3, island_r: float) -> void:
	berth = berth_pos
	keep_out_r = island_r + 6.0
	ship = Node3D.new()
	add_child(ship)
	ship.position = ship_pos
	ship.rotation.y = ship_yaw
	var m := Props.model("water/ship-cargo-a")
	m.scale = Vector3.ONE * 2.2
	m.position.y = -2.2
	ship.add_child(m)
	var tag := _label(ship, "¡Remólcame!", 90, Vector3(0, 9.0, 0), Color(1, 0.85, 0.3))
	tag.name = "Tag"
	# The berth: a ring of buoys by the quay.
	for i in 10:
		var a := TAU * i / 10.0
		var b := Props.model("water/buoy")
		b.scale = Vector3.ONE * 1.4
		b.position = berth + Vector3(cos(a), 0, sin(a)) * BERTH_R + Vector3(0, -0.5, 0)
		add_child(b)
	_label(self, "El puerto", 100, berth + Vector3(0, 5.0, 0), Color(0.6, 0.9, 1.0))
	# The rope (hidden until hooked).
	_rope = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 1.0)
	bm.material = Props.mat(Color(0.9, 0.8, 0.55))
	_rope.mesh = bm
	_rope.visible = false
	add_child(_rope)


func ship_rect() -> Array:
	return [Vector2(ship.position.x, ship.position.z), HALF, ship.rotation.y]


func bow() -> Vector3:
	return ship.to_global(Vector3(0, 0, -11.0))


func _physics_process(delta: float) -> void:
	if done or not tug or not is_instance_valid(tug):
		return
	var tug_p := Vector3(tug.global_position.x, 0, tug.global_position.z)
	if not hooked:
		var b := bow()
		if tug.rider != null and Vector2(tug_p.x - b.x, tug_p.z - b.z).length() < HOOK_R:
			hooked = true
			Game.sfx("win", 1.5)
			Game.show_toast("¡Enganchado! The rope is on - tow the ship to the port behind the crane!")
			(ship.get_node("Tag") as Label3D).text = "¡Al puerto!"
		return
	# Towed: the ship's bow follows the tug at the end of the rope.
	var sp := Vector3(ship.position.x, 0, ship.position.z)
	var to_tug := tug_p - sp
	var dist := to_tug.length()
	var want := Vector3.ZERO
	if dist > ROPE + 11.0:
		want = to_tug.normalized() * minf((dist - ROPE - 11.0) * 1.6, 12.0)
	_ship_vel = _ship_vel.lerp(want, 1.0 - exp(-2.0 * delta))
	ship.position += _ship_vel * delta
	# Keep it clear of the quay (three circles along its length).
	if not quay.is_empty():
		var za := Vector3(sin(ship.rotation.y), 0, cos(ship.rotation.y))
		for k in [-7.5, 0.0, 7.5]:
			var pt: Vector3 = ship.position + za * float(k)
			var push: Vector2 = preload("res://scripts/rowboat.gd").push_out_rect(Vector2(pt.x, pt.z), HALF.x, quay)
			ship.position += Vector3(push.x, 0, push.y)
	# Keep it off the island.
	var flat := Vector2(ship.position.x, ship.position.z)
	if flat.length() < keep_out_r:
		var n := flat.normalized() * keep_out_r
		ship.position.x = n.x
		ship.position.z = n.y
	if _ship_vel.length() > 0.3:
		var yaw := atan2(-_ship_vel.x, -_ship_vel.z)
		ship.rotation.y = lerp_angle(ship.rotation.y, yaw, 1.0 - exp(-1.5 * delta))
	# The rope from the bow to the tug.
	var a := bow() + Vector3(0, 1.2, 0)
	var c := tug.global_position + Vector3(0, 1.0, 0)
	_rope.visible = true
	_rope.position = (a + c) / 2.0
	_rope.scale.z = maxf(0.1, a.distance_to(c))
	_rope.look_at(c, Vector3.UP)
	# In the berth?
	if Vector2(ship.position.x - berth.x, ship.position.z - berth.z).length() < BERTH_R:
		done = true
		_rope.visible = false
		Game.sfx("win", 1.1)
		Game.show_toast("¡Perfecto! The ship is in port - a sweet is waiting on the quay!")
		(ship.get_node("Tag") as Label3D).text = "¡Gracias!"
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _label(parent: Node3D, text: String, size: int, pos: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = size
	l.pixel_size = 0.008
	l.outline_size = 16
	l.modulate = col
	l.outline_modulate = Color(0.15, 0.2, 0.35)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
