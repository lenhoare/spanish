extends Node3D
## "La cinta transportadora": things roll along a conveyor belt, each with its Spanish name
## floating above it (un botiquín, una sartén...). Four big job pads stand in front of the belt.
## When a thing reaches the scanner in the middle, it's sent to the job whose pad you're
## standing on. Send enough things to the right jobs and the sweet appears.
## The belt runs along local +X; the pads are in front of it (+Z, towards the island's middle).

const BELT_Z := -2.5
const SPEED := 1.5
const START_X := -8.0
const SCAN_X := 0.0
const GAP := 4.0            # seconds between things
const PAD_POS := [Vector2(-2.6, 1.6), Vector2(2.6, 1.6), Vector2(-2.6, 5.4), Vector2(2.6, 5.4)]
const PAD_COLS := [Color(0.95, 0.35, 0.4), Color(1.0, 0.7, 0.2), Color(0.35, 0.6, 1.0), Color(0.4, 0.8, 0.45)]

var reto: Dictionary
var sweet: Node3D
var done := false
var sorted := 0

var _items: Array = []      # [{node, job, name, label}]
var _next := 1.5
var _order: Array = []
var _k := 0
var _count_label: Label3D
var _pad_mats: Array = []
var _rng := RandomNumberGenerator.new()


func need() -> int:
	return int(reto.get("need", 6))


func jobs() -> Array:
	return reto.get("jobs", [])


func setup(r: Dictionary) -> void:
	reto = r
	_rng.randomize()
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	_flat(Vector3(20.0, 0.04, 13.0), Vector3(0, 0.02, 1.0), Props.mat(Color(0.55, 0.57, 0.62)))
	# The belt (visual), on a solid base you can't walk through.
	for k in 9:
		var seg := Props.model("conveyor/conveyor-long-stripe-sides")
		seg.scale = Vector3.ONE * 1.0
		seg.position = Vector3(-8.0 + k * 2.0, 0.6, BELT_Z)
		add_child(seg)
	_solid(body, Vector3(18.0, 0.6, 1.0), Vector3(0, 0.3, BELT_Z), Props.mat(Color(0.3, 0.32, 0.38)))
	_solid(body, Vector3(18.0, 0.9, 0.1), Vector3(0, 0.45, BELT_Z + 0.55), Props.mat(Color(1.0, 0.8, 0.2)))   # keeps you off the belt
	var scanner := Props.model("conveyor/scanner-high")
	scanner.scale = Vector3.ONE * 1.6
	scanner.position = Vector3(SCAN_X, 0.6, BELT_Z)
	scanner.rotation.y = PI / 2
	add_child(scanner)
	var arm := Props.model("conveyor/robot-arm-a")
	arm.scale = Vector3.ONE * 2.0
	arm.position = Vector3(6.5, 0.6, BELT_Z - 1.6)
	add_child(arm)
	_label(self, str(r.get("sign", "La fábrica de trabajos")), 80, Vector3(0, 4.6, BELT_Z - 0.5), Color(1, 0.85, 0.3))
	_count_label = _label(self, "", 56, Vector3(0, 3.6, BELT_Z - 0.5), Color.WHITE)
	# The job pads, each with a big label and a bin at the back.
	var js := jobs()
	for i in mini(js.size(), PAD_POS.size()):
		var m := StandardMaterial3D.new()
		m.albedo_color = PAD_COLS[i].darkened(0.3)
		m.emission_enabled = true
		m.emission = PAD_COLS[i]
		m.emission_energy_multiplier = 0.0
		var pad := _mesh(self, _box(Vector3(2.8, 0.14, 2.8)), Vector3(PAD_POS[i].x, 0.07, PAD_POS[i].y), m)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_pad_mats.append(m)
		var l := _label(self, str(js[i].job), 64, Vector3(PAD_POS[i].x, 0.9, PAD_POS[i].y + 1.2), PAD_COLS[i].lightened(0.3))
		l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_refresh()


func pad_spot(job_i: int) -> Vector3:
	return to_global(Vector3(PAD_POS[job_i].x, 0.3, PAD_POS[job_i].y))


