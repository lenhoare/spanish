extends Node3D
## "El muro de escalada": a tall climbing wall covered in coloured holds. Each section of the
## wall has a sign saying - in Spanish only - which colour to climb ("¡Solo el verde!"). Only
## holds of that colour are real; the others are just painted on, and you'll fall straight
## through them. Reach the top for the sweet. The wall faces local +Z.

const COLS := {"rojo": Color(0.95, 0.3, 0.3), "azul": Color(0.3, 0.55, 1.0), "verde": Color(0.35, 0.8, 0.4), "amarillo": Color(1.0, 0.85, 0.2)}
const XS := [-5.1, -1.7, 1.7, 5.1]    # far apart, so the next hold is never over your head
const STEP := 1.45           # height between holds (a single jump is 1.8)
const LEVELS := 9

var sweet: Node3D
var reto: Dictionary
var route: Array = []        # the real hold at each level: [x index, colour]

var _rng := RandomNumberGenerator.new()


func top_y() -> float:
	return STEP * LEVELS + 1.0      # the last step up onto the top is a small, easy one


func setup(r: Dictionary) -> void:
	reto = r
	_rng.seed = 2024
	var sections: Array = r.get("sections", ["verde", "azul", "rojo"])
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var h := top_y()
	_solid(body, Vector3(13.0, h, 1.2), Vector3(0, h / 2.0, -0.6), Props.mat(Color(0.75, 0.72, 0.8)))
	# The top of the wall is the landing (jump up from the last hold), with a little rail behind.
	_solid(body, Vector3(13.0, 0.3, 1.4), Vector3(0, top_y() + 0.15, -0.65), Props.mat(Color(0.55, 0.5, 0.65)))
	_solid(body, Vector3(13.0, 0.9, 0.15), Vector3(0, top_y() + 0.75, -1.3), Props.mat(Color(0.55, 0.5, 0.65)))
	# Soft crash mat at the bottom.
	var mat_m := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(13.0, 0.25, 3.0)
	mm.material = Props.mat(Color(0.3, 0.45, 0.85))
	mat_m.mesh = mm
	mat_m.position = Vector3(0, 0.12, 1.5)
	add_child(mat_m)
	# The holds: at each level one real hold (the section's colour, next to the one below) and
	# two decoys of other colours.
	var names: Array = COLS.keys()
	var x := _rng.randi_range(1, 2)
	for lv in LEVELS:
		var sec: String = sections[mini(lv * sections.size() / LEVELS, sections.size() - 1)]
		if lv > 0:
			x = clampi(x + [-1, 1][_rng.randi() % 2], 0, XS.size() - 1)
		route.append([x, sec])
		var y := STEP * (lv + 1)
		var others: Array = []
		for k in XS.size():
			if k != x:
				others.append(k)
		others.shuffle()
		_hold(body, Vector3(XS[x], y, 0.5), sec, true)
		for d in 2:
			var fake: String = names[_rng.randi() % names.size()]
			while fake == sec:
				fake = names[_rng.randi() % names.size()]
			_hold(null, Vector3(XS[others[d]], y, 0.5), fake, false)
		# A sign at the start of each section (words only - no colour clues!).
		if lv == 0 or sections[mini((lv - 1) * sections.size() / LEVELS, sections.size() - 1)] != sec:
			var sl := _label(self, "¡Solo el %s!" % sec, 64, Vector3(-7.8, y + 0.6, 0.4), Color.WHITE)
			sl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_label(self, str(r.get("sign", "El muro de escalada")), 90, Vector3(0, top_y() + 2.4, 0), Color(1, 0.85, 0.3))


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, top_y() + 1.2, -0.6))


func hold_spot(lv: int) -> Vector3:
	return to_global(Vector3(XS[route[lv][0]], STEP * (lv + 1) + 0.4, 0.6))


func _hold(body: StaticBody3D, pos: Vector3, colour: String, real: bool) -> void:
	var b := BoxMesh.new()
	b.size = Vector3(1.2, 0.3, 1.0)
	b.material = Props.mat(COLS[colour])
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	add_child(mi)
	if real:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = b.size
		cs.shape = sh
		cs.position = pos
		body.add_child(cs)


func _solid(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	parent.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	parent.add_child(cs)


func _label(parent: Node3D, text: String, size: int, pos: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 14
	l.modulate = col
	l.outline_modulate = Color(0.2, 0.2, 0.35)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
