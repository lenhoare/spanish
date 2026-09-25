extends Node3D
## "¡A pescar!": one fish swims in a straight line under the water and leaps out four times.
## The first two leaps are at random spots; after that the leaps are evenly spaced along the
## same line - so a sharp-eyed rower can work out where it will come up next and be waiting
## there (the boat is slow!). Be under it when it leaps and you catch it. A splash ring marks
## each leap. Then it dives, swims off somewhere else, and starts a new run.

const AREA_R := 12.0         # the fish swims about within this distance of the middle
const JUMPS := 4
const LEAP_TIME := 1.1       # seconds in the air
const GAP := 3.2             # seconds under water between leaps
const CATCH_R := 2.6

var rowboat: Node3D
var on_catch := Callable()
var active := Callable()     # optional: () -> bool, false when nobody needs a fish any more
var caught := false
var points: Array[Vector3] = []   # this run's leap spots (local)
var jump_i := 0

var _fish: Node3D
var _t := 0.0
var _rest := 1.5
var _rng := RandomNumberGenerator.new()
var _ripples: Array = []     # [{node, t}]


func setup() -> void:
	_rng.randomize()
	_fish = Props.model("food/fish")
	_fish.scale = Vector3.ONE * 4.0
	_fish.visible = false
	add_child(_fish)
	var l := Label3D.new()
	l.text = "¡A pescar!"
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = 110
	l.pixel_size = 0.008
	l.outline_size = 18
	l.modulate = Color(0.6, 0.9, 1.0)
	l.outline_modulate = Color(0.1, 0.25, 0.5)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 6.0, 0)
	add_child(l)
	_new_run()


## Two random spots; the rest follow on along the same line, evenly spaced.
func _new_run() -> void:
	points.clear()
	jump_i = 0
	# Start near one edge of the area and swim across it, roughly through the middle.
	var a := _rng.randf() * TAU
	var step := _rng.randf_range(4.5, 6.0)
	var start := Vector3(cos(a), 0, sin(a)) * AREA_R * 0.75
	var dir := (-start).normalized().rotated(Vector3.UP, _rng.randf_range(-0.45, 0.45))
	for k in JUMPS:
		points.append(start + dir * step * k)
	_t = 0.0


func _process(delta: float) -> void:
	for i in range(_ripples.size() - 1, -1, -1):
		var r: Dictionary = _ripples[i]
		r.t += delta
		(r.node as Node3D).scale = Vector3.ONE * (0.4 + r.t * 1.3)
		((r.node as MeshInstance3D).mesh.material as StandardMaterial3D).albedo_color.a = maxf(0.0, 0.8 - r.t * 0.35)
		if r.t > 2.3:
			(r.node as Node3D).queue_free()
			_ripples.remove_at(i)
	if _rest > 0:
		_rest -= delta
		return
	_t += delta
	var cycle := LEAP_TIME + GAP
	var k := int(_t / cycle)
	if k >= JUMPS:
		_fish.visible = false
		_rest = 2.5
		_new_run()
		return
	if k != jump_i:
		jump_i = k
	var in_leap := fmod(_t, cycle)
	if in_leap < LEAP_TIME:
		var f := in_leap / LEAP_TIME
		var p: Vector3 = points[k]
		var along := (points[1] - points[0]).normalized()
		if not _fish.visible:
			_fish.visible = true
			_ripple(p)
			Game.sfx("thud", 1.8, -10)
		_fish.position = p + along * (f - 0.5) * 1.6 + Vector3(0, -0.5 + sin(f * PI) * 2.4, 0)
		_fish.rotation.y = atan2(along.x, along.z) - PI / 2
		_fish.rotation.z = lerpf(0.9, -0.9, f)
		_try_catch()
	elif _fish.visible:
		_fish.visible = false
		_ripple(_fish.position * Vector3(1, 0, 1))


func _try_catch() -> void:
	if caught or not rowboat or not is_instance_valid(rowboat) or rowboat.rider == null:
		return
	if active.is_valid() and not active.call():
		return
	var b := to_local(rowboat.global_position)
	if Vector2(b.x - _fish.position.x, b.z - _fish.position.z).length() > CATCH_R:
		return
	caught = true
	_fish.visible = false
	Game.sfx("win", 1.4)
	Game.show_toast("¡Has pescado un pescado! Take it to the restaurant.")
	if on_catch.is_valid():
		on_catch.call()
	_rest = 3.0
	_new_run()
	# It can be caught again later (in case it's lost).
	get_tree().create_timer(8.0).timeout.connect(func(): caught = false)


## Where the fish will leap next (local), or null between runs - for the test.
func next_point():
	var k := int(_t / (LEAP_TIME + GAP))
	if _rest > 0 or k + 1 >= JUMPS:
		return null
	return points[k + 1]


func _ripple(p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.8)
	ring.material = m
	mi.mesh = ring
	mi.position = Vector3(p.x, -0.15, p.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_ripples.append({"node": mi, "t": 0.0})
