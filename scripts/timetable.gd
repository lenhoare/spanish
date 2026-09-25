extends Node3D
## "El horario": a timetable board, a school bell and four classrooms.
## Ring the bell: it tells you the day and time IN SPANISH ("Es martes. Son las once.").
## Read the timetable, work out which lesson you have, and run into that classroom
## before the clock runs out. Three rounds in a row wins the sweet.
## Faces local +Z (towards the middle of the island); the classrooms are behind (-Z).

signal finished

const TIME_LIMIT := 25.0
const ROOM_COLORS := [Color(0.95, 0.45, 0.45), Color(0.45, 0.65, 0.95), Color(0.55, 0.8, 0.45), Color(0.95, 0.75, 0.3)]

var reto: Dictionary
var sweet: Node3D
var done := false
var round_i := 0
var running := false
var time_left := 0.0

var _prompt: Label3D
var _cool := 0.0
var _nag := 0.0
var _rooms := {}        # subject -> Area3D


func setup(r: Dictionary) -> void:
	reto = r
	var subjects: Array = r.get("rooms", ["química", "historia", "dibujo", "informática"])
	# Classrooms in a row behind the board.
	for i in subjects.size():
		var x := -9.0 + i * 6.0
		_classroom(Vector3(x, 0, -4.5), str(subjects[i]), ROOM_COLORS[i % ROOM_COLORS.size()])
	# The timetable board.
	var board := StaticBody3D.new()
	board.add_to_group("solid_ground")
	add_child(board)
	board.position = Vector3(-3.5, 0, 3.0)
	var frame := _mesh(board, _box(Vector3(7.8, 3.6, 0.2)), Vector3(0, 2.4, 0), Props.mat(Color(0.3, 0.45, 0.35)))
	for x in [-3.7, 3.7]:
		_mesh(board, _box(Vector3(0.2, 2.4, 0.2)), Vector3(x, 0.6, 0), Props.mat(Color(0.5, 0.35, 0.25)))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(7.8, 4.2, 0.3)
	cs.shape = sh
	cs.position.y = 2.1
	board.add_child(cs)
	var title := _label(board, "EL HORARIO", 72, Vector3(0, 3.8, 0.12), Color(1, 0.95, 0.6))
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# One column per day: the day on top, then its lessons.
	var days: Array = r.get("timetable", [])
	for i in days.size():
		var row: Array = days[i]
		var x := (i - (days.size() - 1) / 2.0) * 2.6
		var day := _label(board, str(row[0]).to_upper(), 46, Vector3(x, 3.0, 0.12), Color(1, 0.85, 0.5))
		day.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		var tt := _label(board, "\n".join(PackedStringArray(row.slice(1))), 40, Vector3(x, 1.95, 0.12), Color.WHITE)
		tt.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		tt.line_spacing = 14
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# The bell on a post.
	var bell_post := StaticBody3D.new()
	add_child(bell_post)
	bell_post.position = Vector3(3.5, 0, 3.0)
	_mesh(bell_post, _box(Vector3(0.25, 2.6, 0.25)), Vector3(0, 1.3, 0), Props.mat(Color(0.5, 0.35, 0.25)))
	var bell := CylinderMesh.new()
	bell.top_radius = 0.2
	bell.bottom_radius = 0.45
	bell.height = 0.6
	_mesh(bell_post, bell, Vector3(0, 2.9, 0), Props.mat(Color(1.0, 0.8, 0.2)))
	var bcs := CollisionShape3D.new()
	var bsh := CylinderShape3D.new()
	bsh.radius = 0.3
	bsh.height = 3.2
	bcs.shape = bsh
	bcs.position.y = 1.6
	bell_post.add_child(bcs)
	_prompt = _label(self, "¡Toca el timbre!", 52, Vector3(3.5, 4.1, 3.0), Color(1, 0.9, 0.4))
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := CylinderShape3D.new()
	ash.radius = 1.4
	ash.height = 2.5
	acs.shape = ash
	area.add_child(acs)
	area.position = Vector3(3.5, 1.2, 3.0)
	add_child(area)
	area.body_entered.connect(_on_bell)


func sweet_spot() -> Vector3:
	return to_global(Vector3(3.5, 0.2, 4.6))


