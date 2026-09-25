extends Node3D
## "¿Dónde está?": a little town. A guide at the tourist office gives directions in Spanish
## (sigue todo recto, toma la segunda calle a la izquierda...). Gift boxes wait at the ends of
## the streets - follow the directions to the right one. Three rounds, then a sweet.
## Local frame: the main street runs along -Z from the plaza (z=+12) where the guide stands,
## facing down it; so "a la derecha" is +X and "a la izquierda" is -X.

const STREET_Z := [3.5, -4.5]          # first and second cross streets
const BLOCKS := {                       # name -> [x centre, z centre, colour]
	"banco": [4.0, 7.6, Color(0.55, 0.7, 0.95)],
	"farmacia": [-4.0, 7.6, Color(0.55, 0.9, 0.6)],
	"cine": [4.0, -0.5, Color(0.95, 0.45, 0.5)],
	"panadería": [-4.0, -0.5, Color(0.98, 0.8, 0.45)],
	"museo": [4.0, -8.6, Color(0.8, 0.7, 0.95)],
	"iglesia": [-4.0, -8.6, Color(0.95, 0.92, 0.85)],
}
const BOXES := {                        # label -> local position
	"A": Vector3(5.2, 0, 3.5), "B": Vector3(-5.2, 0, 3.5),
	"C": Vector3(5.2, 0, -4.5), "D": Vector3(-5.2, 0, -4.5),
	"E": Vector3(0, 0, -10.5),
}

var reto: Dictionary
var sweet: Node3D
var done := false
var round_i := -1                 # -1: not started (talk to the guide)

var _guide_label: Label3D
var _boxes := {}                  # label -> Node3D
var _cool := 0.0
var read := Callable()          # (title, markdown) -> shows a text panel (set by the world)


func setup(r: Dictionary) -> void:
	reto = r
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	# Streets: the main street and two cross streets, with white centre dashes.
	var road := Props.mat(Color(0.35, 0.36, 0.42))
	var white := Props.mat(Color(0.95, 0.95, 0.95))
	_flat(Vector3(3.2, 0.04, 26.0), Vector3(0, 0.02, 0), road)
	for z in STREET_Z:
		_flat(Vector3(12.4, 0.04, 3.0), Vector3(0, 0.021, z), road)
	for k in 9:
		_flat(Vector3(0.18, 0.01, 1.2), Vector3(0, 0.045, 11.0 - k * 2.8), white)
	_flat(Vector3(6.0, 0.04, 3.0), Vector3(0, 0.02, 12.5), Props.mat(Color(0.85, 0.75, 0.6)))   # the plaza
	# Buildings, each with a door onto the main street and a big name sign.
	for n in BLOCKS:
		var b: Array = BLOCKS[n]
		_building(body, str(n), Vector3(b[0], 0, b[1]), b[2])
	# A fountain at the end of the main street.
	var basin := CylinderMesh.new()
	basin.top_radius = 1.3
	basin.bottom_radius = 1.4
	basin.height = 0.6
	_mesh(body, basin, Vector3(0, 0.3, -12.6), Props.mat(Color(0.8, 0.8, 0.85)))
	var water := CylinderMesh.new()
	water.top_radius = 1.1
	water.bottom_radius = 1.1
	water.height = 0.05
	_mesh(body, water, Vector3(0, 0.58, -12.6), Props.mat(Color(0.4, 0.75, 1.0)))
	_mesh(body, _cyl(0.2, 1.6), Vector3(0, 1.0, -12.6), Props.mat(Color(0.8, 0.8, 0.85)))
	var fcs := CollisionShape3D.new()
	var fsh := CylinderShape3D.new()
	fsh.radius = 1.4
	fsh.height = 0.7
	fcs.shape = fsh
	fcs.position = Vector3(0, 0.35, -12.6)
	body.add_child(fcs)
	_label(self, "la fuente", 48, Vector3(0, 2.3, -12.6), Color(0.7, 0.9, 1.0))
	# The gift boxes.
	var cols := [Color(1.0, 0.45, 0.55), Color(0.45, 0.7, 1.0), Color(1.0, 0.8, 0.3), Color(0.5, 0.85, 0.55), Color(0.8, 0.55, 1.0)]
	var i := 0
	for k in BOXES:
		_boxes[k] = _gift(BOXES[k], cols[i % cols.size()], str(k))
		i += 1
	# The guide at the tourist office on the plaza.
	var stall := Props.model("fair/stall-information")
	stall.scale = Vector3.ONE * 2.4
	stall.position = Vector3(3.2, 0, 13.2)
	stall.rotation.y = PI
	add_child(stall)
	var guide := Props.character(str(r.get("character", "character-female-b")))
	guide.scale = Vector3.ONE * 1.7
	guide.position = Vector3(0, 0, 13.4)
	guide.rotation.y = PI       # facing down the main street, like you
	add_child(guide)
	var anims := guide.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		(anims[0] as AnimationPlayer).get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		(anims[0] as AnimationPlayer).play("idle")
	_label(self, "Oficina de turismo", 60, Vector3(3.2, 4.6, 13.2), Color(1, 0.9, 0.4))
	_guide_label = _label(self, str(r.get("greeting", "¡Hola! ¿Buscas los regalos?\nHabla conmigo.")), 46, Vector3(0, 4.4, 14.0), Color.WHITE)
	_guide_label.font_size = 40
	_guide_label.width = 700
	_guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.8
	sh.height = 2.5
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(0, 1.2, 12.4)
	add_child(area)
	area.body_entered.connect(_on_guide)


func sweet_spot() -> Vector3:
	return to_global(Vector3(-1.6, 1.2, 12.0))


