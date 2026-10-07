class_name Atmosphere
## Special moods an island can have (switched on per island in config.json's "course"):
##   "night": true    - moonlit night: dark blue sky, moon, stars, fireflies, glowing lanterns
##   "rainbow": true  - a big rainbow arching across the sky
##   "sparkle": true  - glitter drifting in the air, twinkles on the ground, a sparkly sea, and
##                      a sparkle trail behind the hero
## The walkable rainbow road is a sweet ("kind": "rainbow"), see rainbow_road().


## Night colours for a theme: everything darker and bluer, but still easy to read.
static func night_theme(t: Dictionary) -> Dictionary:
	var n := t.duplicate()
	var tint := func(c: Color, k: float) -> Color:
		return Color(c.r * k * 0.85, c.g * k * 0.9, minf(1.0, c.b * k * 0.98 + 0.03))
	n.grass = tint.call(t.grass, 0.62)
	n.dirt = tint.call(t.dirt, 0.6)
	n.sand = tint.call(t.sand, 0.6)
	n.sky = Color(0.03, 0.04, 0.16)
	n.horizon = Color(0.16, 0.16, 0.38)
	n.deep = Color(0.02, 0.06, 0.2)
	n.shallow = Color(0.07, 0.17, 0.4)
	n.sun = Color(0.62, 0.72, 1.0)
	n.sun_energy = 0.55
	return n


## Night sky and lighting: called once the environment and sun exist.
static func night(world: Node3D, env: Environment, radius: float, add_lanterns: bool) -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.56, 0.75)
	env.ambient_light_energy = 0.6
	env.fog_light_color = Color(0.1, 0.1, 0.26)
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.85
	# The moon, with a soft halo.
	var moon_dir := Vector3(-0.45, 0.42, -0.79).normalized()
	var moon := _glow_sphere(14.0, Color(1.0, 0.97, 0.85), 2.2)
	moon.position = moon_dir * 270.0
	world.add_child(moon)
	var halo := _glow_sphere(30.0, Color(0.6, 0.65, 1.0, 0.12), 0.6, true)
	halo.position = moon.position
	world.add_child(halo)
	# Stars across the sky.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	sm.radial_segments = 6
	sm.rings = 3
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1, 1, 0.95)
	sm.material = smat
	mm.mesh = sm
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	mm.instance_count = 420
	for i in mm.instance_count:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.12, 1.0), rng.randf_range(-1, 1)).normalized()
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.5, 1.6)), d * 280.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)
	# Fireflies drifting over the island.
	var ff := _particles(160, 5.0, Vector3(radius * 0.9, 1.4, radius * 0.9), 0.07, [Color(0.85, 1.0, 0.45), Color(1.0, 0.9, 0.4)], 2.4)
	ff.position.y = 1.6
	ff.direction = Vector3(0, 1, 0)
	ff.spread = 180.0
	ff.initial_velocity_min = 0.1
	ff.initial_velocity_max = 0.4
	ff.gravity = Vector3.ZERO
	world.add_child(ff)
	# Warm lanterns dotted around (islands that don't have their own lamps).
	if add_lanterns:
		for i in 18:
			var a := rng.randf() * TAU
			var r := rng.randf_range(radius * 0.3, radius - 2.5)
			var p := Vector3(cos(a), 0, sin(a)) * r
			if world.has_method("is_free_spot") and not world.is_free_spot(Vector2(p.x, p.z), 1.0):
				continue
			var l := Props.model("proc/lantern")
			l.position = p
			l.scale = Vector3.ONE * 1.6
			world.add_child(l)


## A soft glow around the hero at night, so they're always easy to see.
static func hero_light(player: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.92, 0.75)
	light.light_energy = 1.4
	light.omni_range = 7.0
	light.position = Vector3(0, 1.6, 0)
	light.shadow_enabled = false
	player.add_child(light)


