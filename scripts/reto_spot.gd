extends Node3D
## A "Reto" (IGCSE challenge) in the world:
##   postcard - a yellow Correos postbox; write a postcard, marked by the sentence builder
##   notice   - a broken notice board; fix the verbs in the paragraph to repair it
##   chat     - a character glued to their phone; text them back in Spanish
## Walk into it to start. Once completed it shows how well you did.

signal touched(spot: Node3D)

var reto: Dictionary
var done := false
var best := 0            # best stars (postcard) / 1 when fixed (notice)

var _label: Label3D
var _float: Node3D       # the floating postcard / paper
var _cool := 0.0
var _t := randf() * TAU
var _board: Node3D


func setup(r: Dictionary) -> void:
	reto = r
	match str(r.get("kind", "postcard")):
		"notice":
			_build_notice()
		"chat":
			_build_chat()
		_:
			_build_postbox()
	_label = Label3D.new()
	_label.font = preload("res://scripts/ui.gd").ui_font(700)
	_label.font_size = 48
	_label.pixel_size = 0.005
	_label.outline_size = 14
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_modulate = Color(0.25, 0.2, 0.5)
	_label.position.y = 3.3
	add_child(_label)
	_refresh()
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.6
	sh.height = 2.5
	cs.shape = sh
	cs.position = Vector3(0, 1.2, 1.0)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_cool -= delta
	if _float and _float.visible:
		if str(reto.get("kind", "")) != "chat":
			_float.rotation.y += delta * 1.3
		_float.position.y = 2.5 + sin(_t * 2.0) * 0.12


func _on_body(body: Node) -> void:
	if Game.ui_open or _cool > 0 or not body.is_in_group("player"):
		return
	touched.emit(self)


func rest() -> void:
	_cool = 1.5


## Records a result. Postcards keep their best star count; returns true the first time it's completed.
func record(stars: int) -> bool:
	var first := not done
	best = maxi(best, stars)
	done = true
	_refresh()
	if first and str(reto.get("kind", "")) == "notice" and _board:
		var t := create_tween()
		t.tween_property(_board, "rotation:z", 0.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return first


func _refresh() -> void:
	var kind := str(reto.get("kind", "postcard"))
	if not done:
		_label.text = {"postcard": "Reto: la postal", "notice": "Reto: el tablón roto", "chat": "Reto: el chat"}.get(kind, "Reto")
		_label.modulate = Color(1, 0.9, 0.4)
		return
	if kind == "postcard":
		_label.text = "★".repeat(best) + "☆".repeat(5 - best)
		_label.modulate = Color(1, 0.85, 0.2)
	elif kind == "chat":
		_label.text = "¡Hablamos!"
		_label.modulate = Color(0.5, 1.0, 0.5)
	else:
		_label.text = "¡Arreglado!"
		_label.modulate = Color(0.5, 1.0, 0.5)
	if _float:
		_float.visible = (kind == "postcard" and best < 5) or (kind == "chat" and not done)


# ---------------------------------------------------------------- models

## A Spanish Correos postbox: yellow, with a rounded top and a posting slot.
func _build_postbox() -> void:
	var yellow := Props.mat(Color(1.0, 0.8, 0.1))
	var dark := Props.mat(Color(0.2, 0.25, 0.45))
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	_mesh(body, _box(Vector3(0.9, 1.3, 0.7)), Vector3(0, 0.75, 0), yellow)
	var top := CylinderMesh.new()
	top.top_radius = 0.35
	top.bottom_radius = 0.35
	top.height = 0.9
	var tm := _mesh(body, top, Vector3(0, 1.4, 0), yellow)
	tm.rotation.z = PI / 2
	tm.scale = Vector3(1, 1, 1.0)
	_mesh(body, _box(Vector3(0.6, 0.08, 0.05)), Vector3(0, 1.15, 0.36), dark)          # slot
	_mesh(body, _box(Vector3(1.0, 0.12, 0.8)), Vector3(0, 0.06, 0), dark)             # base
	var horn := Label3D.new()                                                          # Correos-style badge
	horn.text = "✉"
	horn.font_size = 90
	horn.pixel_size = 0.005
	horn.modulate = Color(0.2, 0.25, 0.45)
	horn.position = Vector3(0, 0.7, 0.36)
	body.add_child(horn)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.9, 1.75, 0.7)
	cs.shape = sh
	cs.position.y = 0.87
	body.add_child(cs)
	# A postcard floating above it.
	_float = Node3D.new()
	add_child(_float)
	var card := QuadMesh.new()
	card.size = Vector2(0.9, 0.6)
	var m := StandardMaterial3D.new()
	m.albedo_texture = preload("res://scripts/question_card.gd").card_texture()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = Color(1, 0.95, 0.8)
	m.emission_energy_multiplier = 0.25
	card.material = m
	var ci := MeshInstance3D.new()
	ci.mesh = card
	_float.add_child(ci)
	var stamp := _mesh(_float, _box(Vector3(0.16, 0.2, 0.01)), Vector3(0.3, 0.14, 0.01), Props.mat(Color(0.95, 0.35, 0.4)))
	stamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A notice board on two posts, knocked crooked; it straightens when fixed.
