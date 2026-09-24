extends Node3D
## A rowing boat. Jump into it from the jetty to row: the joystick / WASD steers (relative
## to the camera), a gentle current pushes you back out to sea, and rocks and buoys bump you.
## Jump near any shore to hop out onto the land. The bow points along local -Z.

const SEA_Y := -1.3
const ROW_SPEED := 7.0
const ACCEL := 3.5
const DRAG := 1.2
const CURRENT := Vector3(1.3, 0, 0.9)     # drifts you back towards the main island's coast
const WORLD_LIMIT := 110.0

var vel := Vector3.ZERO
var rider: CharacterBody3D
## Circles the boat can't enter: [Vector2 centre, radius]. Filled in by the world.
var blockers: Array = []
## Land you can hop out onto: [Vector3 centre, grass radius, (optional) exact landing spot].
var shores: Array = []

var _model: Node3D
var _t := 0.0
var _board_cd := 0.0
var _exit_cd := 0.0
var _told := false


func setup() -> void:
	add_to_group("rowboat")
	_model = Props.model("water/boat-row-large")
	_model.scale = Vector3.ONE * 2.2
	_model.position.y = -0.35
	add_child(_model)
	global_position.y = SEA_Y
	# Jump (or walk) into the boat to climb aboard.
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.6, 3.0, 5.0)
	cs.shape = sh
	cs.position.y = 1.2
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func seat() -> Vector3:
	return to_global(Vector3(0, 0.6, 0.4))


func _on_body(body: Node) -> void:
	if rider or _board_cd > 0 or Game.ui_open or not body.is_in_group("player"):
		return
	board(body)


func board(body: CharacterBody3D) -> void:
	rider = body
	_exit_cd = 0.5
	body.ride(self)
	Game.sfx("thud", 1.4, -6.0)
	if not _told:
		_told = true
		Game.show_toast("¡A remar! Steer with the joystick. Jump near land to get out.")


func _physics_process(delta: float) -> void:
	_t += delta
	_board_cd -= delta
	_exit_cd -= delta
	var input := Vector2.ZERO
	if rider and not Game.ui_open:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Game.touch_move.length() > 0.05:
			input = Game.touch_move
		if _exit_cd <= 0 and Input.is_action_just_pressed("jump"):
			_try_exit()
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, rider.camera_yaw if rider else 0.0)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dir.length() > 0.05:
		vel = vel.move_toward(dir * ROW_SPEED, ACCEL * delta)
	else:
		vel = vel.move_toward(Vector3.ZERO, DRAG * delta)
	# The current only matters out in open water.
	if rider and _nearest_shore_gap() > 6.0:
		vel += CURRENT * delta * 0.5
	global_position += vel * delta
	_collide()
	# Face where we're going, and bob on the waves.
	if vel.length() > 0.4:
		rotation.y = lerp_angle(rotation.y, atan2(-vel.x, -vel.z), 1.0 - exp(-3.0 * delta))
	global_position.y = SEA_Y + sin(_t * 1.7) * 0.08
	_model.rotation.z = sin(_t * 1.3) * 0.04
	_model.rotation.x = sin(_t * 1.1 + 1.0) * 0.03


func _collide() -> void:
	var p := Vector2(global_position.x, global_position.z)
	for b in blockers:
		var c: Vector2 = b[0]
		var r: float = b[1] + 1.6
		var off := p - c
		if off.length() < r:
			var n := off.normalized() if off.length() > 0.01 else Vector2(1, 0)
			p = c + n * r
			var v2 := Vector2(vel.x, vel.z)
			if v2.dot(n) < 0:
				v2 = v2.bounce(n) * 0.4
				vel = Vector3(v2.x, 0, v2.y)
				if rider:
					Game.sfx("thud", 1.2, -8.0)
	if p.length() > WORLD_LIMIT:
		p = p.normalized() * WORLD_LIMIT
		vel = Vector3.ZERO
	global_position.x = p.x
	global_position.z = p.y


func _nearest_shore_gap() -> float:
	var p := Vector2(global_position.x, global_position.z)
	var best := INF
	for s in shores:
		var c: Vector3 = s[0]
		best = minf(best, p.distance_to(Vector2(c.x, c.z)) - s[1])
	return best


func _try_exit() -> void:
	var p := Vector2(global_position.x, global_position.z)
	for s in shores:
		var c: Vector3 = s[0]
		var r: float = s[1]
		var d := p.distance_to(Vector2(c.x, c.z)) - r
		if d < 5.5:
			# Hop out onto the grass just inside the shore, facing inland.
			var n := (Vector2(c.x, c.z) - p).normalized()
			var land := Vector2(c.x, c.z) - n * (r - 1.5)
			var land3 := Vector3(land.x, c.y + 0.4, land.y)
			if s.size() > 2:
				land3 = s[2]     # e.g. the deck of a ship
			var who := rider
			rider = null
			_board_cd = 1.5
			vel = Vector3.ZERO
			who.unride(land3)
			return
	Game.sfx("wrong", 1.2, -6.0)
	Game.show_toast("¡Demasiado lejos! Row closer to land to get out.")