## A big rainbow arching across the sky, in the distance (the bottom is hidden by the sea).
static func sky_rainbow(world: Node3D, angle_deg: float) -> void:
	var cols := [Color(1, 0.3, 0.3), Color(1, 0.6, 0.2), Color(1, 0.92, 0.3), Color(0.4, 0.85, 0.4), Color(0.35, 0.65, 1), Color(0.45, 0.4, 0.95), Color(0.75, 0.45, 0.95)]
	var a := deg_to_rad(angle_deg)
	var dir := Vector3(cos(a), 0, sin(a))
	var root := Node3D.new()
	world.add_child(root)
	root.position = dir * 140.0 + Vector3(0, -14, 0)
	root.rotation.y = atan2(dir.x, dir.z)      # the arc faces the island
	for i in cols.size():
		var t := TorusMesh.new()
		t.inner_radius = 62.0 + i * 3.5
		t.outer_radius = 65.5 + i * 3.5
		t.rings = 96
		t.ring_segments = 4
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var c: Color = cols[cols.size() - 1 - i]
		m.albedo_color = Color(c.r, c.g, c.b, 0.5)
		t.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = t
		mi.rotation.x = PI / 2
		mi.scale.y = 0.02
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)


## A rainbow road you can walk on: from `start` (on the island) curving up to a cloud at
## `height`, `length` metres further out along `dir`. Returns the cloud's top centre.
static func rainbow_road(world: Node3D, start: Vector3, dir: Vector3, length := 34.0, height := 11.0) -> Vector3:
	var cols := [Color(0.95, 0.2, 0.3), Color(1, 0.5, 0.12), Color(1, 0.82, 0.1), Color(0.22, 0.75, 0.3), Color(0.15, 0.5, 0.95), Color(0.38, 0.28, 0.85), Color(0.68, 0.3, 0.85)]
	var W := 4.2
	var N := 40
	var side := Vector3(-dir.z, 0, dir.x)
	var pt := func(s: float) -> Vector3:
		return start + dir * length * s + Vector3(0, height * sin(s * PI / 2.0) + 0.05, 0)
	# One mesh: seven coloured lanes across the top, a pale underside.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in N:
		var a: Vector3 = pt.call(float(k) / N)
		var b: Vector3 = pt.call(float(k + 1) / N)
		for lane in cols.size():
			var w0 := -W / 2.0 + W * lane / cols.size()
			var w1 := -W / 2.0 + W * (lane + 1) / cols.size()
			st.set_color(cols[lane])
			for v in [a + side * w0, b + side * w0, b + side * w1, a + side * w0, b + side * w1, a + side * w1]:
				st.add_vertex(v)
		st.set_color(Color(0.95, 0.92, 1.0))
		for v in [a + side * (-W / 2) + Vector3.DOWN * 0.3, a + side * (W / 2) + Vector3.DOWN * 0.3, b + side * (W / 2) + Vector3.DOWN * 0.3,
				a + side * (-W / 2) + Vector3.DOWN * 0.3, b + side * (W / 2) + Vector3.DOWN * 0.3, b + side * (-W / 2) + Vector3.DOWN * 0.3]:
			st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = Color(0.08, 0.07, 0.1)
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mesh.surface_set_material(0, m)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	world.add_child(mi)
	# Solid: a short box per step along the curve.
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	world.add_child(body)
	for k in N:
		var a: Vector3 = pt.call(float(k) / N)
		var b: Vector3 = pt.call(float(k + 1) / N)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(W, 0.3, a.distance_to(b) + 0.08)
		cs.shape = sh
		var mid := (a + b) / 2.0 + Vector3(0, -0.15, 0)
		cs.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), mid)
		body.add_child(cs)
	# The cloud at the top.
	var top: Vector3 = pt.call(1.0) + dir * 3.2
	var cloud_m := StandardMaterial3D.new()
	cloud_m.albedo_color = Color(1, 1, 1)
	cloud_m.emission_enabled = true
	cloud_m.emission = Color(0.85, 0.88, 1.0)
	cloud_m.emission_energy_multiplier = 0.3
	cloud_m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var s := SphereMesh.new()
		var r := rng.randf_range(1.6, 2.6)
		s.radius = r
		s.height = r * 1.4
		s.material = cloud_m
		var p := MeshInstance3D.new()
		p.mesh = s
		var a := TAU * i / 9.0
		p.position = top + Vector3(cos(a) * 2.6, -0.9 + rng.randf_range(-0.2, 0.3), sin(a) * 2.6)
		world.add_child(p)
	var ccs := CollisionShape3D.new()
	var csh := CylinderShape3D.new()
	csh.radius = 4.2
	csh.height = 0.6
	ccs.shape = csh
	ccs.position = top + Vector3(0, -0.3, 0)
	body.add_child(ccs)
	var flat := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 4.0
	fm.bottom_radius = 3.6
	fm.height = 0.5
	fm.material = cloud_m
	flat.mesh = fm
	flat.position = top + Vector3(0, -0.3, 0)
	world.add_child(flat)
	# A little twinkle over the road.
	var tw := _particles(40, 1.6, Vector3(1.6, 0.6, length * 0.5), 0.09, [Color(1, 1, 1), Color(1, 0.85, 1)], 3.0)
	tw.position = pt.call(0.5) + Vector3(0, 0.8, 0)
	tw.rotation.y = atan2(dir.x, dir.z)
	world.add_child(tw)
	return top


