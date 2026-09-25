extends Node3D
## "El Diamante": a big glowing diamond on a far-off island. It can only be taken by someone
## who has finished every bridge AND every reto on all the islands (progress saved in the
## browser). Touch it: if something is still missing, a panel lists what; otherwise ¡enhorabuena!

signal touched

const R := 7.0

var won := false
var _gem: Node3D
var _cage: Node3D
var _t := 0.0
var _cool := 0.0


func setup(ready: bool) -> void:
	# The gem: two cones, glowing.
	_gem = Node3D.new()
	add_child(_gem)
	_gem.position.y = 3.2
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.6, 0.95, 1.0, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.4, 0.85, 1.0)
	m.emission_energy_multiplier = 1.3
	m.metallic = 0.3
	m.roughness = 0.1
	var top := CylinderMesh.new()
	top.top_radius = 0.9
	top.bottom_radius = 1.6
	top.height = 0.8
	top.radial_segments = 8
	top.material = m
	var ti := MeshInstance3D.new()
	ti.mesh = top
	ti.position.y = 0.4
	_gem.add_child(ti)
	var bot := CylinderMesh.new()
	bot.top_radius = 1.6
	bot.bottom_radius = 0.0
	bot.height = 2.0
	bot.radial_segments = 8
	bot.material = m
	var bi := MeshInstance3D.new()
	bi.mesh = bot
	bi.position.y = -1.0
	_gem.add_child(bi)
	# A stone plinth, and a cage of light bars while it's still locked.
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var pl := CylinderMesh.new()
	pl.top_radius = 1.4
	pl.bottom_radius = 1.7
	pl.height = 1.0
	pl.material = Props.mat(Color(0.9, 0.88, 0.95))
	var pmi := MeshInstance3D.new()
	pmi.mesh = pl
	pmi.position.y = 0.5
	body.add_child(pmi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.6
	sh.height = 1.0
	cs.shape = sh
	cs.position.y = 0.5
	body.add_child(cs)
	_cage = Node3D.new()
	add_child(_cage)
	var bar_m := Props.unshaded(Color(1.0, 0.85, 0.3, 0.6))
	for k in 8:
		var a := TAU * k / 8.0
		var b := BoxMesh.new()
		b.size = Vector3(0.12, 4.0, 0.12)
		b.material = bar_m
		var bmi := MeshInstance3D.new()
		bmi.mesh = b
		bmi.position = Vector3(cos(a) * 2.3, 3.0, sin(a) * 2.3)
		_cage.add_child(bmi)
	_cage.visible = not ready
	var l := Label3D.new()
	l.text = "El Diamante"
	l.font = preload("res://scripts/ui.gd").ui_font(700)
	l.font_size = 140
	l.pixel_size = 0.01
	l.outline_size = 20
	l.modulate = Color(0.6, 0.95, 1.0)
	l.outline_modulate = Color(0.1, 0.2, 0.4)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = 7.0
	add_child(l)
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := CylinderShape3D.new()
	ash.radius = 2.8
	ash.height = 5.0
	acs.shape = ash
	area.add_child(acs)
	area.position.y = 2.5
	add_child(area)
	area.body_entered.connect(func(b):
		if b.is_in_group("player") and _cool <= 0 and not Game.ui_open and not won:
			_cool = 2.0
			touched.emit())


func _process(delta: float) -> void:
	_t += delta
	_cool -= delta
	if _gem and is_instance_valid(_gem):
		_gem.rotation.y += delta * 0.8
		_gem.position.y = 3.2 + sin(_t * 1.5) * 0.25
	if _cage and _cage.visible:
		_cage.rotation.y -= delta * 0.4


func win(player: Node3D) -> void:
	won = true
	_cage.visible = false
	var t := create_tween()
	t.tween_property(_gem, "scale", Vector3.ONE * 1.6, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_gem, "global_position", player.global_position + Vector3(0, 2.5, 0), 0.8)
	t.tween_property(_gem, "scale", Vector3.ONE * 0.01, 0.4)
