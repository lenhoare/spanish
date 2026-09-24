extends Node3D
## A floating index card with a question on it. Walk into it to answer.
## When solved it flies off and becomes a piece of the bridge.

signal touched(card: Node3D)

var question: Dictionary
var solved := false
var index := 0

var _card: Node3D
var _t := randf() * TAU
var _cooldown := 0.0
var _ring: MeshInstance3D
var _beacon: MeshInstance3D


static func card_texture() -> Texture2D:
	var w := 256
	var h := 170
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.99, 0.95))
	for y in range(52, h, 22):
		img.fill_rect(Rect2i(0, y, w, 2), Color(0.55, 0.75, 0.95))
	img.fill_rect(Rect2i(0, 34, w, 3), Color(0.95, 0.4, 0.45))
	# rounded-ish border
	for x in w:
		for y in [0, 1, h - 2, h - 1]:
			img.set_pixel(x, y, Color(0.85, 0.82, 0.75))
	for y in h:
		for x in [0, 1, w - 2, w - 1]:
			img.set_pixel(x, y, Color(0.85, 0.82, 0.75))
	return ImageTexture.create_from_image(img)


func setup(q: Dictionary, i: int, tex: Texture2D) -> void:
	question = q
	index = i
	_card = Node3D.new()
	add_child(_card)
	_card.position.y = 1.4

	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 0.86)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = Color(1, 0.95, 0.8)
	m.emission_energy_multiplier = 0.25
	quad.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	_card.add_child(mi)

	for side in [1, -1]:
		var l := Label3D.new()
		l.text = "?"
		l.font_size = 160
		l.pixel_size = 0.004
		l.outline_size = 24
		l.modulate = Color(0.93, 0.3, 0.55)
		l.outline_modulate = Color(1, 1, 1)
		l.position = Vector3(0, -0.02, 0.01 * side)
		l.rotation.y = 0.0 if side == 1 else PI
		_card.add_child(l)

	var tag := Label3D.new()
	tag.text = "Question Card"
	tag.font_size = 48
	tag.pixel_size = 0.005
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(1, 1, 1)
	tag.outline_modulate = Color(0.35, 0.2, 0.55)
	tag.position.y = 2.35
	add_child(tag)

	# Glowing ring on the ground marks the spot.
	var torus := TorusMesh.new()
	torus.inner_radius = 0.75
	torus.outer_radius = 0.95
	torus.rings = 24
	torus.ring_segments = 8
	torus.material = Props.unshaded(Color(1.0, 0.85, 0.3, 0.8))
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position.y = 0.05
	_ring.scale.y = 0.2
	add_child(_ring)
	# Tall light beam so cards can be spotted from across the island.
	_beacon = Props.beacon(self, Color(1.0, 0.85, 0.3))

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.0
	s.height = 2.5
	cs.shape = s
	cs.position.y = 1.2
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if not solved:
		_card.rotation.y += delta * 1.2
		_card.position.y = 1.4 + sin(_t * 2.0) * 0.15
		_ring.rotation.y -= delta
		var p := 1.0 + sin(_t * 4.0) * 0.06
		_ring.scale = Vector3(p, 0.2, p)


func _on_body(body: Node) -> void:
	if solved or Game.ui_open or _cooldown > 0 or not body.is_in_group("player"):
		return
	touched.emit(self)


func set_locked(on: bool) -> void:
	for c in get_children():
		if c is Label3D:
			c.text = "Locked - Read the Whiteboard!" if on else "Question Card"
			c.modulate = Color(1, 0.75, 0.7) if on else Color.WHITE
	_ring.material_override = Props.unshaded(Color(0.6, 0.6, 0.7, 0.6)) if on else null


## Called after a wrong answer so the panel doesn't instantly reopen.
func rest() -> void:
	_cooldown = 1.5
	var t := create_tween()
	t.tween_property(_card, "rotation:z", 0.4, 0.08)
	t.tween_property(_card, "rotation:z", -0.4, 0.12)
	t.tween_property(_card, "rotation:z", 0.0, 0.08)


## Card flies to `target` (global position) and disappears.
func fly_to(target: Vector3) -> void:
	solved = true
	_ring.visible = false
	_beacon.visible = false
	for c in get_children():
		if c is Label3D:
			c.visible = false
	var start := _card.global_position
	var top := (start + target) * 0.5 + Vector3(0, 8, 0)
	var t := create_tween()
	t.tween_property(_card, "scale", Vector3.ONE * 1.6, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_method(func(k: float):
		var a := start.lerp(top, k)
		var b := top.lerp(target, k)
		_card.global_position = a.lerp(b, k)
		_card.rotation.y += 0.3
	, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_card, "scale", Vector3.ONE * 0.01, 0.15)
	t.tween_callback(queue_free)
