extends Node3D
## "El circuito": a timed obstacle course out over the sea. Start at the whistle on the grass,
## cross stepping stones, jump the hurdles on the dock, balance along the beam, climb the posts,
## ride the sliding platform and reach the finish islet before the clock runs out.
## Falling in the sea ends the attempt (you pop back at the start). The course runs along
## local +X; set the node's rotation to aim it.

const TIME_LIMIT := 30.0
const FINISH_X := 46.0

signal finished

var running := false
var done := false
var time_left := 0.0
var sweet: Node3D

var _wood: StandardMaterial3D
var _paint: StandardMaterial3D
var _mover: AnimatableBody3D
var _mover_t := 0.0
var _start_area: Area3D
var _finish_area: Area3D
var _cool := 0.0


func setup() -> void:
	_wood = Props.mat(Color(0.72, 0.5, 0.33))
	_paint = Props.mat(Color(1.0, 0.45, 0.6))
	var white := Props.mat(Color(1, 1, 1))

	# Start pad on the grass with a painted line and a whistle post.
	_box(Vector3(3.0, 0.08, 4.0), Vector3(1.5, 0.04, 0), Props.mat(Color(0.95, 0.9, 1.0)), false)
	_box(Vector3(0.3, 0.1, 4.0), Vector3(3.0, 0.06, 0), _paint, false)
	var post := Props.place(self, "flag", Vector3(0.5, 0, -2.3), 0.0, 2.4, "cyl")
	post.name = "StartFlag"
	var sign := Label3D.new()
	sign.text = "El Circuito"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 80
	sign.pixel_size = 0.008
	sign.outline_size = 18
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.outline_modulate = Color(0.6, 0.15, 0.35)
	sign.position = Vector3(1.5, 3.2, 0)
	add_child(sign)
	_start_area = _area(Vector3(2.5, 2.0, 4.0), Vector3(1.5, 1.0, 0))
	_start_area.body_entered.connect(_on_start)

	# 1. Stepping stones across the shallows.
	for i in 3:
		_disc(Vector3(5.5 + i * 2.6, -0.1, (0.6 if i % 2 == 0 else -0.6)), 0.9, 0.35)
	# 2. A floating dock with hurdles to jump.
	_box(Vector3(9.0, 0.3, 3.0), Vector3(17.0, -0.15, 0), _wood)
	for x in [14.5, 17.0, 19.5]:
		_box(Vector3(0.25, 0.75, 3.0), Vector3(x, 0.375, 0), _paint)
		for zz in [-1.4, 1.4]:
			_box(Vector3(0.2, 0.75, 0.2), Vector3(x, 0.375, zz), white, false)
	# 3. A balance beam, a little higher.
	_box(Vector3(1.0, 0.8, 1.2), Vector3(22.0, 0.4, 0), _wood)          # step up
	_box(Vector3(7.0, 0.25, 0.5), Vector3(26.0, 0.8, 0), _paint)       # the beam
	# 4. Climbing posts.
	var posts := [[30.5, 1.3], [32.8, 2.0], [35.0, 2.7]]
	for pp in posts:
		_disc(Vector3(pp[0], pp[1], 0), 0.6, pp[1] + 1.8)
	# 5. A platform sliding side to side.
	_mover = AnimatableBody3D.new()
	add_child(_mover)
	_mover.position = Vector3(38.8, 2.7, 0)
	var mm := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = Vector3(2.4, 0.3, 2.4)
	mbox.material = _paint
	mm.mesh = mbox
	mm.position.y = -0.15
	_mover.add_child(mm)
	var mcs := CollisionShape3D.new()
	var msh := BoxShape3D.new()
	msh.size = mbox.size
	mcs.shape = msh
	mcs.position.y = -0.15
	_mover.add_child(mcs)
	# 6. The finish islet with a chequered flag.
	_disc(Vector3(FINISH_X, 2.7, 0), 3.0, 4.5, true)
	var ff := Props.place(self, "flag", Vector3(FINISH_X + 1.5, 2.7, -1.5), 0.0, 2.6, "cyl")
	ff.name = "FinishFlag"
	_finish_area = _area(Vector3(5.0, 3.0, 5.0), Vector3(FINISH_X, 4.0, 0))
	_finish_area.body_entered.connect(_on_finish)


func sweet_spot() -> Vector3:
	return to_global(Vector3(FINISH_X, 2.75, 0.6))


func _physics_process(delta: float) -> void:
	_mover_t += delta
	_mover.position.z = sin(_mover_t * 1.2) * 2.6
	_cool -= delta
	if not running:
		return
	time_left -= delta
	get_tree().call_group("hud", "set_timer", time_left)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if time_left <= 0:
		_fail("¡Se acabó el tiempo! Back to the start and try again.")
	elif player and player.global_position.y < -1.5:
		_fail("¡Al agua! Back to the start and try again.")


func _on_start(body: Node) -> void:
	if done or running or _cool > 0 or not body.is_in_group("player"):
		return
	running = true
	time_left = TIME_LIMIT
	Game.sfx("spring", 1.6)
	Game.show_toast("¡Preparados, listos... ¡YA! Reach the finish flag in %d seconds!" % int(TIME_LIMIT))


func _on_finish(body: Node) -> void:
	if not running or not body.is_in_group("player"):
		return
	running = false
	done = true
	get_tree().call_group("hud", "set_timer", -1.0)
	Game.sfx("win", 1.1)
	Game.show_toast("¡Increíble! %.1f seconds - the sweet has appeared!" % (TIME_LIMIT - time_left))
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	finished.emit()


func _fail(msg: String) -> void:
	running = false
	_cool = 1.0
	get_tree().call_group("hud", "set_timer", -1.0)
	Game.sfx("wrong", 0.9)
	Game.show_toast(msg)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and player.has_method("send_to"):
		player.send_to(to_global(Vector3(0.6, 0.3, 0)))


# ---------------------------------------------------------------- pieces

func _box(size: Vector3, pos: Vector3, m: Material, solid := true) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = m
	mi.mesh = box
	mi.position = pos
	if not solid:
		add_child(mi)
		return
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	mi.position = Vector3.ZERO
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)


## Round post/stone with its top at `top.y`, going down `depth` into the sea.
func _disc(top: Vector3, r: float, depth: float, grassy := false) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = Vector3(top.x, top.y - depth / 2.0, top.z)
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r * 0.9
	c.height = depth
	c.material = Props.mat(Color(0.55, 0.85, 0.45)) if grassy else _wood
	var mi := MeshInstance3D.new()
	mi.mesh = c
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = depth
	cs.shape = sh
	body.add_child(cs)


func _area(size: Vector3, pos: Vector3) -> Area3D:
	var a := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	a.position = pos
	add_child(a)
	return a
