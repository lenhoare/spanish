extends Area3D
## A spinning, bobbing star. Touch it to collect.

var _model: Node3D
var _t := randf() * TAU
var _base_y := 0.0
var _taken := false


func _ready() -> void:
	_base_y = position.y
	_model = Props.model("star")
	_model.scale = Vector3.ONE * 1.6
	add_child(_model)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.55
	cs.shape = s
	cs.position.y = 0.3
	add_child(cs)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_model.rotation.y += delta * 2.5
	if not _taken:
		position.y = _base_y + sin(_t * 2.5) * 0.12


func _on_body(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	Game.add_star()
	var t := create_tween().set_parallel()
	t.tween_property(self, "position:y", position.y + 1.2, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.35).set_delay(0.1)
	t.chain().tween_callback(queue_free)
