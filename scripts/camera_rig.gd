extends Node3D
## Third-person orbit camera. Drag (mouse or finger on the right side of the screen)
## or Q/E to rotate. Gently swings behind the player while they run.

var target: Node3D
var yaw := 0.0
var pitch := deg_to_rad(-22.0)
var distance := 6.5

var _arm: SpringArm3D
var camera: Camera3D
var _dragging := false
var _drag_index := -1
var _zoomed := false     # the player used the mouse wheel; respect their zoom


func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.margin = 0.3
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	_arm.shape = shape
	add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 60
	camera.far = 400
	_arm.add_child(camera)
	camera.current = true


func set_target(t: CollisionObject3D) -> void:
	target = t
	_arm.add_excluded_object(t.get_rid())
	global_position = t.global_position + Vector3(0, 1.1, 0)


func _process(delta: float) -> void:
	if not target:
		return
	var want := target.global_position + Vector3(0, 1.1, 0)
	global_position = global_position.lerp(want, 1.0 - exp(-10.0 * delta))

	if not Game.ui_open:
		var turn := Input.get_axis("cam_left", "cam_right")
		yaw -= turn * 2.2 * delta
		# Lazy auto-follow: slowly rotate behind the player when they run sideways.
		var v: Vector3 = target.velocity if "velocity" in target else Vector3.ZERO
		var flat := Vector2(v.x, v.z)
		if flat.length() > 3.0 and not _dragging:
			var move_yaw := atan2(-v.x, -v.z)
			var diff := wrapf(move_yaw - yaw, -PI, PI)
			if absf(diff) < PI * 0.75:
				yaw += diff * 0.6 * delta
	# In a boat: pull back and look down a bit more, so the boat doesn't fill the screen.
	var in_boat: bool = "vehicle" in target and target.vehicle != null
	var want_len := distance * (1.7 if in_boat else 1.0)
	if not _zoomed:
		_arm.spring_length = lerpf(_arm.spring_length, want_len, 1.0 - exp(-3.0 * delta))
	var want_pitch := deg_to_rad(-30.0) if in_boat else pitch
	rotation = Vector3(lerp_angle(rotation.x, want_pitch, 1.0 - exp(-4.0 * delta)) if in_boat or absf(rotation.x - pitch) > 0.01 else pitch, yaw, 0)
	if "camera_yaw" in target:
		target.camera_yaw = yaw


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open:
		_dragging = false
		return
	if Game.is_touch():
		# Touch: any finger not already used by the joystick / jump button steers the camera.
		if event is InputEventScreenTouch:
			if event.pressed and _drag_index == -1:
				_drag_index = event.index
				_dragging = true
			elif not event.pressed and event.index == _drag_index:
				_drag_index = -1
				_dragging = false
		elif event is InputEventScreenDrag and event.index == _drag_index:
			_rotate_by(event.relative * 0.008)
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoomed = true
			_arm.spring_length = clampf(_arm.spring_length - 0.5, 4.0, 12.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoomed = true
			_arm.spring_length = clampf(_arm.spring_length + 0.5, 4.0, 12.0)
	elif event is InputEventMouseMotion and _dragging:
		_rotate_by(event.relative * 0.006)


func _rotate_by(rel: Vector2) -> void:
	yaw -= rel.x
	pitch = clampf(pitch - rel.y, deg_to_rad(-60), deg_to_rad(5))

