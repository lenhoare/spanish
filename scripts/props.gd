class_name Props
## Helpers for spawning Kenney models and simple materials.

const PLATFORMER := "res://assets/platformer/%s.glb"

static var _cache := {}


## "star" -> Platformer Kit; "food/cupcake" or "graveyard/pumpkin" -> other kits in assets/.
static func model(name: String) -> Node3D:
	if name.begins_with("proc/"):
		return procedural(name.trim_prefix("proc/"))
	var path := ("res://assets/%s.glb" % name) if name.contains("/") else PLATFORMER % name
	if not _cache.has(path):
		_cache[path] = load(path)
	return (_cache[path] as PackedScene).instantiate()


## Simple models built from shapes, for things Kenney doesn't have.
static func procedural(name: String) -> Node3D:
	var n := Node3D.new()
	var add := func(size: Vector3, pos: Vector3, col: Color) -> void:
		var b := BoxMesh.new()
		b.size = size
		b.material = mat(col)
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.position = pos
		n.add_child(mi)
	var glow := func(size: Vector3, pos: Vector3, col: Color) -> void:
		var b := BoxMesh.new()
		b.size = size
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 1.2
		b.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.position = pos
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	var neon: Color = [Color(1.0, 0.35, 0.75), Color(0.3, 0.95, 1.0), Color(0.75, 1.0, 0.35), Color(1.0, 0.85, 0.3)][randi() % 4]
	match name:
		"lamp":         # a neon street lamp
			add.call(Vector3(0.1, 1.6, 0.1), Vector3(0, 0.8, 0), Color(0.2, 0.18, 0.35))
			glow.call(Vector3(0.3, 0.3, 0.3), Vector3(0, 1.75, 0), neon)
		"screen":       # a big glowing screen on two legs
			add.call(Vector3(0.08, 1.0, 0.08), Vector3(-0.5, 0.5, 0), Color(0.2, 0.18, 0.35))
			add.call(Vector3(0.08, 1.0, 0.08), Vector3(0.5, 0.5, 0), Color(0.2, 0.18, 0.35))
			add.call(Vector3(1.4, 0.9, 0.1), Vector3(0, 1.4, 0), Color(0.15, 0.13, 0.25))
			glow.call(Vector3(1.25, 0.75, 0.02), Vector3(0, 1.4, 0.06), neon)
			glow.call(Vector3(1.25, 0.75, 0.02), Vector3(0, 1.4, -0.06), neon)
		"phone":        # un móvil
			add.call(Vector3(0.14, 0.26, 0.025), Vector3(0, 0.13, 0), Color(0.15, 0.13, 0.25))
			glow.call(Vector3(0.12, 0.22, 0.01), Vector3(0, 0.13, 0.015), Color(0.5, 0.85, 1.0))
		"charger":      # un cargador: a plug with a curly-ish cable
			add.call(Vector3(0.12, 0.1, 0.08), Vector3(0, 0.05, 0), Color(0.95, 0.95, 0.97))
			add.call(Vector3(0.02, 0.05, 0.01), Vector3(-0.03, 0.12, 0), Color(0.7, 0.7, 0.72))
			add.call(Vector3(0.02, 0.05, 0.01), Vector3(0.03, 0.12, 0), Color(0.7, 0.7, 0.72))
			add.call(Vector3(0.4, 0.025, 0.025), Vector3(0.24, 0.02, 0), Color(0.95, 0.95, 0.97))
		"bunting":      # papel picado: two poles with a string of coloured flags
			for x in [-1.6, 1.6]:
				add.call(Vector3(0.1, 2.8, 0.1), Vector3(x, 1.4, 0), Color(0.55, 0.4, 0.3))
			var flag_cols := [Color(1, 0.35, 0.5), Color(1, 0.8, 0.2), Color(0.3, 0.8, 0.5), Color(0.35, 0.6, 1), Color(0.8, 0.45, 1)]
			for i in 7:
				var x := -1.35 + i * 0.45
				add.call(Vector3(0.36, 0.42, 0.02), Vector3(x, 2.35 - sin(i / 6.0 * PI) * 0.35, 0), flag_cols[i % flag_cols.size()])
		"guitar":       # una guitarra: body, sound hole, neck and head
			add.call(Vector3(0.34, 0.3, 0.1), Vector3(0, 0.17, 0), Color(0.85, 0.35, 0.3))
			add.call(Vector3(0.26, 0.2, 0.1), Vector3(0, 0.38, 0), Color(0.85, 0.35, 0.3))
			add.call(Vector3(0.08, 0.08, 0.01), Vector3(0, 0.26, 0.055), Color(0.2, 0.12, 0.1))
			add.call(Vector3(0.06, 0.42, 0.05), Vector3(0, 0.68, 0), Color(0.55, 0.35, 0.2))
			add.call(Vector3(0.1, 0.1, 0.05), Vector3(0, 0.93, 0), Color(0.3, 0.2, 0.15))
		"microphone":   # un micrófono on a little stand
			add.call(Vector3(0.24, 0.03, 0.24), Vector3(0, 0.015, 0), Color(0.2, 0.2, 0.25))
			add.call(Vector3(0.03, 0.4, 0.03), Vector3(0, 0.22, 0), Color(0.6, 0.6, 0.65))
			add.call(Vector3(0.06, 0.14, 0.06), Vector3(0, 0.48, 0), Color(0.15, 0.15, 0.2))
			glow.call(Vector3(0.1, 0.1, 0.1), Vector3(0, 0.59, 0), Color(0.75, 0.75, 0.8))
		"drumsticks":   # las baquetas
			add.call(Vector3(0.4, 0.03, 0.03), Vector3(0, 0.02, -0.04), Color(0.9, 0.75, 0.5))
			add.call(Vector3(0.4, 0.03, 0.03), Vector3(0.02, 0.02, 0.04), Color(0.9, 0.75, 0.5))
			add.call(Vector3(0.05, 0.04, 0.04), Vector3(0.21, 0.02, -0.04), Color(0.95, 0.9, 0.8))
			add.call(Vector3(0.05, 0.04, 0.04), Vector3(0.23, 0.02, 0.04), Color(0.95, 0.9, 0.8))
		"speaker":      # a big festival speaker
			add.call(Vector3(0.6, 1.0, 0.5), Vector3(0, 0.5, 0), Color(0.12, 0.12, 0.18))
			add.call(Vector3(0.4, 0.4, 0.02), Vector3(0, 0.35, 0.26), Color(0.35, 0.35, 0.45))
			add.call(Vector3(0.2, 0.2, 0.02), Vector3(0, 0.78, 0.26), Color(0.35, 0.35, 0.45))
		"photo":        # una foto de la familia in a frame
			add.call(Vector3(0.3, 0.24, 0.03), Vector3(0, 0.14, 0), Color(0.75, 0.5, 0.3))
			add.call(Vector3(0.24, 0.18, 0.01), Vector3(0, 0.14, 0.02), Color(0.6, 0.85, 1.0))
			add.call(Vector3(0.05, 0.09, 0.01), Vector3(-0.05, 0.11, 0.028), Color(0.95, 0.5, 0.55))
			add.call(Vector3(0.05, 0.11, 0.01), Vector3(0.05, 0.12, 0.028), Color(0.4, 0.5, 0.95))
		"suitcase":     # una maleta: a red suitcase with a handle and stickers
			add.call(Vector3(0.5, 0.36, 0.16), Vector3(0, 0.2, 0), Color(0.9, 0.3, 0.35))
			add.call(Vector3(0.2, 0.04, 0.05), Vector3(0, 0.42, 0), Color(0.2, 0.2, 0.25))
			add.call(Vector3(0.04, 0.06, 0.05), Vector3(-0.08, 0.39, 0), Color(0.2, 0.2, 0.25))
			add.call(Vector3(0.04, 0.06, 0.05), Vector3(0.08, 0.39, 0), Color(0.2, 0.2, 0.25))
			add.call(Vector3(0.12, 0.1, 0.01), Vector3(-0.12, 0.25, 0.085), Color(1.0, 0.85, 0.3))
			add.call(Vector3(0.1, 0.1, 0.01), Vector3(0.12, 0.14, 0.085), Color(0.4, 0.75, 1.0))
		"backpack":     # una mochila: a school backpack
			add.call(Vector3(0.34, 0.42, 0.2), Vector3(0, 0.23, 0), Color(0.3, 0.55, 0.95))
			add.call(Vector3(0.26, 0.18, 0.06), Vector3(0, 0.16, 0.12), Color(0.95, 0.75, 0.25))
			add.call(Vector3(0.3, 0.08, 0.18), Vector3(0, 0.47, 0), Color(0.2, 0.4, 0.8))
		"pencilcase":   # un estuche: a pencil case with pencils poking out
			add.call(Vector3(0.36, 0.1, 0.12), Vector3(0, 0.05, 0), Color(0.95, 0.4, 0.6))
			add.call(Vector3(0.3, 0.03, 0.03), Vector3(0.05, 0.11, 0.02), Color(1.0, 0.85, 0.2))
			add.call(Vector3(0.28, 0.03, 0.03), Vector3(0.08, 0.12, -0.03), Color(0.3, 0.8, 0.4))
		"calculator":   # una calculadora
			add.call(Vector3(0.2, 0.04, 0.3), Vector3(0, 0.02, 0), Color(0.25, 0.25, 0.3))
			add.call(Vector3(0.16, 0.01, 0.07), Vector3(0, 0.045, -0.09), Color(0.7, 0.85, 0.7))
			for i in 3:
				for j in 3:
					add.call(Vector3(0.035, 0.012, 0.035), Vector3(-0.05 + i * 0.05, 0.045, 0.0 + j * 0.05), Color(0.9, 0.9, 0.95))
		"wallet":       # una cartera: a brown wallet with a note sticking out
			add.call(Vector3(0.32, 0.05, 0.22), Vector3(0, 0.03, 0), Color(0.5, 0.3, 0.18))
			add.call(Vector3(0.2, 0.01, 0.12), Vector3(0.05, 0.065, 0.02), Color(0.5, 0.8, 0.5))
			add.call(Vector3(0.05, 0.03, 0.05), Vector3(-0.12, 0.065, 0), Color(0.9, 0.75, 0.3))
	return n


