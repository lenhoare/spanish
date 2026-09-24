extends Control
## On-screen controls for phones: a floating joystick (left half) and a jump button.
## Uses raw multi-touch so you can run and jump at the same time.

const JOY_RADIUS := 90.0
const JUMP_RADIUS := 78.0

var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _jump_index := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()


func _jump_center() -> Vector2:
	return Vector2(size.x - 130, size.y - 130)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if Game.ui_open:
		_release_all()
		return
	var pos: Vector2
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		pos = make_input_local(event).position
	if event is InputEventScreenTouch:
		if event.pressed:
			if _jump_index == -1 and pos.distance_to(_jump_center()) < JUMP_RADIUS + 30:
				_jump_index = event.index
				Input.action_press("jump")
				get_viewport().set_input_as_handled()
			elif _joy_index == -1 and pos.x < size.x * 0.45 and pos.y > 120:
				_joy_index = event.index
				_joy_center = pos
				_joy_pos = pos
				get_viewport().set_input_as_handled()
		else:
			if event.index == _jump_index:
				_jump_index = -1
				Input.action_release("jump")
			elif event.index == _joy_index:
				_joy_index = -1
				Game.touch_move = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _joy_index:
		var d: Vector2 = pos - _joy_center
		if d.length() > JOY_RADIUS:
			# Let the joystick base follow the thumb a little.
			_joy_center += d - d.normalized() * JOY_RADIUS
			d = d.normalized() * JOY_RADIUS
		_joy_pos = _joy_center + d
		Game.touch_move = d / JOY_RADIUS
		get_viewport().set_input_as_handled()
		queue_redraw()


func _release_all() -> void:
	if _jump_index != -1:
		Input.action_release("jump")
	_jump_index = -1
	_joy_index = -1
	Game.touch_move = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if Game.ui_open:
		return
	# Joystick
	var c := _joy_center if _joy_index != -1 else Vector2(170, size.y - 150)
	var k := _joy_pos if _joy_index != -1 else c
	draw_circle(c, JOY_RADIUS, Color(1, 1, 1, 0.22))
	draw_arc(c, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.6), 4, true)
	draw_circle(k, 42, Color(1, 1, 1, 0.75))
	draw_arc(k, 42, 0, TAU, 32, Color(0.55, 0.45, 0.9, 0.9), 4, true)
	# Jump button
	var j := _jump_center()
	var pressed := _jump_index != -1
	draw_circle(j + Vector2(0, 6), JUMP_RADIUS, Color(0.3, 0.2, 0.5, 0.35))
	draw_circle(j + (Vector2(0, 4) if pressed else Vector2.ZERO), JUMP_RADIUS, Color(1.0, 0.55, 0.72, 0.85 if not pressed else 1.0))
	draw_arc(j, JUMP_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.9), 5, true)
	var font := get_theme_default_font()
	var s := "JUMP"
	var fs := 30
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, j + Vector2(-w / 2, 11), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
