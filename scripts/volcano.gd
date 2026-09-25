extends Node3D
## "El volcán": a stepped volcano with a glowing crater. A ring of lava round its foot pushes
## you back - until you've done enough retos to cool it ("cool_at"). Each reto you finish
## calms the volcano a little: less glow, less smoke. Climb the terraces to the crater's
## rim for the sweet.

const TIERS := 6
const TIER_H := 1.45         # a single jump (1.8 m) gets you up each step
const BASE_R := 10.0
const TOP_R := 3.6
const MOAT_W := 2.4

var sweet: Node3D
var cool_at := 3
var cooled := false

var _lava_mat: StandardMaterial3D
var _moat_mat: StandardMaterial3D
var _smoke: CPUParticles3D
var _stream_mat: StandardMaterial3D
var _puffs: Array = []
var _cool := 0.0


func top_y() -> float:
	return TIERS * TIER_H


func setup(need: int) -> void:
	cool_at = need
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var rock := Props.mat(Color(0.33, 0.28, 0.3))
	var rock2 := Props.mat(Color(0.42, 0.34, 0.33))
	_moat_mat = StandardMaterial3D.new()
	for i in TIERS:
		var r := lerpf(BASE_R, TOP_R + 1.2, float(i) / (TIERS - 1))
		var c := CylinderMesh.new()
		c.top_radius = r * 0.97
		c.bottom_radius = r
		c.height = TIER_H
		c.radial_segments = 14
		# The bottom tier is lava too (sides and all) until the volcano cools.
		_mesh(body, c, Vector3(0, TIER_H * (i + 0.5), 0), _moat_mat if i == 0 else (rock if i % 2 == 0 else rock2))
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r
		sh.height = TIER_H
		cs.shape = sh
		cs.position.y = TIER_H * (i + 0.5)
		body.add_child(cs)
	# The crater: a rim with a lava pool inside (the rim is walkable, the pool isn't).
	_lava_mat = StandardMaterial3D.new()
	_lava_mat.albedo_color = Color(0.85, 0.18, 0.08)
	_lava_mat.emission_enabled = true
	_lava_mat.emission = Color(0.75, 0.12, 0.04)
	_lava_mat.emission_energy_multiplier = 1.0
	var pool := CylinderMesh.new()
	pool.top_radius = TOP_R - 1.4
	pool.bottom_radius = TOP_R - 1.4
	pool.height = 0.1
	_mesh(self, pool, Vector3(0, top_y() + 0.05, 0), _lava_mat)
	var rim := TorusMesh.new()
	rim.inner_radius = TOP_R - 1.4
	rim.outer_radius = TOP_R + 0.2
	rim.rings = 24
	var rim_mi := _mesh(body, rim, Vector3(0, top_y() + 0.25, 0), rock2)
	var rcs := CollisionShape3D.new()
	rcs.shape = rim.create_trimesh_shape()
	rcs.position = rim_mi.position
	body.add_child(rcs)
	# A stream of lava that has run down from the vent, over each terrace, into the moat.
	_stream_mat = StandardMaterial3D.new()
	_stream_mat.albedo_color = Color(0.85, 0.18, 0.08)
	_stream_mat.emission_enabled = true
	_stream_mat.emission = Color(0.75, 0.12, 0.04)
	_stream_mat.emission_energy_multiplier = 1.0
	var sdir := Vector3(0, 0, -1)
	for i in range(TIERS - 1, -1, -1):
		var r := lerpf(BASE_R, TOP_R + 1.2, float(i) / (TIERS - 1))
		var r_in := TOP_R - 1.2 if i == TIERS - 1 else lerpf(BASE_R, TOP_R + 1.2, float(i + 1) / (TIERS - 1))
		var y_top := TIER_H * (i + 1)
		var flat := _mesh(self, _box(Vector3(0.9, 0.06, r - r_in + 0.1)), sdir * ((r + r_in) / 2.0) + Vector3(0, y_top + 0.03, 0), _stream_mat)
		flat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var fall := _mesh(self, _box(Vector3(0.9, TIER_H + 0.06, 0.08)), sdir * (r + 0.02) + Vector3(0, y_top - TIER_H / 2.0, 0), _stream_mat)
		fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Little grey smoke puffs rising off the lava (the moat and the crater).
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		_puffs.append(_puff(Vector3(cos(a), 0.1, sin(a)) * (BASE_R + MOAT_W * 0.5)))
	_puffs.append(_puff(Vector3(0, top_y() + 0.2, 0)))
	_puffs.append(_puff(sdir * (BASE_R - 1.0) + Vector3(0, TIER_H + 0.1, 0)))
	# The lava pool itself is hot: a ring you can stand on around it, a push-off in the middle.
	var hot := Area3D.new()
	var hcs := CollisionShape3D.new()
	var hsh := CylinderShape3D.new()
	hsh.radius = TOP_R - 1.5
	hsh.height = 1.5
	hcs.shape = hsh
	hot.add_child(hcs)
	hot.position.y = top_y() + 0.6
	add_child(hot)
	hot.body_entered.connect(_on_pool)
	# Smoke.
	_smoke = CPUParticles3D.new()
	_smoke.amount = 40
	_smoke.lifetime = 4.0
	_smoke.direction = Vector3.UP
	_smoke.spread = 12.0
	_smoke.initial_velocity_min = 2.0
	_smoke.initial_velocity_max = 3.5
	_smoke.gravity = Vector3(0.6, 0.3, 0)
	_smoke.scale_amount_min = 1.5
	_smoke.scale_amount_max = 3.0
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	sm.radial_segments = 8
	sm.rings = 4
	sm.material = Props.unshaded(Color(0.5, 0.48, 0.5, 0.45))
	_smoke.mesh = sm
	_smoke.position.y = top_y() + 0.5
	add_child(_smoke)
	# The lava moat round the foot.
	_moat_mat.albedo_color = Color(0.85, 0.18, 0.08)
	_moat_mat.emission_enabled = true
	_moat_mat.emission = Color(0.75, 0.12, 0.04)
	_moat_mat.emission_energy_multiplier = 1.0
	var moat := TorusMesh.new()
	moat.inner_radius = BASE_R
	moat.outer_radius = BASE_R + MOAT_W
	moat.rings = 40
	var mi := _mesh(self, moat, Vector3(0, 0.02, 0), _moat_mat)
	mi.scale.y = 0.05
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = "El volcán"
	label.font = preload("res://scripts/ui.gd").ui_font(700)
	label.font_size = 140
	label.pixel_size = 0.008
	label.outline_size = 20
	label.modulate = Color(1, 0.55, 0.25)
	label.outline_modulate = Color(0.25, 0.1, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = top_y() + 5.0
	add_child(label)


func sweet_spot() -> Vector3:
	return to_global(Vector3(TOP_R - 0.7, top_y() + 0.9, 0))


func rim_spot() -> Vector3:
	return to_global(Vector3(-(TOP_R - 0.6), top_y() + 0.6, 0))


func _physics_process(delta: float) -> void:
	_cool -= delta
	# The more retos done, the calmer the volcano.
	var k := 0.0
	if Game.total_retos > 0:
		k = clampf(float(Game.retos_done) / Game.total_retos, 0.0, 1.0)
	_lava_mat.emission_energy_multiplier = lerpf(1.1, 0.35, k)
	_smoke.amount = maxi(4, int(40 * (1.0 - k)))
	if not cooled and Game.retos_done >= cool_at:
		cooled = true
		var t := create_tween()
		t.tween_property(_moat_mat, "emission_energy_multiplier", 0.0, 2.0)
		t.parallel().tween_property(_moat_mat, "albedo_color", Color(0.3, 0.25, 0.26), 2.0)
		t.parallel().tween_property(_stream_mat, "emission_energy_multiplier", 0.0, 2.0)
		t.parallel().tween_property(_stream_mat, "albedo_color", Color(0.3, 0.25, 0.26), 2.0)
		for pf in _puffs:
			(pf as CPUParticles3D).emitting = false
		Game.sfx("win", 0.8)
		Game.show_toast("¡El volcán se enfría! The lava at its foot has cooled - you can climb it now!")
	if cooled:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player or _cool > 0:
		return
	var lp := to_local(player.global_position)
	var d := Vector2(lp.x, lp.z).length()
	if d < BASE_R + MOAT_W + 0.3 and lp.y < top_y() + 2.0:
		_cool = 1.2
		Game.sfx("wrong", 0.8)
		Game.show_toast("¡Qué calor! The lava is too hot. Complete %d retos to cool the volcano (%d / %d)." % [cool_at, mini(Game.retos_done, cool_at), cool_at])
		var out := global_transform.basis * Vector3(lp.x, 0, lp.z).normalized()
		player.knockback(out * 9.0 + Vector3(0, 7.0, 0))


func _on_pool(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var p := body as CharacterBody3D
	var lp := to_local(p.global_position)
	var out := global_transform.basis * Vector3(lp.x + 0.01, 0, lp.z).normalized()
	Game.sfx("wrong", 0.8)
	Game.show_toast("¡Cuidado! ¡Lava!")
	p.knockback(out * 5.0 + Vector3(0, 8.0, 0))


func _puff(pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 5
	p.lifetime = 2.2
	p.randomness = 0.6
	p.direction = Vector3.UP
	p.spread = 20.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, 0.4, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.5
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.6
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = Props.unshaded(Color(0.62, 0.6, 0.62, 0.55))
	p.mesh = sm
	p.position = pos
	add_child(p)
	return p


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
