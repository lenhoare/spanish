extends Node3D
## "Sin señal": the island has lost its signal. Climb three antenna towers (a spiral of little
## platforms around a mast) and touch the switch at the top of each one. When all three are
## connected, the big phone in the plaza lights up and the sweet appears.
## Lives at the world origin; towers and the hub are placed in world coordinates.

const STEPS := 8
const STEP_RISE := 1.15
const STEP_R := 2.05

var sweet: Node3D
var connected: Array[bool] = []
var done := false

var _lights: Array[MeshInstance3D] = []
var _hub_label: Label3D
var _hub_screen: StandardMaterial3D
var _hub_help: Label3D
var _cool := 0.0


func setup(towers: Array, hub: Vector3) -> void:
	for i in towers.size():
		_tower(towers[i], i)
		connected.append(false)
	_build_hub(hub)


func top_of(i: int) -> Vector3:
	return _lights[i].get_parent().to_global(Vector3(0, _top_y() + 0.3, 0))


func sweet_spot(hub: Vector3) -> Vector3:
	return hub + (-hub.normalized()) * 1.9 + Vector3(0, 1.3, 0)


func _top_y() -> float:
	return STEPS * STEP_RISE + 0.5


func _process(delta: float) -> void:
	_cool -= delta
	for i in _lights.size():
		var l := _lights[i]
		l.scale = Vector3.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.006 + i))


## A mast with a spiral of platforms, a dish, and a switch pad on top.
func _tower(pos: Vector3, i: int) -> void:
	var t := Node3D.new()
	add_child(t)
	t.position = pos
	var metal := Props.mat(Color(0.75, 0.75, 0.85))
	var pad_mat := Props.mat(Color(0.3, 0.9, 1.0))
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	t.add_child(body)
	var top := _top_y()
	# The mast.
	var mast := CylinderMesh.new()
	mast.top_radius = 0.25
	mast.bottom_radius = 0.45
	mast.height = top
	_mesh(body, mast, Vector3(0, mast.height / 2.0, 0), metal)
	var mcs := CollisionShape3D.new()
	var msh := CylinderShape3D.new()
	msh.radius = 0.4
	msh.height = mast.height
	mcs.shape = msh
	mcs.position.y = mast.height / 2.0
	body.add_child(mcs)
	# Spiral steps.
	for k in STEPS:
		var a := k * 0.9 + i * 1.3
		var p := Vector3(cos(a) * STEP_R, (k + 1) * STEP_RISE - 0.15, sin(a) * STEP_R)
		_solid(body, Vector3(1.3, 0.3, 1.3), p, pad_mat if k % 2 == 0 else Props.mat(Color(0.95, 0.4, 0.8)))
	# A round platform at the top (no railings - it's a game!).
	var plat := CylinderMesh.new()
	plat.top_radius = 1.35
	plat.bottom_radius = 1.35
	plat.height = 0.3
	_mesh(body, plat, Vector3(0, top, 0), Props.mat(Color(0.35, 0.3, 0.6)))
	var pcs := CollisionShape3D.new()
	var psh := CylinderShape3D.new()
	psh.radius = 1.35
	psh.height = 0.3
	pcs.shape = psh
	pcs.position.y = top
	body.add_child(pcs)
	# A little aerial at the back with a dish and a light that turns green when connected.
	var pole := CylinderMesh.new()
	pole.top_radius = 0.07
	pole.bottom_radius = 0.1
	pole.height = 2.4
	_mesh(t, pole, Vector3(0.95, top + 1.2, -0.6), metal)
	var dish := CylinderMesh.new()
	dish.top_radius = 0.7
	dish.bottom_radius = 0.2
	dish.height = 0.3
	var dm := _mesh(t, dish, Vector3(0.95, top + 1.9, -0.45), Props.mat(Color(0.95, 0.95, 1.0)))
	dm.rotation.z = -0.9
	var light := SphereMesh.new()
	light.radius = 0.35
	light.height = 0.7
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(1.0, 0.3, 0.35)
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.25, 0.3)
	lm.emission_energy_multiplier = 1.5
	light.material = lm
	var li := MeshInstance3D.new()
	li.mesh = light
	li.position = Vector3(0.95, top + 2.6, -0.6)
	t.add_child(li)
	_lights.append(li)
	var label := _label(t, "Antena %d\n¡Sin señal!" % (i + 1), Vector3(0, top + 3.7, 0), Color(1, 0.6, 0.7))
	label.set_meta("tower", i)
	li.set_meta("label", label)
	# The switch: touch the middle of the top platform.
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.9
	sh.height = 1.6
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(0, top + 1.0, 0)
	t.add_child(area)
	area.body_entered.connect(_on_switch.bind(i))
	var sw := CylinderMesh.new()
	sw.top_radius = 0.55
	sw.bottom_radius = 0.6
	sw.height = 0.12
	_mesh(t, sw, Vector3(0, top + 0.2, 0), Props.mat(Color(1.0, 0.85, 0.2)))


