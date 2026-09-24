extends Node3D
## A character at a little market stall who has lost three things. Bring them all back and
## they let you have the sweet on the counter (after answering their question).
## Everything they say is in Spanish only - working it out is part of the challenge.
## Configured with a dictionary (see world.gd QUESTS). The stall faces local +Z.

var cfg: Dictionary
var sweet: Node3D      # the reward on the counter (set by the world)

var _npc: Node3D
var _anim: AnimationPlayer
var _bubble: Label3D
var _nag := 0.0
var _thanked := false


func setup(config: Dictionary) -> void:
	cfg = config
	var wood := Props.mat(Color(0.75, 0.5, 0.32))
	var white := Props.mat(Color(1, 1, 1))
	var stripe_mat := Props.mat(cfg.get("awning", Color(0.93, 0.3, 0.35)))

	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	# Counter, back wall, posts
	_box(body, Vector3(4.0, 1.1, 1.0), Vector3(0, 0.55, 1.2), wood)
	_box(body, Vector3(4.3, 0.12, 1.3), Vector3(0, 1.16, 1.2), white)
	_box(body, Vector3(4.6, 3.2, 0.3), Vector3(0, 1.6, -1.2), Props.mat(Color(1.0, 0.93, 0.8)))
	for x in [-2.2, 2.2]:
		_box(body, Vector3(0.25, 3.2, 0.25), Vector3(x, 1.6, 1.6), wood)
	_box(body, Vector3(3.6, 0.4, 1.4), Vector3(0, 0.2, 0.0), wood)   # little step behind the counter
	# Striped awning
	for i in 7:
		var stripe := BoxMesh.new()
		stripe.size = Vector3(4.8 / 7.0, 0.12, 3.4)
		stripe.material = stripe_mat if i % 2 == 0 else white
		var mi := MeshInstance3D.new()
		mi.mesh = stripe
		mi.position = Vector3(-2.4 + (i + 0.5) * 4.8 / 7.0, 3.35, 0.3)
		mi.rotation.x = 0.18
		add_child(mi)
	var roof := CollisionShape3D.new()
	var rsh := BoxShape3D.new()
	rsh.size = Vector3(4.8, 0.2, 3.4)
	roof.shape = rsh
	roof.position = Vector3(0, 3.35, 0.3)
	roof.rotation.x = 0.18
	body.add_child(roof)
	var sign := Label3D.new()
	sign.text = str(cfg.get("sign", ""))
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.outline_size = 14
	sign.outline_modulate = (cfg.get("awning", Color(0.93, 0.3, 0.35)) as Color).darkened(0.25)
	sign.position = Vector3(0, 2.7, -1.0)
	add_child(sign)
	for deco in cfg.get("counter", []):     # [model, scale, x]
		var d: Node3D = _dumbbell() if deco[0] == "dumbbell" else (_bins() if deco[0] == "bins" else Props.model(deco[0]))
		d.scale = Vector3.ONE * deco[1]
		d.position = Vector3(deco[2], 1.22, 1.2 + (deco[3] if deco.size() > 3 else 0.0))
		add_child(d)

	# The character, behind the counter.
	_npc = Props.character(str(cfg.character)) if not str(cfg.character).contains("/") else Props.model(str(cfg.character))
	_npc.scale = Vector3.ONE * float(cfg.get("npc_scale", 2.4))   # tall enough to see over the counter
	_npc.position = Vector3(0, 0.4, 0.05)
	add_child(_npc)
	match str(cfg.get("hat", "")):
		"chef":
			# (sizes are in the character's own units - they're scaled up)
			_part(_npc, CylinderMesh.new(), Vector3(0, 0.86, 0.01), white, 0.13, 0.11, 0.2)
			var puff := SphereMesh.new()
			puff.radius = 0.15
			puff.height = 0.2
			_part(_npc, puff, Vector3(0, 0.98, 0.01), white)
		"headband":
			var band := TorusMesh.new()
			band.inner_radius = 0.16
			band.outer_radius = 0.2
			var bm := _part(_npc, band, Vector3(0, 0.62, 0.0), Props.mat(Color(1.0, 0.35, 0.55)))
			bm.scale = Vector3(1.05, 0.5, 1.0)
	var anims := _npc.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		_anim = anims[0]
		_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		_anim.play("idle")

	_bubble = Label3D.new()
	_bubble.font = preload("res://scripts/ui.gd").ui_font(600)
	_bubble.font_size = 44
	_bubble.pixel_size = 0.005
	_bubble.outline_size = 14
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.outline_modulate = Color(0.35, 0.2, 0.5)
	_bubble.position = Vector3(0, 4.3, 0.3)
	add_child(_bubble)
	_update_bubble()
	Game.ingredients_changed.connect(_update_bubble)

	# Talk to them by walking up to the counter.
	var area := Area3D.new()
	var acs := CollisionShape3D.new()
	var ash := BoxShape3D.new()
	ash.size = Vector3(5.0, 2.5, 2.5)
	acs.shape = ash
	acs.position = Vector3(0, 1.25, 2.6)
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_nag -= delta


