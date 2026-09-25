extends Node3D
## "El escenario": a festival stage with four big dance pads in front of it. Step on the
## start star: the DJ calls out a sequence of colours IN SPANISH (and the pads flash, in the
## early rounds). Then dance on the pads in the same order. The last round is words only.
## Faces local +Z (towards the middle of the island); the stage is behind the pads.

const DEFAULT_PADS := [
	{"word": "rojo", "color": "#ff4d5e"},
	{"word": "azul", "color": "#3d8bff"},
	{"word": "verde", "color": "#3cc47c"},
	{"word": "amarillo", "color": "#ffd23f"},
]
const DEFAULT_ROUNDS := [["rojo", "verde", "azul"], ["amarillo", "rojo", "azul", "verde"], ["verde", "amarillo", "rojo", "azul", "amarillo"]]
## A 2x2 grid with gaps between, so you can walk from any pad to any other without
## stepping on a third one.
const PAD_POS := [Vector2(-2.4, -0.9), Vector2(2.4, -0.9), Vector2(-2.4, 3.9), Vector2(2.4, 3.9)]

var reto: Dictionary
var sweet: Node3D
var done := false
var round_i := 0

var _pads: Array = []            # [{word, color, mat, area}]
var _dj_label: Label3D
var _state := "idle"             # idle / showing / dancing
var _seq: Array = []
var _step := 0
var _cool := 0.0
var _t := 0.0
var _lights: Array[MeshInstance3D] = []


func setup(r: Dictionary) -> void:
	reto = r
	var pads: Array = r.get("pads", DEFAULT_PADS)
	# The stage: a raised platform at the back with a big frame, speakers and a DJ desk.
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var deck := Props.mat(Color(0.3, 0.25, 0.45))
	_solid(body, Vector3(14.0, 1.2, 4.5), Vector3(0, 0.6, -4.5), deck)
	_solid(body, Vector3(0.5, 6.0, 0.5), Vector3(-6.8, 3.0, -6.4), Props.mat(Color(0.2, 0.2, 0.3)))
	_solid(body, Vector3(0.5, 6.0, 0.5), Vector3(6.8, 3.0, -6.4), Props.mat(Color(0.2, 0.2, 0.3)))
	_mesh(body, _box(Vector3(14.1, 0.5, 0.5)), Vector3(0, 6.1, -6.4), Props.mat(Color(0.2, 0.2, 0.3)))
	_mesh(body, _box(Vector3(13.0, 5.0, 0.1)), Vector3(0, 3.7, -6.6), Props.mat(Color(0.95, 0.4, 0.65)))
	for x in [-5.6, 5.6]:
		_solid(body, Vector3(1.4, 2.4, 1.2), Vector3(x, 2.4, -4.8), Props.mat(Color(0.12, 0.12, 0.18)))
		for y in [1.9, 2.9]:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.38
			cone.bottom_radius = 0.38
			cone.height = 0.05
			var cm := _mesh(body, cone, Vector3(x, y, -4.18), Props.mat(Color(0.4, 0.4, 0.5)))
			cm.rotation.x = PI / 2
	_solid(body, Vector3(3.0, 1.0, 1.0), Vector3(0, 1.7, -4.2), Props.mat(Color(0.15, 0.13, 0.25)))
	var dj := Props.character(str(r.get("character", "character-male-c")))
	dj.scale = Vector3.ONE * 1.7
	dj.position = Vector3(0, 1.2, -5.2)
	add_child(dj)
	var anims := dj.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap := anims[0] as AnimationPlayer
		var anim := "emote-yes" if ap.has_animation("emote-yes") else "idle"
		ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim)
	# Coloured lights along the top of the frame.
	for i in 7:
		var bulb := SphereMesh.new()
		bulb.radius = 0.25
		bulb.height = 0.5
		var m := StandardMaterial3D.new()
		var c := Color(str(pads[i % pads.size()].color))
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.0
		bulb.material = m
		var li := MeshInstance3D.new()
		li.mesh = bulb
		li.position = Vector3(-6.0 + i * 2.0, 5.7, -6.1)
		add_child(li)
		_lights.append(li)
	_label(self, str(r.get("sign", "¡Festival!")), 160, Vector3(0, 7.3, -6.4), Color(1, 0.9, 0.4)).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_dj_label = _label(self, "¡Pisa la estrella\npara bailar!", 130, Vector3(0, 4.4, -3.0), Color.WHITE)

	# The dance pads.
	for i in mini(pads.size(), PAD_POS.size()):
		var col := Color(str(pads[i].color))
		var m := StandardMaterial3D.new()
		m.albedo_color = col.darkened(0.35)
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.0
		var pad := _mesh(self, _box(Vector3(2.4, 0.12, 2.4)), Vector3(PAD_POS[i].x, 0.06, PAD_POS[i].y), m)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.0, 1.2, 2.0)
		cs.shape = sh
		area.add_child(cs)
		area.position = Vector3(PAD_POS[i].x, 0.6, PAD_POS[i].y)
		add_child(area)
		area.body_entered.connect(_on_pad.bind(i))
		_pads.append({"word": str(pads[i].word), "color": col, "mat": m})
	# The start star in front of the pads.
	var star := Props.model("star")
	star.scale = Vector3.ONE * 1.4
	star.position = Vector3(0, 0.6, 7.5)
	star.name = "StartStar"
	add_child(star)
	var sa := Area3D.new()
	var scs := CollisionShape3D.new()
	var ssh := CylinderShape3D.new()
	ssh.radius = 1.0
	ssh.height = 2.0
	scs.shape = ssh
	sa.add_child(scs)
	sa.position = Vector3(0, 1.0, 7.5)
	add_child(sa)
	sa.body_entered.connect(_on_start)


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 2.2, -3.2))