static func character(name: String) -> Node3D:
	# The round "oo" buddies live in the Platformer Kit.
	var path := (PLATFORMER % name) if name.begins_with("character-oo") else "res://assets/characters/%s.glb" % name
	if not _cache.has(path):
		_cache[path] = load(path)
	return (_cache[path] as PackedScene).instantiate()


## Combined local-space bounding box of all meshes under `node`.
static func aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := node.global_transform.affine_inverse() * m.global_transform if node.is_inside_tree() else _relative_xform(node, m)
		var b := xf * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


static func _relative_xform(root: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


## Places a Kenney model. collide: "" (none), "box" or "cyl".
static func place(parent: Node3D, name: String, pos: Vector3, rot_y := 0.0, scale := 1.0, collide := "") -> Node3D:
	var m := model(name)
	if collide == "":
		parent.add_child(m)
		m.position = pos
		m.rotation.y = rot_y
		m.scale = Vector3.ONE * scale
		return m
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	parent.add_child(body)
	body.position = pos
	body.rotation.y = rot_y
	body.add_child(m)
	m.scale = Vector3.ONE * scale
	var box := aabb(m)
	box = AABB(box.position * scale, box.size * scale)
	var cs := CollisionShape3D.new()
	if collide == "trunk":
		# Trees: only the trunk is solid, so you can walk between them under the canopy.
		var shape := CylinderShape3D.new()
		shape.radius = clampf(minf(box.size.x, box.size.z) * 0.12, 0.2, 0.45)
		shape.height = box.size.y
		cs.shape = shape
		cs.position = Vector3(0, box.size.y / 2.0, 0)
		body.add_child(cs)
		return body
	if collide == "cyl":
		var shape := CylinderShape3D.new()
		shape.radius = maxf(box.size.x, box.size.z) * 0.5
		shape.height = box.size.y
		cs.shape = shape
	else:
		var shape := BoxShape3D.new()
		shape.size = box.size
		cs.shape = shape
	cs.position = box.get_center()
	body.add_child(cs)
	return body


static func mat(color: Color, toon := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if toon:
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return m


static func unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## A tall soft column of light that makes important things visible from across the island.
static func beacon(parent: Node3D, color: Color, height := 26.0) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = 0.28
	c.bottom_radius = 0.45
	c.height = height
	c.radial_segments = 12
	c.rings = 1
	c.cap_top = false
	c.cap_bottom = false
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(color.r, color.g, color.b, 0.35)
	c.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position.y = height / 2.0 + 0.5
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# "beacons": false in config.json turns these off (they're still created, just hidden).
	mi.visible = bool(Game.config.get("beacons", true))
	parent.add_child(mi)
	return mi


## A soft round "blob" shadow texture drawn in code.
static func blob_texture() -> Texture2D:
	var key := "blob"
	if _cache.has(key):
		return _cache[key]
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x - size / 2.0 + 0.5, y - size / 2.0 + 0.5).length() / (size / 2.0)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.1, 0.05, 0.2, a * a * 0.6))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
