extends CharacterBody3D
## Bouncy third-person player: run, jump, double jump, squash & stretch.

const SPEED := 6.5
const ACCEL := 40.0
const AIR_ACCEL := 18.0
const JUMP_VELOCITY := 9.5
const DOUBLE_JUMP_VELOCITY := 8.5
const GRAVITY := 25.0
const FALL_GRAVITY := 34.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
const MODEL_SCALE := 1.6

var camera_yaw := 0.0      # set by the camera rig every frame
var respawn_point := Vector3.ZERO

var _model: Node3D
var _pivot: Node3D         # squash/stretch applies here
var _anim: AnimationPlayer
var _coyote := 0.0
var _buffer := 0.0
var _can_double := false
var _was_on_floor := true
var _safe_timer := 0.0
var _last_safe := Vector3.ZERO
var _shadow: Sprite3D
var _ray: RayCast3D
var _dust: CPUParticles3D
var _squash_tween: Tween
var _frozen_anim := ""
var _spring_rise := false  # springs give full height even if jump isn't held
var _dazed := 0.0          # after being knocked back, controls ignored briefly


func setup(character_name: String, spawn: Vector3, display_name := "") -> void:
	respawn_point = spawn
	_last_safe = spawn
	position = spawn

	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.25
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = 0.625
	add_child(cs)
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50)

	_pivot = Node3D.new()
	add_child(_pivot)
	_model = Props.character(character_name)
	_model.scale = Vector3.ONE * MODEL_SCALE
	_pivot.add_child(_model)
	_anim = _model.find_children("*", "AnimationPlayer", true, false)[0] if _model.find_children("*", "AnimationPlayer", true, false).size() > 0 else null
	if _anim:
		for a in ["idle", "walk", "sprint", "fall"]:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		_play("idle")

	if display_name != "":
		var tag := Label3D.new()
		tag.text = display_name
		tag.font_size = 44
		tag.pixel_size = 0.005
		tag.outline_size = 12
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.modulate = Color(1, 1, 1, 0.95)
		tag.outline_modulate = Color(0.3, 0.2, 0.5, 0.9)
		tag.position.y = 1.75
		add_child(tag)

	# Blob shadow: makes jumps much easier to judge.
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, -30, 0)
	_ray.position.y = 0.3
	_ray.add_exception(self)
	add_child(_ray)
	_shadow = Sprite3D.new()
	_shadow.texture = Props.blob_texture()
	_shadow.pixel_size = 0.016
	_shadow.axis = Vector3.AXIS_Y
	_shadow.top_level = true
	_shadow.shaded = false
	_shadow.transparent = true
	_shadow.no_depth_test = false
	add_child(_shadow)

	_dust = CPUParticles3D.new()
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 12
	_dust.lifetime = 0.5
	_dust.explosiveness = 0.95
	_dust.direction = Vector3(0, 1, 0)
	_dust.spread = 90
	_dust.initial_velocity_min = 1.5
	_dust.initial_velocity_max = 3.0
	_dust.gravity = Vector3(0, -2, 0)
	_dust.scale_amount_min = 0.6
	_dust.scale_amount_max = 1.2
	var puff := SphereMesh.new()
	puff.radius = 0.09
	puff.height = 0.18
	puff.radial_segments = 8
	puff.rings = 4
	puff.material = Props.unshaded(Color(1, 1, 1, 0.9))
	_dust.mesh = puff
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	_dust.scale_amount_curve = curve
	add_child(_dust)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	_dazed -= delta
	if not Game.ui_open and _dazed <= 0:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Game.touch_move.length() > 0.05:
			input = Game.touch_move
		if Input.is_action_just_pressed("jump"):
			_buffer = JUMP_BUFFER
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw)
	if dir.length() > 1.0:
		dir = dir.normalized()

	var on_floor := is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
		_can_double = true
	else:
		_coyote -= delta
	_buffer -= delta

	# Gravity: heavier when falling, and a lighter arc while the jump button is held.
	var g := GRAVITY
	if velocity.y < 0:
		g = FALL_GRAVITY
		_spring_rise = false
	elif not Input.is_action_pressed("jump") and not _spring_rise:
		g = FALL_GRAVITY * 1.4
	velocity.y -= g * delta
	velocity.y = maxf(velocity.y, -30.0)

	if _buffer > 0:
		if _coyote > 0:
			_jump(JUMP_VELOCITY)
		elif _can_double:
			_can_double = false
			_jump(DOUBLE_JUMP_VELOCITY)
			_flip()

	var target := dir * SPEED
	var a := ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target.x, a * delta)
	velocity.z = move_toward(velocity.z, target.z, a * delta)

	move_and_slide()

	# Face the direction of travel.
	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.3:
		var want := atan2(velocity.x, velocity.z)
		_pivot.rotation.y = lerp_angle(_pivot.rotation.y, want, 1.0 - exp(-14.0 * delta))

	if is_on_floor() and not _was_on_floor:
		_land()
	_was_on_floor = is_on_floor()

	_update_safe_point(delta)
	_update_anim(flat.length())
	_update_shadow()

	if global_position.y < -6.0:
		_respawn()


