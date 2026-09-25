extends Node3D
## "La excursión": a ring road round the island, school-trip places beside it (la biblioteca,
## el museo...), and classmates waiting at bus stops. Drive up to a stop and the classmate gets
## on and says (in Spanish) where they want to go; take them there. Everyone delivered = a
## sweet at the bus depot. Lives at the world origin.

const ROAD_W := 5.0
const STOP_R := 4.5
const DROP_R := 5.5

var bus: CharacterBody3D
var sweet: Node3D
var reto: Dictionary
var road_r := 40.5
var done := false
var round_i := 0
var delivered := 0

var _places := {}             # name -> [road point, building node]
var _stops: Array = []        # [{pos, who, say, to}]
var _kid: Node3D
var _kid_label: Label3D
var _stop_marker: Node3D
var _cool := 0.0


func setup(r: Dictionary, radius: float) -> void:
	reto = r
	road_r = radius
	# The road: a ring with dashed white centre lines.
	var road := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = road_r - ROAD_W / 2.0
	tm.outer_radius = road_r + ROAD_W / 2.0
	tm.rings = 96
	tm.ring_segments = 4
	tm.material = Props.mat(Color(0.38, 0.38, 0.44))
	road.mesh = tm
	road.scale.y = 0.02
	road.position.y = 0.02
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)
	var white := Props.mat(Color(0.95, 0.95, 0.95))
	for k in 60:
		var a := TAU * k / 60.0
		var dash := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.2, 0.02, 1.6)
		bm.material = white
		dash.mesh = bm
		dash.position = Vector3(cos(a), 0, sin(a)) * road_r + Vector3(0, 0.05, 0)
		dash.rotation.y = -a
		dash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dash)
	# The places, just inside the road.
	var cols := [Color(0.55, 0.7, 0.95), Color(0.8, 0.7, 0.95), Color(0.55, 0.85, 0.6), Color(0.95, 0.55, 0.55), Color(0.98, 0.8, 0.45)]
	var i := 0
	for p in r.get("places", []):
		var ang := deg_to_rad(float(p.at))
		var u := Vector3(cos(ang), 0, sin(ang))
		var b := _building(str(p.name), u * (road_r - ROAD_W / 2.0 - 3.2), ang, cols[i % cols.size()])
		_places[str(p.name)] = [u * road_r, b]
		i += 1
	# The depot where the bus starts (and the sweet appears at the end).
	var da := deg_to_rad(float(r.get("depot_at", 95.0)))
	var du := Vector3(cos(da), 0, sin(da))
	var depot := _label(self, "Parada del autobús escolar", 60, du * (road_r + ROAD_W / 2.0 + 1.0) + Vector3(0, 3.2, 0), Color(1, 0.85, 0.3))
	depot.name = "Depot"
	_stops = r.get("stops", [])
	# The stop marker (a sign) and the waiting classmate.
	_stop_marker = Node3D.new()
	add_child(_stop_marker)
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.07
	pm.height = 2.6
	pm.material = Props.mat(Color(0.6, 0.6, 0.65))
	pole.mesh = pm
	pole.position.y = 1.3
	_stop_marker.add_child(pole)
	var plate := MeshInstance3D.new()
	var plm := BoxMesh.new()
	plm.size = Vector3(0.9, 0.9, 0.05)
	plm.material = Props.mat(Color(0.2, 0.45, 0.9))
	plate.mesh = plm
	plate.position.y = 2.6
	_stop_marker.add_child(plate)
	_label(_stop_marker, "PARADA", 40, Vector3(0, 3.4, 0), Color.WHITE)
	_kid_label = _label(self, "", 44, Vector3.ZERO, Color.WHITE)
	_kid_label.width = 500
	_kid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_kid()


func depot_spot() -> Vector3:
	var da := deg_to_rad(float(reto.get("depot_at", 95.0)))
	return Vector3(cos(da), 0, sin(da)) * road_r


func stop_pos() -> Vector3:
	if round_i >= _stops.size():
		return Vector3.ZERO
	var a := deg_to_rad(float(_stops[round_i].at))
	return Vector3(cos(a), 0, sin(a)) * road_r


func place_pos(name: String) -> Vector3:
	return _places[name][0] if _places.has(name) else Vector3.ZERO


func current_target() -> String:
	return str(_stops[round_i].to) if round_i < _stops.size() else ""