func guide_spot() -> Vector3:
	return to_global(Vector3(0, 0.3, 11.8))


func box_spot(label: String) -> Vector3:
	return to_global(BOXES[label] + Vector3(0, 0.3, 0))


func current_box() -> String:
	var rounds: Array = reto.get("rounds", [])
	return str(rounds[round_i].box) if round_i >= 0 and round_i < rounds.size() else ""


func _process(delta: float) -> void:
	_cool -= delta
	for k in _boxes:
		var b: Node3D = _boxes[k]
		if b.visible:
			b.get_child(0).rotation.y += delta * 0.8


func _on_guide(body: Node) -> void:
	if done or not body.is_in_group("player"):
		return
	if round_i < 0:
		round_i = 0
	_say_round()


func _say_round() -> void:
	if Game.ui_open or _cool > 0:
		return
	_cool = 1.0
	var rounds: Array = reto.get("rounds", [])
	var rd: Dictionary = rounds[round_i]
	_guide_label.text = "Regalo %d / %d" % [round_i + 1, rounds.size()]
	Game.sfx("click")
	if read.is_valid():
		read.call("La guía (%d / %d)" % [round_i + 1, rounds.size()], "## %s\n\n*Start here, facing down the main street.*" % rd.say)
	else:
		Game.show_toast("La guía: \"%s\"" % rd.say)


func _on_box(body: Node, label: String) -> void:
	if done or _cool > 0 or not body.is_in_group("player"):
		return
	var b: Node3D = _boxes[label]
	if not b.visible:
		return
	_cool = 1.0
	if round_i < 0:
		Game.sfx("click")
		Game.show_toast("Un regalo... ¿pero cuál? Talk to the guide at the tourist office first.")
		return
	if label != current_box():
		Game.sfx("wrong")
		Game.show_toast("¡Aquí no hay nada! Read the directions again - ask the guide if you need to.")
		var t := create_tween()
		t.tween_property(b, "rotation:z", 0.25, 0.08)
		t.tween_property(b, "rotation:z", -0.25, 0.12)
		t.tween_property(b, "rotation:z", 0.0, 0.08)
		return
	# The right one!
	Game.sfx("correct")
	var t := create_tween()
	t.tween_property(b, "scale", Vector3.ONE * 1.3, 0.12)
	t.tween_property(b, "scale", Vector3.ONE * 0.01, 0.2)
	t.tween_callback(func(): b.visible = false)
	var rounds: Array = reto.get("rounds", [])
	round_i += 1
	if round_i >= rounds.size():
		done = true
		_guide_label.text = "¡Muy bien! Ya conoces la ciudad."
		Game.show_toast("¡Perfecto! You found every present - a sweet is waiting at the tourist office!")
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	_guide_label.text = "¡Muy bien! Vuelve a la oficina de turismo."
	Game.show_toast("¡Muy bien! %d / %d. Go back to the guide for the next directions." % [round_i, rounds.size()])


# ---------------------------------------------------------------- pieces

func _building(body: StaticBody3D, name: String, c: Vector3, col: Color) -> void:
	var h := 4.2 if name != "museo" else 5.0
	var w := 3.6
	var d := 4.4
	_solid(body, Vector3(w, h, d), c + Vector3(0, h / 2.0, 0), Props.mat(col))
	_solid(body, Vector3(w + 0.4, 0.3, d + 0.4), c + Vector3(0, h + 0.15, 0), Props.mat(col.darkened(0.35)))
	var toward := -signf(c.x)                 # the side facing the main street
	var door_x := c.x + toward * (w / 2.0 + 0.02)
	var door := _mesh(body, _box(Vector3(0.05, 1.8, 1.1)), Vector3(door_x, 0.9, c.z), Props.mat(Color(0.45, 0.3, 0.22)))
	door.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for dz in [-1.3, 1.3]:
		for y in [1.4, 3.0]:
			_mesh(body, _box(Vector3(0.05, 0.8, 0.7)), Vector3(door_x, y, c.z + dz), Props.mat(Color(0.75, 0.9, 1.0)))
	if name == "iglesia":
		_solid(body, Vector3(1.8, 4.0, 1.8), c + Vector3(0, h + 2.0, -1.0), Props.mat(col))
		var spire := CylinderMesh.new()
		spire.top_radius = 0.0
		spire.bottom_radius = 1.3
		spire.height = 2.2
		spire.radial_segments = 4
		_mesh(body, spire, c + Vector3(0, h + 5.1, -1.0), Props.mat(Color(0.75, 0.4, 0.35)))
	var sign := _label(self, name.to_upper(), 64, c + Vector3(toward * (w / 2.0 + 0.9), h + 0.8, 0), Color.WHITE)
	sign.outline_modulate = col.darkened(0.55)


func _gift(pos: Vector3, col: Color, label: String) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	var g := Node3D.new()
	root.add_child(g)
	_mesh(g, _box(Vector3(0.9, 0.8, 0.9)), Vector3(0, 0.4, 0), Props.mat(col))
	_mesh(g, _box(Vector3(0.94, 0.82, 0.18)), Vector3(0, 0.4, 0), Props.mat(Color(1, 1, 1)))
	_mesh(g, _box(Vector3(0.18, 0.82, 0.94)), Vector3(0, 0.4, 0), Props.mat(Color(1, 1, 1)))
	_mesh(g, _box(Vector3(0.4, 0.2, 0.2)), Vector3(0, 0.9, 0), Props.mat(Color(1, 1, 1)))
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.9
	sh.height = 2.0
	cs.shape = sh
	area.add_child(cs)
	area.position.y = 1.0
	root.add_child(area)
	area.body_entered.connect(_on_box.bind(label))
	return root


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


func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


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
