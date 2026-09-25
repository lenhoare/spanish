extends Node3D
## "La Tomatina": a festival street with houses on both sides. People on the balconies lob
## tomatoes at you - a red ring shows where each one will land. Get hit and you're knocked
## back towards the start. Reach the plaza at the far end for the sweet.
## The street runs along local -Z from the entrance (z=0); the only way in is the entrance.

const LENGTH := 26.0
const HALF_W := 2.8          # half the street width
const HOUSE_D := 3.0         # depth of the houses on each side
const FLIGHT := 1.1          # seconds a tomato is in the air
const HIT_R := 1.05

var sweet: Node3D
var hits := 0

var _throwers: Array[Vector3] = []
var _tomatoes: Array = []    # [{node, from, to, t, marker}]
var _splats: Array = []      # [{node, t}]
var _next := 1.0
var _cool := 0.0
var _rng := RandomNumberGenerator.new()


func setup() -> void:
	_rng.seed = 777
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	_flat(Vector3(HALF_W * 2, 0.04, LENGTH + 8.0), Vector3(0, 0.02, -(LENGTH + 8.0) / 2.0 + 1.0), Props.mat(Color(0.85, 0.72, 0.55)))
	# Houses along both sides, all solid and taller than a double jump, with balconies.
	var cols := [Color(1.0, 0.75, 0.55), Color(0.98, 0.9, 0.6), Color(0.95, 0.6, 0.55), Color(1.0, 0.85, 0.75), Color(0.85, 0.7, 0.9)]
	for side in [-1.0, 1.0]:
		var z := 0.0
		var k := 0
		while z > -(LENGTH + 6.0):
			var w := 4.4
			var c: Color = cols[(k + (1 if side > 0 else 0)) % cols.size()]
			var x: float = side * (HALF_W + HOUSE_D / 2.0)
			_solid(body, Vector3(HOUSE_D, 4.6, w), Vector3(x, 2.3, z - w / 2.0), Props.mat(c))
			_solid(body, Vector3(HOUSE_D + 0.3, 0.3, w + 0.2), Vector3(x, 4.75, z - w / 2.0), Props.mat(c.darkened(0.4)))
			var inner: float = side * HALF_W
			# A door, windows, and a balcony facing the street.
			_mesh(body, _box(Vector3(0.05, 1.8, 1.0)), Vector3(inner - side * 0.02, 0.9, z - w / 2.0 - 0.9), Props.mat(Color(0.5, 0.32, 0.22)))
			_mesh(body, _box(Vector3(0.05, 0.8, 0.8)), Vector3(inner - side * 0.02, 1.5, z - w / 2.0 + 1.0), Props.mat(Color(0.75, 0.9, 1.0)))
			if k % 2 == 0 and z < -2.0 and z > -(LENGTH - 2.0):
				var bz := z - w / 2.0
				_mesh(body, _box(Vector3(1.0, 0.15, 1.8)), Vector3(inner - side * 0.5, 3.0, bz), Props.mat(Color(0.4, 0.3, 0.3)))
				_mesh(body, _box(Vector3(0.08, 0.6, 1.8)), Vector3(inner - side * 0.95, 3.35, bz), Props.mat(Color(0.3, 0.25, 0.25)))
				var npc := Props.character(["character-male-a", "character-female-c", "character-male-f", "character-female-e"][k % 4])
				npc.scale = Vector3.ONE * 1.5
				npc.position = Vector3(inner - side * 0.5, 3.08, bz)
				npc.rotation.y = -side * PI / 2
				add_child(npc)
				var anims := npc.find_children("*", "AnimationPlayer", true, false)
				if anims.size() > 0:
					var ap := anims[0] as AnimationPlayer
					var an := "emote-yes" if ap.has_animation("emote-yes") else "idle"
					ap.get_animation(an).loop_mode = Animation.LOOP_LINEAR
					ap.play(an)
				_throwers.append(Vector3(inner - side * 0.5, 4.2, bz))
			z -= w
			k += 1
	# The plaza at the far end, closed at the back.
	var end_z := -(LENGTH + 6.0)
	_solid(body, Vector3(HALF_W * 2 + HOUSE_D * 2, 4.6, 0.6), Vector3(0, 2.3, end_z - 0.3), Props.mat(Color(0.95, 0.55, 0.45)))
	# Papel picado bunting across the street.
	var flag_cols := [Color(1, 0.35, 0.5), Color(1, 0.8, 0.2), Color(0.3, 0.8, 0.5), Color(0.35, 0.6, 1), Color(0.8, 0.45, 1)]
	for z in range(-3, -int(LENGTH + 4), -5):
		for i in 9:
			var f := _mesh(self, _box(Vector3(0.45, 0.5, 0.02)), Vector3(-HALF_W + 0.4 + i * (HALF_W * 2 - 0.8) / 8.0, 4.0 - sin(i / 8.0 * PI) * 0.5, z), Props.mat(flag_cols[i % flag_cols.size()]))
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sign := Label3D.new()
	sign.text = "¡La Tomatina!"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 120
	sign.pixel_size = 0.007
	sign.outline_size = 20
	sign.modulate = Color(1, 0.35, 0.3)
	sign.outline_modulate = Color(1, 1, 1)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(0, 6.0, 0.5)
	add_child(sign)


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 1.0, -(LENGTH + 4.0)))