func pad_spot(word: String) -> Vector3:
	for i in _pads.size():
		if _pads[i].word == word:
			return to_global(Vector3(PAD_POS[i].x, 0.3, PAD_POS[i].y))
	return global_position


func start_spot() -> Vector3:
	return to_global(Vector3(0, 0.3, 7.5))


func is_listening() -> bool:
	return _state == "dancing"


func _process(delta: float) -> void:
	_t += delta
	_cool -= delta
	var star := get_node_or_null("StartStar")
	if star:
		star.rotation.y += delta * 1.5
		star.visible = not done and _state == "idle"
	# The lights dance to an imaginary beat.
	for i in _lights.size():
		_lights[i].scale = Vector3.ONE * (1.0 + 0.25 * maxf(0.0, sin(_t * 6.0 + i * 0.9)))
	# Pads fade back down after flashing.
	for p in _pads:
		var m: StandardMaterial3D = p.mat
		m.emission_energy_multiplier = maxf(0.0, m.emission_energy_multiplier - delta * 2.5)


func _on_start(body: Node) -> void:
	if done or _state != "idle" or _cool > 0 or Game.ui_open or not body.is_in_group("player"):
		return
	var rounds: Array = reto.get("rounds", DEFAULT_ROUNDS)
	_seq = rounds[round_i]
	_step = 0
	_state = "showing"
	_show_sequence(round_i == rounds.size() - 1)


func _show_sequence(words_only: bool) -> void:
	var rounds: Array = reto.get("rounds", DEFAULT_ROUNDS)
	Game.show_toast("Ronda %d / %d - %s" % [round_i + 1, rounds.size(), "¡Solo en español! Listen carefully..." if words_only else "¡Escucha y mira!"])
	_dj_label.text = "¡Escucha!"
	await get_tree().create_timer(1.2).timeout
	var said := PackedStringArray()
	for w in _seq:
		var i := _index(str(w))
		said.append(str(w).to_upper())
		_dj_label.text = "¡%s!" % str(w).to_upper()
		Game.sfx("click", 0.8 + i * 0.2, -2)
		if not words_only:
			(_pads[i].mat as StandardMaterial3D).emission_energy_multiplier = 1.6
		await get_tree().create_timer(0.9).timeout
	_dj_label.text = "¡Ahora tú!\n" + " - ".join(said) if round_i == 0 else "¡Ahora tú!"
	_state = "dancing"


func _on_pad(body: Node, i: int) -> void:
	if not body.is_in_group("player"):
		return
	(_pads[i].mat as StandardMaterial3D).emission_energy_multiplier = 1.2
	if _state != "dancing":
		return
	var want := _index(str(_seq[_step]))
	if i != want:
		_state = "idle"
		_cool = 1.0
		Game.sfx("wrong")
		_dj_label.text = "¡Uy! Era el %s." % _pads[want].word
		Game.show_toast("¡Uy! That was %s - the DJ wanted %s. Step on the star to try again." % [_pads[i].word, _pads[want].word])
		return
	Game.sfx("click", 0.8 + i * 0.2)
	_step += 1
	if _step < _seq.size():
		return
	# Round complete!
	var rounds: Array = reto.get("rounds", DEFAULT_ROUNDS)
	round_i += 1
	_state = "idle"
	Game.sfx("correct")
	if round_i >= rounds.size():
		done = true
		_dj_label.text = "¡Bailas genial!"
		Game.show_toast("¡Fantástico! You danced every round - a sweet has appeared on the stage!")
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	_dj_label.text = "¡Muy bien!\nPisa la estrella."
	Game.show_toast("¡Muy bien! Round %d done - step on the star for the next one." % round_i)


func _index(word: String) -> int:
	for i in _pads.size():
		if _pads[i].word == word:
			return i
	return 0


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


func _label(parent: Node3D, text: String, size: int, pos: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 16
	l.modulate = col
	l.outline_modulate = Color(0.3, 0.1, 0.4)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
