extends Node3D
## "La piñata": a stripy donkey piñata hanging from a frame. Jump and land on top of it three
## times to burst it - sweets rain down, and the real one appears.

const HANG_Y := 2.0          # bottom of the donkey
const HITS := 3

var sweet: Node3D
var hits := 0
var done := false

var _donkey: Node3D
var _cool := 0.0
var _swing := 0.0
var _t := 0.0


func setup() -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var wood := Props.mat(Color(0.6, 0.42, 0.28))
	for x in [-3.2, 3.2]:
		_solid(body, Vector3(0.35, 5.6, 0.35), Vector3(x, 2.8, 0), wood)
	_mesh(body, _box(Vector3(6.8, 0.3, 0.3)), Vector3(0, 5.6, 0), wood)
	_mesh(self, _box(Vector3(0.05, 5.6 - HANG_Y - 1.1, 0.05)), Vector3(0, (5.6 + HANG_Y + 1.1) / 2.0, 0), Props.mat(Color(0.9, 0.85, 0.7)))
	_donkey = Node3D.new()
	add_child(_donkey)
	_donkey.position = Vector3(0, HANG_Y, 0)
	var stripes := [Color(1, 0.35, 0.55), Color(1, 0.8, 0.2), Color(0.3, 0.75, 1.0), Color(0.45, 0.85, 0.45), Color(0.8, 0.45, 1.0)]
	for i in 5:
		_mesh(_donkey, _box(Vector3(0.36, 0.8, 0.8)), Vector3(-0.72 + i * 0.36, 0.55, 0), Props.mat(stripes[i]))
	_mesh(_donkey, _box(Vector3(0.5, 0.9, 0.6)), Vector3(1.0, 1.05, 0), Props.mat(stripes[0]))        # neck + head
	_mesh(_donkey, _box(Vector3(0.55, 0.4, 0.5)), Vector3(1.35, 1.35, 0), Props.mat(stripes[1]))
	for z in [-0.18, 0.18]:
		_mesh(_donkey, _box(Vector3(0.12, 0.4, 0.1)), Vector3(1.05, 1.7, z), Props.mat(stripes[2]))   # ears
	for x in [-0.6, 0.6]:
		for z in [-0.25, 0.25]:
			_mesh(_donkey, _box(Vector3(0.18, 0.4, 0.18)), Vector3(x, 0.0, z), Props.mat(stripes[3]))   # legs
	_mesh(_donkey, _box(Vector3(0.3, 0.12, 0.12)), Vector3(-1.0, 0.8, 0), Props.mat(stripes[4]))        # tail
	# Solid, so you can land on it.
	var dbody := StaticBody3D.new()
	_donkey.add_child(dbody)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.9, 0.8, 0.9)
	cs.shape = sh
	cs.position = Vector3(0, 0.55, 0)
	dbody.add_child(cs)
	var label := Label3D.new()
	label.text = "¡La piñata!"
	label.font = preload("res://scripts/ui.gd").ui_font(700)
	label.font_size = 90
	label.pixel_size = 0.006
	label.outline_size = 16
	label.modulate = Color(1, 0.8, 0.3)
	label.outline_modulate = Color(0.5, 0.15, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 6.6, 0)
	label.name = "Title"
	add_child(label)


func top() -> Vector3:
	return to_global(Vector3(0, HANG_Y + 0.95, 0))


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 1.0, 0))


func _physics_process(delta: float) -> void:
	_t += delta
	_cool -= delta
	_swing = move_toward(_swing, 0.0, delta * 0.4)
	if _donkey and is_instance_valid(_donkey):
		_donkey.rotation.z = sin(_t * 5.0) * _swing
		_donkey.rotation.y = sin(_t * 0.7) * 0.3
	if done or _cool > 0:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player:
		return
	var lp := to_local(player.global_position)
	var on_top := absf(lp.x) < 1.1 and absf(lp.z) < 0.7 and lp.y > HANG_Y + 0.8 and lp.y < HANG_Y + 1.6
	if on_top and player.velocity.y <= 0.5:
		_hit(player)


func _hit(player: CharacterBody3D) -> void:
	_cool = 0.5
	hits += 1
	_swing = 0.5
	player.bounce(10.0)
	Game.sfx("spring", 1.0 + hits * 0.15)
	_confetti(8)
	if hits < HITS:
		Game.show_toast("¡Dale! %d / %d" % [hits, HITS])
		return
	# ¡Boom!
	done = true
	Game.sfx("win", 1.2)
	Game.show_toast("¡La piñata se rompió! Sweets everywhere - grab the big one!")
	_confetti(40)
	var t := create_tween()
	t.tween_property(_donkey, "scale", Vector3.ONE * 1.3, 0.1)
	t.tween_property(_donkey, "scale", Vector3.ONE * 0.01, 0.15)
	t.tween_callback(_donkey.queue_free)
	# Little sweets rain down (just for fun).
	for i in 8:
		var s := Props.model(["food/candy-bar", "food/lollypop", "food/cookie", "food/donut-sprinkles"][i % 4])
		s.scale = Vector3.ONE * 2.2
		add_child(s)
		s.position = Vector3(0, HANG_Y + 0.5, 0)
		var a := TAU * i / 8.0
		var tt := create_tween()
		tt.tween_property(s, "position", Vector3(cos(a) * 2.2, 0.2, sin(a) * 2.2), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _confetti(n: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.lifetime = 1.4
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -6, 0)
	var q := BoxMesh.new()
	q.size = Vector3(0.12, 0.12, 0.02)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.35, 0.55), Color(1, 0.85, 0.2), Color(0.3, 0.75, 1.0)])
	p.color_initial_ramp = g
	add_child(p)
	p.position = Vector3(0, HANG_Y + 0.8, 0)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _solid(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	_mesh(parent, _box(size), pos, m)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	parent.add_child(cs)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material) -> MeshInstance3D:
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi
