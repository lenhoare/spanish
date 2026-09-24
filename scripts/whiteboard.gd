extends Node3D
## The big lesson whiteboard in the middle of the island. Jump at it to read.

signal touched

const W := 7.0
const H := 4.2
const BOTTOM := 1.3

var _cooldown := 0.0
var _area: Area3D
var _arrow: Label3D
var _t := 0.0


func setup(lesson: Dictionary) -> void:
	var frame_mat := Props.mat(Color(0.56, 0.45, 0.9))
	var leg_mat := Props.mat(Color(0.98, 0.62, 0.78))
	var board_mat := Props.mat(Color(0.98, 0.98, 1.0), false)

	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)

	_box(body, Vector3(W, H, 0.15), Vector3(0, BOTTOM + H / 2, 0), board_mat)
	# Chunky rounded frame
	for y in [BOTTOM - 0.15, BOTTOM + H + 0.15]:
		_box(body, Vector3(W + 0.6, 0.35, 0.4), Vector3(0, y, 0), frame_mat)
	for x in [-W / 2 - 0.15, W / 2 + 0.15]:
		_box(body, Vector3(0.35, H + 0.6, 0.4), Vector3(x, BOTTOM + H / 2, 0), frame_mat)
	# Legs with ball feet
	for x in [-W / 2 + 0.4, W / 2 - 0.4]:
		_box(body, Vector3(0.3, BOTTOM, 0.3), Vector3(x, BOTTOM / 2, 0), leg_mat)
		var ball := SphereMesh.new()
		ball.radius = 0.35
		ball.height = 0.7
		ball.material = leg_mat
		var bm := MeshInstance3D.new()
		bm.mesh = ball
		bm.position = Vector3(x, 0.2, 0)
		body.add_child(bm)
	# Pen tray
	_box(body, Vector3(W * 0.6, 0.1, 0.4), Vector3(0, BOTTOM + 0.05, 0.25), frame_mat)
	var pen_colors := [Color(0.9, 0.2, 0.3), Color(0.2, 0.5, 0.9), Color(0.2, 0.7, 0.35)]
	for i in 3:
		var pen := CylinderMesh.new()
		pen.top_radius = 0.05
		pen.bottom_radius = 0.05
		pen.height = 0.5
		pen.material = Props.mat(pen_colors[i])
		var pm := MeshInstance3D.new()
		pm.mesh = pen
		pm.rotation.z = PI / 2
		pm.position = Vector3(-0.8 + i * 0.7, BOTTOM + 0.16, 0.25)
		body.add_child(pm)

	var z := 0.09
	# Long titles shrink to stay on one line rather than wrapping into the subject.
	var tsize := 150 if lesson.title.length() <= 14 else maxi(70, int(150.0 * 14 / lesson.title.length()))
	var title := _label(lesson.title, tsize, Vector3(0, BOTTOM + H - 0.55, z), Color(0.88, 0.27, 0.48))
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.font = preload("res://scripts/ui.gd").ui_font(600)
	title.outline_size = 0
	if lesson.subject != "":
		_label(lesson.subject.to_upper(), 60, Vector3(0, BOTTOM + H - 1.15, z), Color(0.35, 0.31, 0.81)).outline_size = 0

	var lines := PackedStringArray()
	for i in lesson.pages.size():
		lines.append("%d.  %s" % [i + 1, lesson.pages[i].title])
	# Page list, anchored under the subject so long lists grow downwards, not over the title.
	var contents := _label("\n".join(lines), 64 if lines.size() <= 4 else 44, Vector3(0, BOTTOM + H - 1.5, z), Color(0.2, 0.2, 0.3))
	contents.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	contents.outline_size = 0
	contents.line_spacing = 6 if lines.size() <= 4 else 0
	var hint := _label("Jump at the board to read!", 64, Vector3(0, BOTTOM + 0.45, z), Color(0.2, 0.55, 0.45))
	hint.outline_size = 0

	# Bouncing arrow above the board so it's easy to spot from anywhere.
	_arrow = Label3D.new()
	_arrow.text = "LESSON"
	_arrow.font_size = 96
	_arrow.pixel_size = 0.008
	_arrow.outline_size = 24
	_arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_arrow.modulate = Color(1, 0.85, 0.3)
	_arrow.outline_modulate = Color(0.45, 0.25, 0.6)
	_arrow.position.y = BOTTOM + H + 1.3
	add_child(_arrow)

	# Zone just in front of the board. It only opens when the player JUMPS inside it,
	# so walking or running past doesn't grab you.
	_area = Area3D.new()
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(W + 0.6, 4.0, 2.4)
	cs.shape = s
	cs.position = Vector3(0, 2.0, 1.3)
	_area.add_child(cs)
	add_child(_area)


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if _arrow:
		_arrow.position.y = BOTTOM + H + 1.3 + sin(_t * 3.0) * 0.2


func rest() -> void:
	_cooldown = 1.0


func _physics_process(_delta: float) -> void:
	if not _area or Game.ui_open or _cooldown > 0:
		return
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player") and not body.is_on_floor() and body.velocity.y > 0.5:
			touched.emit()
			return


func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	parent.add_child(cs)


func _label(text: String, size: int, pos: Vector3, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = color
	l.position = pos
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = (W - 0.6) / l.pixel_size
	l.font = preload("res://scripts/ui.gd").ui_font(500)
	add_child(l)
	return l