func _on_switch(body: Node, i: int) -> void:
	if connected[i] or not body.is_in_group("player"):
		return
	connected[i] = true
	var li := _lights[i]
	var m := (li.mesh as SphereMesh).material as StandardMaterial3D
	m.albedo_color = Color(0.4, 1.0, 0.5)
	m.emission = Color(0.3, 1.0, 0.45)
	var lbl: Label3D = li.get_meta("label")
	lbl.text = "Antena %d\n¡Conectada!" % (i + 1)
	lbl.modulate = Color(0.6, 1.0, 0.6)
	var n := connected.count(true)
	Game.sfx("correct")
	_hub_label.text = "Señal: %d / %d" % [n, connected.size()]
	if n < connected.size():
		Game.show_toast("¡Conectada! Antena %d. %d / %d - find the other towers!" % [i + 1, n, connected.size()])
		return
	done = true
	Game.sfx("win", 1.2)
	Game.show_toast("¡Todo conectado! The big phone in the plaza has a signal - a sweet is waiting there!")
	_hub_label.text = "¡Conectado!"
	_hub_label.modulate = Color(0.6, 1.0, 0.6)
	_hub_screen.albedo_color = Color(0.7, 1.0, 0.8)
	_hub_screen.emission = Color(0.5, 1.0, 0.7)
	_hub_help.text = "¡Conectado!"
	_hub_help.modulate = Color(0.2, 0.55, 0.3)
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## The plaza: a giant phone standing on a plinth. No signal until the towers are connected.
func _build_hub(pos: Vector3) -> void:
	var h := Node3D.new()
	add_child(h)
	h.position = pos
	h.rotation.y = atan2(-pos.x, -pos.z)     # screen faces the middle of the island
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	h.add_child(body)
	_solid(body, Vector3(3.2, 0.5, 1.6), Vector3(0, 0.25, 0), Props.mat(Color(0.35, 0.3, 0.6)))
	_solid(body, Vector3(2.2, 4.0, 0.35), Vector3(0, 2.5, 0), Props.mat(Color(0.15, 0.13, 0.25)))
	_hub_screen = StandardMaterial3D.new()
	_hub_screen.albedo_color = Color(0.45, 0.45, 0.6)
	_hub_screen.emission_enabled = true
	_hub_screen.emission = Color(0.35, 0.35, 0.5)
	_hub_screen.emission_energy_multiplier = 0.9
	_mesh(h, _box(Vector3(1.9, 3.5, 0.02)), Vector3(0, 2.5, 0.19), _hub_screen)
	_hub_label = _label(h, "Señal: 0 / 3", Vector3(0, 5.3, 0), Color(1, 0.6, 0.7))
	_hub_label.font_size = 64
	_hub_help = _label(h, "¡Sin señal!\nConecta las 3 antenas", Vector3(0, 2.8, 0.25), Color.WHITE)
	_hub_help.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_hub_help.font_size = 40


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


func _label(parent: Node3D, text: String, pos: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = 52
	l.pixel_size = 0.006
	l.outline_size = 14
	l.modulate = col
	l.outline_modulate = Color(0.2, 0.15, 0.4)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