func _next_kid() -> void:
	if round_i >= _stops.size():
		return
	var st: Dictionary = _stops[round_i]
	var a := deg_to_rad(float(st.at))
	var u := Vector3(cos(a), 0, sin(a))
	var side := u * (road_r + ROAD_W / 2.0 + 0.8)
	_stop_marker.position = side + Vector3(-u.z, 0, u.x) * 1.4
	_stop_marker.visible = true
	_kid = Props.character(str(st.get("character", "character-female-b")))
	_kid.scale = Vector3.ONE * 1.4
	_kid.position = side
	_kid.rotation.y = atan2(-u.x, -u.z) + PI
	add_child(_kid)
	var anims := _kid.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap := anims[0] as AnimationPlayer
		ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")
	_kid_label.text = "¡Espérame!"
	_kid_label.position = side + Vector3(0, 3.0, 0)


func _physics_process(delta: float) -> void:
	_cool -= delta
	if done or not bus or not is_instance_valid(bus) or round_i >= _stops.size() or bus.rider == null:
		return
	var bp := Vector3(bus.global_position.x, 0, bus.global_position.z)
	var st: Dictionary = _stops[round_i]
	if bus.passenger == null:
		# Pick up at the stop.
		if bp.distance_to(stop_pos()) < STOP_R + 2.0:
			bus.passenger = _kid
			_stop_marker.visible = false
			Game.sfx("correct", 1.3)
			_kid_label.text = ""
			Game.show_toast("%s: \"%s\"" % [str(st.get("name", "Un compañero")), str(st.say)])
			_label_on_bus(str(st.say))
		return
	# Drop off at the right place.
	for name in _places:
		if bp.distance_to(_places[name][0]) < DROP_R:
			if name != str(st.to):
				if _cool <= 0:
					_cool = 3.0
					Game.sfx("wrong", 1.2)
					Game.show_toast("\"¡No, aquí no! %s\"" % str(st.say))
				return
			_deliver(st)
			return


func _deliver(st: Dictionary) -> void:
	var kid: Node3D = bus.passenger
	bus.passenger = null
	var place: Vector3 = _places[str(st.to)][0]
	var inward := -place.normalized()
	kid.global_position = place + inward * 3.0
	kid.rotation.y = atan2(inward.x, inward.z)
	Game.sfx("win", 1.4)
	Game.show_toast("\"¡Gracias! ¡Adiós!\" %d / %d" % [round_i + 1, _stops.size()])
	var t := create_tween()
	t.tween_interval(1.5)
	t.tween_property(kid, "scale", Vector3.ONE * 0.01, 0.4)
	t.tween_callback(kid.queue_free)
	_clear_bus_label()
	round_i += 1
	delivered += 1
	if round_i >= _stops.size():
		done = true
		Game.show_toast("¡Excursión perfecta! Everyone got where they wanted - a sweet is waiting at the bus stop!")
		if sweet:
			sweet.visible = true
			sweet.scale = Vector3.ONE * 0.01
			create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	_next_kid()


func _label_on_bus(text: String) -> void:
	_clear_bus_label()
	var l := _label(bus, text, 44, Vector3(0, 4.2, 0), Color(1, 0.95, 0.6))
	l.name = "Speech"
	l.width = 600
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _clear_bus_label() -> void:
	var old := bus.get_node_or_null("Speech")
	if old:
		old.queue_free()


func _building(name: String, pos: Vector3, ang: float, col: Color) -> Node3D:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	body.position = pos
	var out := Vector3(cos(ang), 0, sin(ang))
	body.rotation.y = atan2(out.x, out.z)                       # local +Z (the front) faces the road
	var h := 4.0
	_solid(body, Vector3(5.0, h, 4.0), Vector3(0, h / 2.0, 0), Props.mat(col))
	_solid(body, Vector3(5.4, 0.3, 4.4), Vector3(0, h + 0.15, 0), Props.mat(col.darkened(0.35)))
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.2, 1.9, 0.05)
	dm.material = Props.mat(Color(0.45, 0.3, 0.22))
	door.mesh = dm
	door.position = Vector3(0, 0.95, 2.02)
	body.add_child(door)
	for x in [-1.6, 1.6]:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(0.9, 0.9, 0.05)
		wm.material = Props.mat(Color(0.75, 0.9, 1.0))
		w.mesh = wm
		w.position = Vector3(x, 2.4, 2.02)
		body.add_child(w)
	var l := _label(body, name.to_upper(), 72, Vector3(0, h + 1.1, 1.0), Color.WHITE)
	l.outline_modulate = col.darkened(0.55)
	return body


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
