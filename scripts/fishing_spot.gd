extends Node3D
## "¡A pescar!": a ring of buoys out at sea where fish keep leaping out of the water.
## Row the boat into the ring and you catch one (on_catch is called - e.g. the restaurant
## puts it in your hands).

const RADIUS := 5.0

var rowboat: Node3D
var on_catch := Callable()
var caught := false

var _fish: Array[Node3D] = []
var _phase: Array[float] = []
var _t := 0.0


func setup() -> void:
	for i in 8:
		var a := TAU * i / 8.0
		var b := Props.model("water/buoy" if i % 2 == 0 else "water/buoy-flag")
		b.scale = Vector3.ONE * 1.6
		b.position = Vector3(cos(a), 0, sin(a)) * RADIUS + Vector3(0, -0.4, 0)
		add_child(b)
	for i in 3:
		var f := Props.model("food/fish")
		f.scale = Vector3.ONE * 4.0
		add_child(f)
		_fish.append(f)
		_phase.append(i * 1.1)
	var l := Label3D.new()
	l.text = "¡A pescar!"
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = 110
	l.pixel_size = 0.008
	l.outline_size = 18
	l.modulate = Color(0.6, 0.9, 1.0)
	l.outline_modulate = Color(0.1, 0.25, 0.5)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 4.5, 0)
	add_child(l)


func _process(delta: float) -> void:
	_t += delta
	# Fish leap in little arcs, one after another.
	for i in _fish.size():
		var f := _fish[i]
		var k := fmod(_t * 0.6 + _phase[i], 3.0)
		var a := TAU * i / 3.0 + 0.5
		var base := Vector3(cos(a), 0, sin(a)) * 2.0
		if k < 1.0:
			f.visible = true
			f.position = base + Vector3(k * 1.6 - 0.8, -0.6 + sin(k * PI) * 2.2, 0)
			f.rotation.z = lerpf(0.9, -0.9, k)
		else:
			f.visible = false
	if caught or not rowboat or not is_instance_valid(rowboat) or rowboat.rider == null:
		return
	var d := Vector2(rowboat.global_position.x - global_position.x, rowboat.global_position.z - global_position.z)
	if d.length() < RADIUS:
		caught = true
		Game.sfx("win", 1.4)
		Game.show_toast("¡Has pescado un pescado! Take it to the restaurant.")
		if on_catch.is_valid():
			on_catch.call()
		# Let it be caught again later (in case it's lost), after a while.
		get_tree().create_timer(8.0).timeout.connect(func(): caught = false)