func bounce(strength: float) -> void:
	velocity.y = strength
	_spring_rise = true
	_can_double = true
	_coyote = 0
	_squash(Vector3(0.75, 1.35, 0.75))
	_play("jump")


## Pushed away by an enemy.
func knockback(v: Vector3) -> void:
	velocity = v
	_dazed = 0.45
	_spring_rise = true
	_coyote = 0
	_squash(Vector3(1.3, 0.7, 1.3))
	_play("fall")
	# Quick blink so it's clear what happened.
	var t := create_tween()
	for i in 3:
		t.tween_callback(func(): _model.visible = false).set_delay(0.06)
		t.tween_callback(func(): _model.visible = true).set_delay(0.06)


## Teleports the player (e.g. back to the start of a challenge) with a little poof.
func send_to(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_last_safe = pos
	_squash(Vector3(0.6, 1.4, 0.6))
	_dust.restart()


func celebrate() -> void:
	_frozen_anim = "emote-yes"
	_play("emote-yes")
	await get_tree().create_timer(1.6).timeout
	_frozen_anim = ""


func sad() -> void:
	_frozen_anim = "emote-no"
	_play("emote-no")
	await get_tree().create_timer(1.2).timeout
	_frozen_anim = ""


func _jump(v: float) -> void:
	velocity.y = v
	_buffer = 0
	_coyote = 0
	Game.sfx("jump", randf_range(0.95, 1.1), -4.0)
	_squash(Vector3(0.8, 1.25, 0.8))
	_play("jump")


func _flip() -> void:
	var t := create_tween()
	_model.rotation.x = 0
	t.tween_property(_model, "rotation:x", TAU, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _model.rotation.x = 0)


func _land() -> void:
	_squash(Vector3(1.3, 0.7, 1.3))
	_dust.restart()


func _squash(s: Vector3) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_pivot.scale = s
	_squash_tween = create_tween()
	_squash_tween.tween_property(_pivot, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _update_anim(speed: float) -> void:
	if _frozen_anim != "":
		return
	if not is_on_floor():
		_play("jump" if velocity.y > 0 else "fall")
	elif speed > 4.5:
		_play("sprint")
	elif speed > 0.4:
		_play("walk")
	else:
		_play("idle")


func _play(name: String) -> void:
	if _anim and _anim.has_animation(name) and _anim.current_animation != name:
		_anim.play(name, 0.12)


func _update_shadow() -> void:
	_ray.force_raycast_update()
	if _ray.is_colliding():
		_shadow.visible = true
		var p := _ray.get_collision_point()
		_shadow.global_position = p + Vector3(0, 0.03, 0)
		var h := global_position.y - p.y
		var s := clampf(1.0 - h * 0.06, 0.4, 1.0)
		_shadow.scale = Vector3.ONE * s
	else:
		_shadow.visible = false


func _update_safe_point(delta: float) -> void:
	if not is_on_floor():
		_safe_timer = 0
		return
	var col := get_last_slide_collision()
	var ok := col != null and col.get_collider() is Node and (col.get_collider() as Node).is_in_group("solid_ground")
	if ok:
		_safe_timer += delta
		if _safe_timer > 0.25:
			_last_safe = global_position
	else:
		_safe_timer = 0


func _respawn() -> void:
	global_position = _last_safe + Vector3(0, 0.5, 0)
	velocity = Vector3.ZERO
	Game.sfx("wrong", 1.3, -6.0)
	_squash(Vector3(0.6, 1.4, 0.6))
