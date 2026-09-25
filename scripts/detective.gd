extends Node3D
## "¿Quién lo dice?" - a reading-comprehension Reto. Two unhappy hotel guests stand outside a
## hotel reception, each with a review to read. Once you've read both, the receptionist asks
## "¿Quién menciona...?" questions: pick the right guest (or both) for each one.
## Faces local +Z.

signal reviewer_touched(index: int)
signal desk_touched

var reto: Dictionary
var read := []           # which reviews have been read
var done := false

var _desk: Node3D
var _bubbles: Array[Label3D] = []
var _cool := 0.0


func setup(r: Dictionary) -> void:
	reto = r
	var speakers: Array = r.get("speakers", [])
	read.resize(speakers.size())
	read.fill(false)
	# Reception desk (a passive market stall) with the receptionist behind it.
	_desk = Node3D.new()
	_desk.set_script(preload("res://scripts/quest_stall.gd"))
	add_child(_desk)
	_desk.setup({
		"sign": str(r.get("sign", "Recepción")), "character": str(r.get("receptionist", "character-male-c")),
		"speaker": "", "greeting": str(r.get("greeting", "¿Quién lo dice?")), "thanks": str(r.get("greeting", "¿Quién lo dice?")),
		"awning": Color(0.2, 0.55, 0.75), "counter": [["food/cup-coffee", 2.6, -1.5]], "items": [], "passive": true,
	})
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(5.0, 2.5, 2.5)
	cs.shape = sh
	cs.position = Vector3(0, 1.25, 2.6)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(b):
		if b.is_in_group("player") and not Game.ui_open and _cool <= 0:
			desk_touched.emit())

	# The guests stand either side, each with a speech bubble.
	var chars := ["character-female-b", "character-male-d", "character-female-e"]
	for i in speakers.size():
		var sp: Dictionary = speakers[i]
		var npc := Props.character(str(sp.get("character", chars[i % chars.size()])))
		npc.scale = Vector3.ONE * 1.7
		var x := -4.5 if i == 0 else 4.5 + (i - 1) * 2.5
		npc.position = Vector3(x, 0, 3.2)
		npc.rotation.y = 0.5 if i == 0 else -0.5
		add_child(npc)
		var anims := npc.find_children("*", "AnimationPlayer", true, false)
		if anims.size() > 0:
			var ap: AnimationPlayer = anims[0]
			ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			ap.play("idle")
		var bubble := Label3D.new()
		bubble.font = preload("res://scripts/ui.gd").ui_font(600)
		bubble.text = "%s\n%s" % [sp.get("name", "?"), sp.get("bubble", "¡Hotel horroroso!")]
		bubble.font_size = 40
		bubble.pixel_size = 0.005
		bubble.outline_size = 12
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.outline_modulate = Color(0.45, 0.15, 0.2)
		bubble.position = npc.position + Vector3(0, 2.4, 0)
		add_child(bubble)
		_bubbles.append(bubble)
		var a := Area3D.new()
		var acs := CollisionShape3D.new()
		var ash := CylinderShape3D.new()
		ash.radius = 1.3
		ash.height = 2.5
		acs.shape = ash
		acs.position = npc.position + Vector3(0, 1.2, 0)
		a.add_child(acs)
		add_child(a)
		var idx := i
		a.body_entered.connect(func(b):
			if b.is_in_group("player") and not Game.ui_open and _cool <= 0:
				reviewer_touched.emit(idx))


func _process(delta: float) -> void:
	_cool -= delta


func rest() -> void:
	_cool = 1.5


func mark_read(i: int) -> void:
	read[i] = true
	_bubbles[i].modulate = Color(0.75, 1.0, 0.75)


func all_read() -> bool:
	return not false in read


func finish() -> void:
	done = true
	for b in _bubbles:
		b.text = b.text.split("\n")[0] + "\n¡Gracias!"
