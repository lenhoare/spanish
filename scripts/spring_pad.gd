extends Node3D
## A boingy spring. Land on it to launch high into the air.

@export var strength := 17.0

var _model: Node3D


func _ready() -> void:
	# Solid base so the player can stand on it.
	var body := Props.place(self, "spring", Vector3.ZERO, 0.0, 2.0, "cyl")
	_model = body.get_child(0)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 0.7
	s.height = 0.5
	cs.shape = s
	cs.position.y = 0.85
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.velocity.y > 2.0:
		return
	body.bounce(strength)
	Game.sfx("spring")
	_model.scale = Vector3(2.4, 1.2, 2.4)
	var t := create_tween()
	t.tween_property(_model, "scale", Vector3.ONE * 2.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