func start_spot() -> Vector3:
	return to_global(Vector3(0, 0.3, 2.0))


## How far along the street a local position is (0..1), or -1 when outside it.
func progress(world_pos: Vector3) -> float:
	var lp := to_local(world_pos)
	if absf(lp.x) > HALF_W or lp.z > 0.5 or lp.z < -(LENGTH + 6.0):
		return -1.0
	return clampf(-lp.z / LENGTH, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	_cool -= delta
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	# Throw while someone is in the street (and hasn't reached the plaza).
	if player and not Game.ui_open:
		var lp := to_local(player.global_position)
		var in_street := absf(lp.x) < HALF_W + 0.5 and lp.z < 0.5 and lp.z > -LENGTH
		_next -= delta
		if in_street and _next <= 0 and not _throwers.is_empty():
			_next = _rng.randf_range(0.55, 0.95)
			_throw(player)
	# Fly the tomatoes.
	for i in range(_tomatoes.size() - 1, -1, -1):
		var tm: Dictionary = _tomatoes[i]
		tm.t += delta / FLIGHT
		var k: float = minf(tm.t, 1.0)
		var p: Vector3 = (tm.from as Vector3).lerp(tm.to, k) + Vector3(0, sin(k * PI) * 3.0, 0)
		(tm.node as Node3D).position = p
		(tm.marker as Node3D).scale = Vector3.ONE * (0.4 + 0.6 * k)
		if tm.t >= 1.0:
			_land(tm, player)
			_tomatoes.remove_at(i)
	for i in range(_splats.size() - 1, -1, -1):
		var s: Dictionary = _splats[i]
		s.t += delta
		if s.t > 3.0:
			(s.node as Node3D).queue_free()
			_splats.remove_at(i)


func _throw(player: CharacterBody3D) -> void:
	var lp := to_local(player.global_position)
	var lead := to_local(player.global_position + player.velocity * FLIGHT * 0.8) - lp
	var target := lp + Vector3(lead.x, 0, lead.z) + Vector3(_rng.randf_range(-1.2, 1.2), 0, _rng.randf_range(-1.2, 1.2))
	target.x = clampf(target.x, -HALF_W + 0.4, HALF_W - 0.4)
	target.y = 0.05
	# The nearest balcony a bit ahead of the player throws it.
	var from: Vector3 = _throwers[0]
	var best := 1e9
	for t in _throwers:
		var d: float = absf(t.z - (target.z - 3.0)) + _rng.randf() * 4.0
		if d < best:
			best = d
			from = t
	var tomato := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.44
	sm.material = Props.mat(Color(0.95, 0.15, 0.12))
	tomato.mesh = sm
	add_child(tomato)
	tomato.position = from
	var marker := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = HIT_R - 0.15
	ring.outer_radius = HIT_R
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1, 0.2, 0.2, 0.7)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material = rm
	marker.mesh = ring
	marker.position = target
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	_tomatoes.append({"node": tomato, "from": from, "to": target, "t": 0.0, "marker": marker})


func _land(tm: Dictionary, player: CharacterBody3D) -> void:
	var at: Vector3 = tm.to
	(tm.node as Node3D).queue_free()
	(tm.marker as Node3D).queue_free()
	var splat := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7
	cm.bottom_radius = 0.7
	cm.height = 0.02
	cm.material = Props.mat(Color(0.85, 0.1, 0.1))
	splat.mesh = cm
	splat.position = at + Vector3(0, 0.03, 0)
	splat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(splat)
	_splats.append({"node": splat, "t": 0.0})
	Game.sfx("thud", 1.5, -8)
	if not player or _cool > 0 or (sweet and is_instance_valid(sweet) and sweet.collected):
		return
	var lp := to_local(player.global_position)
	if Vector2(lp.x - at.x, lp.z - at.z).length() > HIT_R or lp.y > 1.6:
		return
	# ¡Splat!
	_cool = 0.8
	hits += 1
	Game.sfx("wrong", 1.3)
	if hits % 2 == 1:
		Game.show_toast("¡SPLAT! ¡Un tomate! Watch the red rings...")
	var back := global_transform.basis.z.normalized()      # towards the entrance
	player.knockback(back * 9.0 + Vector3(0, 6.0, 0))


func _flat(size: Vector3, pos: Vector3, m: Material) -> void:
	var mi := _mesh(self, _box(size), pos, m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
