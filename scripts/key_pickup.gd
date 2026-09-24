extends Area3D
## A golden key hidden somewhere on the island. Opens the sweet shop door.

var _model: Node3D
var _beacon: MeshInstance3D
var _t := 0.0
var _taken := false


func _ready() -> void:
	_model = Props.model("key")
	_model.scale = Vector3.ONE * 4.0
	_model.position.y = 1.0
	add_child(_model)
	_beacon = Props.beacon(self, Color(0.4, 0.95, 1.0))
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 1.0
	cs.shape = s
	cs.position.y = 1.2
	add_child(cs)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	if not _taken:
		_model.rotation.y += delta * 2.0
		_model.position.y = 1.0 + sin(_t * 2.5) * 0.2


func _on_body(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	_beacon.visible = false
	Game.has_key = true
	Game.key_changed.emit()
	Game.sfx("build", 1.2)
	Game.show_toast("You found a key! I wonder what it opens...")
	var t := create_tween().set_parallel()
	t.tween_property(_model, "position:y", 3.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.4).set_delay(0.3)
	t.chain().tween_callback(queue_free)
