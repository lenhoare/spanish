extends CharacterBody3D
## "El autobús escolar": a drivable yellow school bus. Walk into its door to get in, steer
## with the movement keys / joystick (relative to the camera, like the boats), jump to get out.
## It bumps into trees and buildings and stays on the island. Forward is local -Z.

const SPEED := 11.0
const ACCEL := 9.0
const DRAG := 10.0
const TURN := 2.6            # how quickly it swings round to the steering direction

var vel := Vector3.ZERO      # read by the player / camera while riding
var rider: CharacterBody3D
var island_r := 43.0
var seat_offset := Vector3(0, 1.3, -1.6)
var passenger: Node3D        # the classmate on board (set by the route)

var _board_cd := 0.0
var _exit_cd := 0.0
var _told := false


func setup() -> void:
	add_to_group("vehicle")
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	var yellow := Props.mat(Color(1.0, 0.8, 0.12))
	var black := Props.mat(Color(0.15, 0.15, 0.18))
	var glass := Props.mat(Color(0.7, 0.88, 1.0))
	_box(body, Vector3(2.4, 2.0, 6.4), Vector3(0, 1.45, 0), yellow)          # the body
	_box(body, Vector3(2.42, 0.18, 6.42), Vector3(0, 1.2, 0), black)          # stripe
	_box(body, Vector3(2.3, 0.9, 1.4), Vector3(0, 0.95, -3.7), yellow)        # bonnet
	_box(body, Vector3(2.0, 0.7, 0.05), Vector3(0, 1.95, -3.21), glass)       # windscreen
	for z in [-1.8, -0.4, 1.0, 2.4]:
		for x in [-1.21, 1.21]:
			_box(body, Vector3(0.03, 0.6, 1.0), Vector3(x, 1.95, z), glass)   # side windows
	_box(body, Vector3(0.03, 1.5, 0.8), Vector3(1.21, 1.2, -2.7), black)      # the door (right side)
	_box(body, Vector3(1.8, 0.7, 0.05), Vector3(0, 1.95, 3.21), glass)        # back window
	for x in [-0.9, 0.9]:
		_box(body, Vector3(0.3, 0.2, 0.05), Vector3(x, 0.75, 3.21), Props.mat(Color(0.95, 0.2, 0.2)))   # rear lights
	var back := Label3D.new()
	back.text = "ESCOLAR"
	back.font = preload("res://scripts/ui.gd").ui_font(700)
	back.font_size = 60
	back.pixel_size = 0.006
	back.modulate = Color(0.15, 0.15, 0.2)
	back.outline_size = 0
	back.position = Vector3(0, 1.3, 3.23)
	body.add_child(back)
	for z in [-2.6, 2.1]:
		for x in [-1.15, 1.15]:
			var w := CylinderMesh.new()
			w.top_radius = 0.5
			w.bottom_radius = 0.5
			w.height = 0.35
			w.material = black
			var wi := MeshInstance3D.new()
			wi.mesh = w
			wi.position = Vector3(x, 0.5, z)
			wi.rotation.z = PI / 2
			body.add_child(wi)
	var sign := Label3D.new()
	sign.text = "ESCOLAR"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 60
	sign.pixel_size = 0.006
	sign.modulate = Color(0.15, 0.15, 0.2)
	sign.outline_size = 0
	sign.position = Vector3(0, 2.3, -3.23)
	sign.rotation.y = PI
	body.add_child(sign)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.4, 2.2, 7.6)
	cs.shape = sh
	cs.position = Vector3(0, 1.4, -0.5)
	add_child(cs)
	# Get in by walking into the door side.
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := BoxShape3D.new()
	ash.size = Vector3(4.6, 2.6, 7.0)
	acs.shape = ash
	area.add_child(acs)
	area.position = Vector3(0, 1.3, -0.5)
	add_child(area)
	area.body_entered.connect(_on_body)
	floor_snap_length = 0.6


func seat() -> Vector3:
	return to_global(seat_offset)


func _on_body(b: Node) -> void:
	if rider or _board_cd > 0 or Game.ui_open or not b.is_in_group("player"):
		return
	rider = b
	add_collision_exception_with(rider)
	rider.ride(self)
	_exit_cd = 0.5
	if not _told:
		_told = true
		Game.show_toast("¡Al volante! Steer with the joystick. Jump to get out.")


func _physics_process(delta: float) -> void:
	_board_cd -= delta
	_exit_cd -= delta
	var input := Vector2.ZERO
	if rider and not Game.ui_open:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Game.touch_move.length() > 0.05:
			input = Game.touch_move
		if _exit_cd <= 0 and Input.is_action_just_pressed("jump"):
			_get_out()
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, rider.camera_yaw if rider else 0.0)
	if dir.length() > 1.0:
		dir = dir.normalized()
	var flat := Vector3(vel.x, 0, vel.z)
	if dir.length() > 0.05:
		# Turn the bus towards the steering direction, and drive forwards.
		var want := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, want, 1.0 - exp(-TURN * delta))
		var fwd := -global_transform.basis.z
		flat = flat.move_toward(fwd * SPEED * dir.length(), ACCEL * delta)
	else:
		flat = flat.move_toward(Vector3.ZERO, DRAG * delta)
	velocity = Vector3(flat.x, velocity.y - 25.0 * delta, flat.z)
	if is_on_floor() and velocity.y < 0:
		velocity.y = -0.5
	move_and_slide()
	vel = Vector3(velocity.x, 0, velocity.z)
	# Stay on the island.
	var p := Vector2(global_position.x, global_position.z)
	if p.length() > island_r:
		p = p.normalized() * island_r
		global_position.x = p.x
		global_position.z = p.y
		vel = Vector3.ZERO
		velocity = Vector3(0, velocity.y, 0)
	if passenger and is_instance_valid(passenger):
		passenger.global_position = to_global(Vector3(-0.5, 1.0, 0.8))
		passenger.rotation.y = rotation.y + PI


func _get_out() -> void:
	var who := rider
	rider = null
	remove_collision_exception_with(who)
	_board_cd = 1.5
	vel = Vector3.ZERO
	velocity = Vector3.ZERO
	who.unride(to_global(Vector3(2.4, 0.4, -1.5)))


func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	parent.add_child(mi)
