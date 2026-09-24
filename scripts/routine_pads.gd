extends Node3D
## "La rutina diaria": five pressure pads, each labelled with a daily-routine phrase in Spanish.
## Step on them in the order you'd do them in the morning to open the hut's door.
## A wrong step buzzes and resets them. The pads are laid out in a jumbled arc.

const ORDER := ["me despierto", "me levanto", "me ducho", "me visto", "desayuno"]
## Where each phrase's pad sits (local), deliberately not in order.
const SPOTS := {
	"me ducho": Vector3(-5.0, 0, 1.0),
	"desayuno": Vector3(-2.6, 0, 3.4),
	"me despierto": Vector3(0.0, 0, 4.2),
	"me visto": Vector3(2.6, 0, 3.4),
	"me levanto": Vector3(5.0, 0, 1.0),
}

signal solved

var hut: Node3D     # the door to open (sweet_shop.gd), set by the world
var done := false

var _next := 0
var _pads := {}     # phrase -> {mesh, mat, label}
var _cool := 0.0
var _told := false


func setup() -> void:
	for phrase in ORDER:
		var spot: Vector3 = SPOTS[phrase]
		var m := Props.mat(Color(0.75, 0.8, 0.95))
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.1
		disc.height = 0.18
		disc.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = disc
		mi.position = spot + Vector3(0, 0.09, 0)
		add_child(mi)
		var label := Label3D.new()
		label.text = phrase
		label.font = preload("res://scripts/ui.gd").ui_font(700)
		label.font_size = 56
		label.pixel_size = 0.006
		label.outline_size = 14
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color.WHITE
		label.outline_modulate = Color(0.25, 0.3, 0.6)
		label.position = spot + Vector3(0, 1.3, 0)
		add_child(label)
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.95
		sh.height = 1.0
		cs.shape = sh
		area.add_child(cs)
		area.position = spot + Vector3(0, 0.5, 0)
		add_child(area)
		area.body_entered.connect(_on_pad.bind(phrase))
		_pads[phrase] = {"mesh": mi, "mat": m, "label": label}
	# Instructions board.
	var sign := Props.place(self, "sign", Vector3(0, 0, 6.5), PI, 2.8, "box")
	var sl := Label3D.new()
	sl.text = "La rutina\ndiaria"
	sl.font_size = 34
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.25, 0.55)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)


func _process(delta: float) -> void:
	_cool -= delta


func _on_pad(body: Node, phrase: String) -> void:
	if done or _cool > 0 or not body.is_in_group("player"):
		return
	if not _told:
		_told = true
		Game.show_toast("¿Qué haces por la mañana? Step on the pads in the right order!")
	var idx := ORDER.find(phrase)
	if idx < _next:
		return      # already lit
	if idx == _next:
		_next += 1
		_light(phrase, Color(0.45, 0.9, 0.45))
		Game.sfx("pickup", 0.9 + _next * 0.12)
		if _next == ORDER.size():
			done = true
			Game.show_toast("¡Perfecto! Primero me despierto... ¡y luego desayuno! The door is open!")
			if hut:
				hut.open_door()
			solved.emit()
		return
	# Wrong order: flash red and reset.
	_cool = 1.0
	_next = 0
	Game.sfx("wrong", 0.9)
	Game.show_toast("¡No! \"%s\" isn't next. Start again from the beginning of the day..." % phrase)
	_light(phrase, Color(1.0, 0.35, 0.35))
	await get_tree().create_timer(0.6).timeout
	for p in ORDER:
		_light(p, Color(0.75, 0.8, 0.95))


func _light(phrase: String, col: Color) -> void:
	var pad: Dictionary = _pads[phrase]
	(pad.mat as StandardMaterial3D).albedo_color = col
	var t := create_tween()
	var mi: MeshInstance3D = pad.mesh
	t.tween_property(mi, "scale", Vector3(1.15, 1.6, 1.15), 0.08)
	t.tween_property(mi, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
