extends Node3D
## "La regata": a timed speedboat race right round the island through numbered buoy gates.
## Drive through gate 1 (the start) and the clock starts; go through every gate in order and
## back through the start before time runs out. The next gate glows. Win = a sweet on the jetty.
## Lives at the world origin.

const GATE_W := 12.0         # gap between a gate's two buoys
const PASS_R := 7.5

var boat: Node3D
var sweet: Node3D
var gates: Array[Vector3] = []
var buoys: Array[Vector3] = []   # every buoy (solid - the world adds them to the boat as blockers)
var time_limit := 70.0
var done := false
var running := false
var next_i := 0
var time_left := 0.0

var _arches: Array[MeshInstance3D] = []
var _labels: Array[Label3D] = []
var _glow: StandardMaterial3D
var _dim: StandardMaterial3D


func setup(points: Array[Vector3], limit: float) -> void:
	gates = points
	time_limit = limit
	_glow = StandardMaterial3D.new()
	_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow.albedo_color = Color(1.0, 0.85, 0.2, 0.75)
	_dim = StandardMaterial3D.new()
	_dim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dim.albedo_color = Color(1, 1, 1, 0.18)
	for i in gates.size():
		var g := gates[i]
		var along := (gates[(i + 1) % gates.size()] - gates[(i - 1 + gates.size()) % gates.size()]).normalized()
		var across := Vector3(-along.z, 0, along.x)
		for side in [-1.0, 1.0]:
			var b := Props.model("water/buoy-flag")
			b.scale = Vector3.ONE * 1.1
			b.position = g + across * side * GATE_W / 2.0 + Vector3(0, -0.3, 0)
			add_child(b)
			buoys.append(b.position)
		# A floating arch between the buoys (glows when it's the next gate).
		var arch := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = GATE_W / 2.0 - 0.25
		tm.outer_radius = GATE_W / 2.0
		tm.rings = 32
		arch.mesh = tm
		arch.material_override = _dim
		arch.position = g + Vector3(0, -0.4, 0)
		arch.basis = Basis.looking_at(along, Vector3.UP) * Basis(Vector3.RIGHT, PI / 2)   # the ring stands across the gate
		arch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arch)
		_arches.append(arch)
		var l := Label3D.new()
		l.text = "SALIDA" if i == 0 else str(i + 1)
		l.font = preload("res://scripts/ui.gd").ui_font(700)
		l.font_size = 130
		l.pixel_size = 0.01
		l.outline_size = 24
		l.modulate = Color.WHITE
		l.outline_modulate = Color(0.1, 0.25, 0.5)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = g + Vector3(0, 2.6, 0)
		add_child(l)
		_labels.append(l)
	_refresh()


func _physics_process(delta: float) -> void:
	if done or not boat or not is_instance_valid(boat):
		return
	if running and not Game.ui_open:
		time_left -= delta
		get_tree().call_group("hud", "set_timer", time_left)
		if time_left <= 0:
			running = false
			next_i = 0
			get_tree().call_group("hud", "set_timer", -1.0)
			Game.sfx("wrong", 0.9)
			Game.show_toast("¡Se acabó el tiempo! Out of time - go back through SALIDA to try again.")
			_refresh()
			return
	if boat.rider == null:
		return
	var bp := Vector2(boat.global_position.x, boat.global_position.z)
	var g := gates[next_i]
	if bp.distance_to(Vector2(g.x, g.z)) > PASS_R:
		return
	if not running:
		if next_i != 0:
			return
		running = true
		time_left = time_limit
		next_i = 1
		Game.sfx("win", 1.6, -4)
		Game.show_toast("¡Ya! Go round the island through every gate - %d seconds!" % int(time_limit))
		_refresh()
		return
	Game.sfx("correct", 1.0 + next_i * 0.05)
	if next_i == 0:
		# Back through the start: finished!
		done = true
		running = false
		get_tree().call_group("hud", "set_timer", -1.0)
		Game.sfx("win", 1.2)
		Game.show_toast("¡Campeón! You finished with %d seconds to spare - a sweet is waiting on the jetty!" % int(time_left))
		_refresh()
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	next_i = (next_i + 1) % gates.size()
	_refresh()


func _refresh() -> void:
	for i in _arches.size():
		var on := not done and i == next_i
		_arches[i].material_override = _glow if on else _dim
		_labels[i].modulate = Color(1, 0.9, 0.3) if on else Color(1, 1, 1, 0.6)
	if next_i == 0 and running:
		_labels[0].text = "¡META!"
	elif not running:
		_labels[0].text = "SALIDA"