## Sparkle: glitter drifting in the air and twinkles near the ground.
static func sparkle(world: Node3D, radius: float, env: Environment = null) -> void:
	var cols := [Color(1, 0.72, 0.05), Color(0.1, 0.75, 1.0), Color(1, 0.25, 0.75), Color(0.6, 0.35, 1.0), Color(1, 0.85, 0.2)]
	if env:
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_hdr_threshold = 0.9
	var air := _particles(320, 4.0, Vector3(radius, 4.0, radius), 0.17, cols, 4.0)
	air.position.y = 4.5
	air.direction = Vector3(0, -1, 0)
	air.spread = 30.0
	air.initial_velocity_min = 0.2
	air.initial_velocity_max = 0.6
	air.gravity = Vector3(0, -0.05, 0)
	world.add_child(air)
	var ground := _particles(260, 1.2, Vector3(radius, 0.1, radius), 0.22, cols, 4.5)
	ground.position.y = 0.25
	ground.gravity = Vector3.ZERO
	ground.initial_velocity_min = 0.0
	ground.initial_velocity_max = 0.05
	world.add_child(ground)


## A trail of sparkles behind the hero.
static func sparkle_trail(player: Node3D) -> void:
	var p := _particles(70, 0.9, Vector3(0.3, 0.3, 0.3), 0.14, [Color(1, 0.72, 0.05), Color(0.1, 0.75, 1.0), Color(1, 0.25, 0.75)], 3.2)
	p.local_coords = false
	p.position = Vector3(0, 0.6, 0)
	p.gravity = Vector3(0, 0.4, 0)
	player.add_child(p)


# ---------------------------------------------------------------- helpers

## Twinkling particles: little glowing stars that grow and shrink.
static func _particles(amount: int, life: float, extents: Vector3, size: float, cols: Array, glow: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.randomness = 0.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	var q := QuadMesh.new()
	q.size = Vector2(size, size) * 2.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _star_texture()
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = glow * 0.3
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray(cols)
	p.color_initial_ramp = g
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	return p


static var _star_tex: Texture2D

## A soft four-pointed twinkle drawn in code.
static func _star_texture() -> Texture2D:
	if _star_tex:
		return _star_tex
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var dx := absf(x - n / 2.0 + 0.5) / (n / 2.0)
			var dy := absf(y - n / 2.0 + 0.5) / (n / 2.0)
			var core := clampf(1.0 - sqrt(dx * dx + dy * dy) * 2.2, 0.0, 1.0)
			var rays := clampf(1.0 - (dx * 6.0 + dy) , 0.0, 1.0) + clampf(1.0 - (dy * 6.0 + dx), 0.0, 1.0)
			var a := clampf(core + rays * 0.8, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_star_tex = ImageTexture.create_from_image(img)
	return _star_tex


static func _glow_sphere(r: float, col: Color, energy: float, transparent := false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
	s.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
