extends Node3D
## A sweet: a bonus "extension" challenge. It sits somewhere hard to reach and asks
## a harder question. Sweets don't open the bridge - they're for kudos.

signal touched(sweet: Node3D)

var question: Dictionary
var collected := false

var _model: Node3D
var _beacon: MeshInstance3D
var _t := 0.0
var _cooldown := 0.0
var _tag: Label3D
var _thief: Node3D          # the ghost, while it's carrying this sweet away
var stolen_left := 0.0
var gate := Callable()      # optional: the sweet can only be taken when this returns true


func setup(q: Dictionary, model_name: String, scale := 5.0) -> void:
	question = q
	_model = Props.model(model_name)
	_model.scale = Vector3.ONE * scale
	add_child(_model)
	_beacon = Props.beacon(self, Color(1.0, 0.45, 0.8))

	# Sparkles so it looks precious.
	var sp := CPUParticles3D.new()
	sp.amount = 16
	sp.lifetime = 1.4
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.8
	sp.gravity = Vector3(0, 0.5, 0)
	sp.initial_velocity_min = 0.1
	sp.initial_velocity_max = 0.3
	var m := SphereMesh.new()
	m.radius = 0.04
	m.height = 0.08
	m.radial_segments = 6
	m.rings = 3
	m.material = Props.unshaded(Color(1, 0.8, 0.95))
	sp.mesh = m
	sp.position.y = 1.0
	add_child(sp)

	_tag = Label3D.new()
	_tag.text = "Sweet Challenge"
	_tag.font_size = 48
	_tag.pixel_size = 0.005
	_tag.outline_size = 14
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.modulate = Color(1, 0.85, 0.95)
	_tag.outline_modulate = Color(0.55, 0.15, 0.4)
	_tag.position.y = 2.3
	add_child(_tag)

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.0
	s.height = 2.4
	cs.shape = s
	cs.position.y = 1.0
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if collected:
		return
	_model.rotation.y += delta * 1.5
	if is_stolen():
		# Bob along above the ghost's head until it gives it back.
		_model.global_position = _thief.global_position + Vector3(0, 2.9 + sin(_t * 3.0) * 0.1, 0)
		stolen_left -= delta
		if stolen_left <= 0:
			give_back()
			Game.show_toast("The ghost got bored and put the lollipop back!")
	else:
		_model.position.y = 0.6 + sin(_t * 2.2) * 0.15


func _on_body(body: Node) -> void:
	if collected or is_stolen() or Game.ui_open or _cooldown > 0 or not body.is_in_group("player"):
		return
	if gate.is_valid() and not gate.call():
		return
	touched.emit(self)


func is_stolen() -> bool:
	return _thief != null and is_instance_valid(_thief)


## An enemy grabs the sweet and carries it off for `secs` seconds.
func steal(by: Node3D, secs: float) -> void:
	_thief = by
	stolen_left = secs
	_tag.visible = false
	_beacon.visible = false


func give_back() -> void:
	_thief = null
	_tag.visible = true
	_beacon.visible = bool(Game.config.get("beacons", true))
	var t := create_tween()
	t.tween_property(_model, "position", Vector3(0, 0.6, 0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_locked(on: bool) -> void:
	_tag.text = "Locked - Read the Whiteboard!" if on else "Sweet Challenge"


func rest() -> void:
	_cooldown = 1.5


## Sweet flies into the player's pocket.
func collect(player: Node3D) -> void:
	collected = true
	_beacon.visible = false
	_tag.visible = false
	var start := _model.global_position
	var t := create_tween()
	t.tween_property(_model, "scale", _model.scale * 1.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(func(k: float):
		if is_instance_valid(player):
			_model.global_position = start.lerp(player.global_position + Vector3(0, 1.0, 0), k) + Vector3(0, sin(k * PI) * 2.0, 0)
		_model.rotation.y += 0.4
	, 0.0, 1.0, 0.7)
	t.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.15)
	t.tween_callback(queue_free)