func has_everything() -> bool:
	for item in cfg.items:
		if not item[0] in Game.ingredients:
			return false
	return true


func _update_bubble() -> void:
	_bubble.text = str(cfg.thanks) if has_everything() else str(cfg.greeting)
	# A hidden reward pops onto the counter when the last item is found.
	if has_everything() and sweet and is_instance_valid(sweet) and not sweet.visible:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if has_everything():
		if not _thanked:
			_thanked = true
			if _anim:
				_anim.play("emote-yes")
				_anim.queue("idle")
			Game.sfx("correct")
		# They ask their question themselves (same checks as touching the sweet).
		if sweet and is_instance_valid(sweet):
			sweet._on_body(body)
		return
	if _nag > 0:
		return
	_nag = 4.0
	var missing := []
	for item in cfg.items:
		if not item[0] in Game.ingredients:
			missing.append(item[0])
	Game.sfx("click")
	Game.show_toast("%s: \"¡Necesito %s!\"" % [cfg.speaker, _spanish_list(missing)])


static func _spanish_list(items: Array) -> String:
	if items.size() == 1:
		return items[0]
	return ", ".join(items.slice(0, items.size() - 1)) + " y " + items[-1]


## Three little recycling bins: yellow (plástico), blue (papel), green (vidrio).
func _bins() -> Node3D:
	var n := Node3D.new()
	var cols := [Color(1.0, 0.82, 0.2), Color(0.25, 0.5, 0.95), Color(0.25, 0.7, 0.3)]
	for i in 3:
		var bin := BoxMesh.new()
		bin.size = Vector3(0.45, 0.6, 0.45)
		var b := _part(n, bin, Vector3(-0.55 + i * 0.55, 0.3, 0), Props.mat(cols[i]))
		var lid := BoxMesh.new()
		lid.size = Vector3(0.52, 0.08, 0.52)
		_part(b, lid, Vector3(0, 0.33, 0), Props.mat((cols[i] as Color).darkened(0.25)))
	return n


## A chunky dumbbell (Kenney has none), lying on the counter.
func _dumbbell() -> Node3D:
	var n := Node3D.new()
	var metal := Props.mat(Color(0.35, 0.37, 0.45))
	var grip := CylinderMesh.new()
	grip.top_radius = 0.06
	grip.bottom_radius = 0.06
	grip.height = 0.9
	var g := _part(n, grip, Vector3(0, 0.2, 0), metal, 0.06, 0.06, 0.9)
	g.rotation.z = PI / 2
	for x in [-0.4, 0.4]:
		var w := _part(n, CylinderMesh.new(), Vector3(x, 0.2, 0), Props.mat(Color(0.95, 0.35, 0.55)), 0.2, 0.2, 0.16)
		w.rotation.z = PI / 2
	n.rotation.y = randf_range(-0.35, 0.35)   # lying sideways, slightly askew
	return n


func _part(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, m: Material, top := 0.0, bottom := 0.0, h := 0.0) -> MeshInstance3D:
	if mesh is CylinderMesh:
		mesh.top_radius = top
		mesh.bottom_radius = bottom
		mesh.height = h
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _box(parent: Node3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	box.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	parent.add_child(cs)