func _physics_process(delta: float) -> void:
	_cool -= delta
	_nag -= delta
	if not running or Game.ui_open:
		return
	time_left -= delta
	get_tree().call_group("hud", "set_timer", time_left)
	if time_left <= 0:
		running = false
		round_i = 0
		_cool = 1.0
		get_tree().call_group("hud", "set_timer", -1.0)
		Game.sfx("wrong", 0.9)
		Game.show_toast("¡Llegas tarde! Too late - ring the bell to start again.")
		_prompt.text = "¡Toca el timbre!"


func _on_bell(body: Node) -> void:
	if done or running or _cool > 0 or Game.ui_open or not body.is_in_group("player"):
		return
	var rounds: Array = reto.get("rounds", [])
	var rd: Dictionary = rounds[round_i]
	running = true
	time_left = TIME_LIMIT
	Game.sfx("win", 1.6, -4)
	_prompt.text = "%s\n¿Qué clase tienes?" % rd.say
	Game.show_toast("¡Riiing! %s ¡Corre a tu clase! (%d / %d)" % [rd.say, round_i + 1, rounds.size()])


func _on_room(body: Node, subject: String) -> void:
	if done or not running or not body.is_in_group("player"):
		return
	var rounds: Array = reto.get("rounds", [])
	var rd: Dictionary = rounds[round_i]
	if Game.strip_accents(subject) != Game.strip_accents(str(rd.answer)):
		if _nag <= 0:
			_nag = 1.5
			Game.sfx("wrong", 1.2, -4)
			Game.show_toast("¡Uy! Esta es la clase de %s. Check the timetable!" % subject)
		return
	running = false
	round_i += 1
	get_tree().call_group("hud", "set_timer", -1.0)
	Game.sfx("correct")
	if round_i >= rounds.size():
		done = true
		_prompt.text = "¡Muy puntual!"
		Game.show_toast("¡Perfecto! Always on time - a sweet has appeared by the bell!")
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		finished.emit()
	else:
		_prompt.text = "¡Toca el timbre!"
		Game.show_toast("¡Muy bien! Tienes %s. Ring the bell again! (%d / %d)" % [subject, round_i, rounds.size()])


# ---------------------------------------------------------------- pieces

## A little classroom: coloured walls, a roof, an open doorway facing the board, a subject sign.
func _classroom(pos: Vector3, subject: String, col: Color) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	body.position = pos
	var wall := Props.mat(col)
	var cream := Props.mat(Color(1, 0.96, 0.88))
	_solid(body, Vector3(4.4, 3.0, 0.3), Vector3(0, 1.5, -2.0), wall)          # back
	_solid(body, Vector3(0.3, 3.0, 4.3), Vector3(-2.1, 1.5, 0), wall)          # sides
	_solid(body, Vector3(0.3, 3.0, 4.3), Vector3(2.1, 1.5, 0), wall)
	_solid(body, Vector3(1.3, 3.0, 0.3), Vector3(-1.55, 1.5, 2.0), cream)       # front, with a doorway
	_solid(body, Vector3(1.3, 3.0, 0.3), Vector3(1.55, 1.5, 2.0), cream)
	_solid(body, Vector3(1.9, 0.7, 0.3), Vector3(0, 2.65, 2.0), cream)
	_solid(body, Vector3(4.8, 0.3, 4.8), Vector3(0, 3.15, 0), Props.mat(col.darkened(0.35)))  # roof
	# A little desk and chair inside, so it looks like a classroom.
	_mesh(body, _box(Vector3(1.2, 0.08, 0.7)), Vector3(0, 0.75, -0.6), Props.mat(Color(0.7, 0.5, 0.32)))
	_mesh(body, _box(Vector3(1.8, 1.0, 0.05)), Vector3(0, 1.8, -1.8), Props.mat(Color(0.2, 0.3, 0.25)))
	var sign := _label(body, subject.capitalize(), 64, Vector3(0, 3.8, 2.1), Color.WHITE)
	sign.outline_modulate = col.darkened(0.5)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.6, 2.5, 3.2)
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(0, 1.25, 0.2)
	body.add_child(area)
	area.body_entered.connect(_on_room.bind(subject))


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
	l.outline_size = 14
	l.modulate = col
	l.outline_modulate = Color(0.2, 0.2, 0.35)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
