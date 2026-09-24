class_name Props
## Helpers for spawning Kenney models and simple materials.

const PLATFORMER := "res://assets/platformer/%s.glb"

static var _cache := {}


## "star" -> Platformer Kit; "food/cupcake" or "graveyard/pumpkin" -> other kits in assets/.
static func model(name: String) -> Node3D:
	var path := ("res://assets/%s.glb" % name) if name.contains("/") else PLATFORMER % name
	if not _cache.has(path):
		_cache[path] = load(path)
	return (_cache[path] as PackedScene).instantiate()


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
