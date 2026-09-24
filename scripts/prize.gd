extends Node3D
## The Golden Star prize at the end of the level.

signal claimed

var _star: Node3D
var _t := 0.0
var _done := false


func setup(prize_name: String) -> void:
	# Pedestal
	var ped := CylinderMesh.new()
	ped.top_radius = 1.1
	ped.bottom_radius = 1.4
	ped.height = 1.0
	ped.material = Props.mat(Color(0.98, 0.72, 0.85))
	var pmi := MeshInstance3D.new()
	pmi.mesh = ped
	pmi.position.y = 0.5
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.3
	shape.height = 1.0
	cs.shape = shape
	cs.position.y = 0.5
	body.add_child(cs)
	body.add_child(pmi)
	add_child(body)

	_star = Props.model("star")
	_star.scale = Vector3.ONE * 5.0
	_star.position.y = 1.4
	add_child(_star)

	var label := Label3D.new()
	label.text = prize_name
	label.font_size = 64
	label.pixel_size = 0.006
	label.outline_size = 18
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 0.9, 0.3)
	label.outline_modulate = Color(0.5, 0.25, 0.05)
	label.position.y = 4.2
	add_child(label)

	var sparkle := CPUParticles3D.new()
	sparkle.amount = 24
	sparkle.lifetime = 1.6
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 1.4
	sparkle.gravity = Vector3(0, 0.6, 0)
	sparkle.initial_velocity_min = 0.1
	sparkle.initial_velocity_max = 0.4
	var m := SphereMesh.new()
	m.radius = 0.05
	m.height = 0.1
	m.radial_segments = 6
	m.rings = 3
	m.material = Props.unshaded(Color(1, 0.95, 0.5))
	sparkle.mesh = m
	sparkle.position.y = 2.3
	add_child(sparkle)

	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 2.5
	acs.shape = s
	acs.position.y = 1.2
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	if not _done:
		_star.rotation.y += delta * 1.5
		_star.position.y = 1.4 + sin(_t * 2.0) * 0.2


func _on_body(body: Node) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	var t := create_tween()
	t.tween_property(_star, "position:y", 6.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_star, "rotation:y", _star.rotation.y + TAU * 3, 1.2)
	claimed.emit()