func sweet_spot() -> Vector3:
	return to_global(Vector3(-8.5, 1.4, 1.0))


## The first thing still heading for the scanner: [name, job index] (for the test).
func next_item():
	for it in _items:
		if (it.node as Node3D).position.x < SCAN_X:
			return it
	return null


func _physics_process(delta: float) -> void:
	# Pads light up under your feet.
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var on := _pad_under(player)
	for i in _pad_mats.size():
		(_pad_mats[i] as StandardMaterial3D).emission_energy_multiplier = 0.9 if i == on else 0.0
	if done or Game.ui_open:
		return
	# New things arrive while someone is nearby.
	var near := player != null and to_local(player.global_position).length() < 16.0
	_next -= delta
	if near and _next <= 0:
		_next = GAP
		_spawn()
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		var n: Node3D = it.node
		var before := n.position.x
		n.position.x += SPEED * delta
		n.rotation.y += delta
		(it.label as Label3D).position = n.position + Vector3(0, 1.4, 0)
		if before < SCAN_X and n.position.x >= SCAN_X:
			_scan(it, on)
		if n.position.x > 9.0:
			n.queue_free()
			(it.label as Node3D).queue_free()
			_items.remove_at(i)


func _spawn() -> void:
	# Go through every thing in a shuffled order, then shuffle again.
	if _order.is_empty() or _k >= _order.size():
		_order.clear()
		var js := jobs()
		for j in js.size():
			for t in js[j].items:
				_order.append([t, j])
		_order.shuffle()
		_k = 0
	var pick: Array = _order[_k]
	_k += 1
	var t: Array = pick[0]
	var n := Props.model(str(t[1]))
	n.scale = Vector3.ONE * float(t[2]) if t.size() > 2 else Vector3.ONE * 3.0
	n.position = Vector3(START_X, 1.0, BELT_Z)
	add_child(n)
	var l := _label(self, str(t[0]), 52, n.position + Vector3(0, 1.4, 0), Color.WHITE)
	_items.append({"node": n, "job": int(pick[1]), "name": str(t[0]), "label": l})


func _scan(it: Dictionary, on: int) -> void:
	var js := jobs()
	var right: String = str(js[it.job].job)
	var l: Label3D = it.label
	if on < 0:
		Game.sfx("click", 0.8)
		l.text = "¿Para quién?"
		l.modulate = Color(1, 0.8, 0.5)
		return
	if on == it.job:
		sorted += 1
		Game.sfx("correct", 1.0 + sorted * 0.05)
		l.text = "¡Para el %s!" % right
		l.modulate = Color(0.6, 1.0, 0.6)
		var n: Node3D = it.node
		var t := create_tween()
		t.tween_property(n, "position", Vector3(PAD_POS[on].x, 2.5, PAD_POS[on].y - 1.0), 0.35)
		t.tween_property(n, "scale", Vector3.ONE * 0.01, 0.2)
		_refresh()
		if sorted >= need():
			_finish()
		return
	Game.sfx("wrong", 1.2)
	l.text = "No: %s → %s" % [str(it.name), right]
	l.modulate = Color(1, 0.55, 0.5)
	Game.show_toast("¡Uy! %s es para el %s." % [str(it.name).capitalize(), right])


func _finish() -> void:
	done = true
	Game.sfx("win", 1.2)
	Game.show_toast("¡Excelente! Everything went to the right job - a sweet has appeared by the belt!")
	_count_label.text = "¡Terminado!"
	for it in _items:
		(it.node as Node3D).queue_free()
		(it.label as Node3D).queue_free()
	_items.clear()
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	_count_label.text = "%d / %d" % [sorted, need()]


func _pad_under(player: Node3D) -> int:
	if not player:
		return -1
	var lp := to_local(player.global_position)
	for i in mini(jobs().size(), PAD_POS.size()):
		if absf(lp.x - PAD_POS[i].x) < 1.4 and absf(lp.z - PAD_POS[i].y) < 1.4 and lp.y < 2.0:
			return i
	return -1


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
	l.outline_modulate = Color(0.15, 0.15, 0.25)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