func _build_notice() -> void:
	var wood := Props.mat(Color(0.6, 0.4, 0.25))
	var cork := Props.mat(Color(0.85, 0.65, 0.42))
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	for x in [-1.3, 1.3]:
		_mesh(body, _box(Vector3(0.18, 2.4, 0.18)), Vector3(x, 1.2, 0), wood)
	_board = Node3D.new()
	body.add_child(_board)
	_board.position = Vector3(0, 1.75, 0.1)
	_board.rotation.z = 0.22
	_mesh(_board, _box(Vector3(2.8, 1.5, 0.12)), Vector3.ZERO, cork)
	for i in 3:
		var paper := _mesh(_board, _box(Vector3(0.7, 0.55, 0.02)), Vector3(-0.8 + i * 0.8, 0.1 - (i % 2) * 0.2, 0.08), Props.mat(Color(1, 0.98, 0.92)))
		paper.rotation.z = randf_range(-0.2, 0.2)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.8, 2.5, 0.3)
	cs.shape = sh
	cs.position.y = 1.25
	body.add_child(cs)
	_float = Node3D.new()   # a torn sheet fluttering above - the broken bit
	add_child(_float)
	var sheet := _mesh(_float, _box(Vector3(0.6, 0.45, 0.02)), Vector3.ZERO, Props.mat(Color(1, 0.98, 0.92)))
	sheet.rotation.z = 0.4


## Someone sitting on a bench, staring at their phone; a big phone floats above, buzzing with messages.
func _build_chat() -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var wood := Props.mat(Color(0.55, 0.38, 0.6))
	_mesh(body, _box(Vector3(2.2, 0.12, 0.7)), Vector3(0, 0.55, -0.25), wood)          # bench seat
	_mesh(body, _box(Vector3(2.2, 0.6, 0.1)), Vector3(0, 0.95, -0.6), wood)            # back
	for x in [-0.95, 0.95]:
		_mesh(body, _box(Vector3(0.12, 0.55, 0.6)), Vector3(x, 0.27, -0.25), wood)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.2, 1.3, 0.8)
	cs.shape = sh
	cs.position = Vector3(0, 0.65, -0.25)
	body.add_child(cs)
	var npc := Props.character(str(reto.get("character", "character-female-e")))
	npc.scale = Vector3.ONE * 1.6
	npc.position = Vector3(-0.35, 0.0, 0.05)
	add_child(npc)
	var anims := npc.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap := anims[0] as AnimationPlayer
		var anim := "sit" if ap.has_animation("sit") else "idle"
		ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim)
		if anim == "sit":
			npc.position.y = 0.05
	# The floating phone: a dark case, a glowing screen and three message bubbles.
	_float = Node3D.new()
	add_child(_float)
	_float.position = Vector3(0, 2.5, 0)
	_mesh(_float, _box(Vector3(0.62, 1.1, 0.08)), Vector3.ZERO, Props.mat(Color(0.15, 0.13, 0.25)))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.85, 0.95, 1.0)
	glow.emission_enabled = true
	glow.emission = Color(0.6, 0.85, 1.0)
	glow.emission_energy_multiplier = 0.8
	_mesh(_float, _box(Vector3(0.52, 0.94, 0.02)), Vector3(0, 0, 0.045), glow)
	var bubbles := [[-0.07, 0.28, Color(1, 1, 1)], [0.07, 0.05, Color(0.55, 0.9, 0.65)], [-0.07, -0.18, Color(1, 1, 1)]]
	for b in bubbles:
		_mesh(_float, _box(Vector3(0.3, 0.13, 0.02)), Vector3(b[0], b[1], 0.06), Props.mat(b[2]))


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material) -> MeshInstance3D:
	(mesh as PrimitiveMesh).material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi
