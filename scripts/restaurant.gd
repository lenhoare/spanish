extends Node3D
## "El restaurante": customers sit at the tables and order IN SPANISH ("Para mí, el pescado,
## por favor"). Pick the right dish up from the kitchen counter (no labels - you need to know
## the words!) and carry it to their table. There's no fish in the kitchen today: row out to
## sea and catch one. Every customer served = a sweet on the counter.
## Faces local +Z (the middle of the island): the kitchen is at the back.

const COUNTER_Z := -4.0
const TABLE_X := [-5.0, 0.0, 5.0]
const TABLE_Z := 2.4

var reto: Dictionary
var sweet: Node3D
var done := false
var carrying := ""                  # id of the dish in your hands
var served := {}                    # customer index -> true

var _carry_node: Node3D
var _bubbles: Array[Label3D] = []
var _chef_label: Label3D
var _cool := 0.0
var _nag := 0.0


func setup(r: Dictionary) -> void:
	reto = r
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	_flat(Vector3(16.0, 0.04, 12.0), Vector3(0, 0.02, -0.5), Props.mat(Color(0.95, 0.85, 0.7)))
	# The kitchen: a back wall with the name, a counter with the dishes, and the chef.
	_solid(body, Vector3(12.0, 5.0, 0.3), Vector3(0, 2.5, -6.2), Props.mat(Color(0.95, 0.55, 0.35)))
	_solid(body, Vector3(11.0, 1.0, 1.2), Vector3(0, 0.5, COUNTER_Z), Props.mat(Color(0.98, 0.95, 0.88)))
	_label(self, str(r.get("sign", "Restaurante La Fiesta")), 90, Vector3(0, 5.6, -6.1), Color(1, 0.9, 0.4)).billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var chef := Props.character(str(r.get("chef", "character-male-e")))
	chef.scale = Vector3.ONE * 1.7
	chef.position = Vector3(-4.4, 0, -5.3)
	add_child(chef)
	_idle(chef)
	_chef_label = _label(self, "", 44, Vector3(-4.4, 4.2, -5.6), Color(1, 0.95, 0.7))
	var dishes: Array = r.get("dishes", [])
	for k in dishes.size():
		var d: Dictionary = dishes[k]
		var x := -4.5 + k * (9.0 / maxf(1.0, dishes.size() - 1))
		var m := Props.model(str(d.model))
		m.scale = Vector3.ONE * float(d.get("scale", 2.5))
		m.position = Vector3(x, 1.0, COUNTER_Z)
		add_child(m)
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.9, 2.0, 0.6)       # shallow, right against the counter
		cs.shape = sh
		area.add_child(cs)
		area.position = Vector3(x, 1.0, COUNTER_Z + 0.9)
		add_child(area)
		area.body_entered.connect(_on_dish.bind(k))
	# The tables, each with a customer and their order.
	var orders: Array = r.get("orders", [])
	for i in mini(orders.size(), TABLE_X.size()):
		var o: Dictionary = orders[i]
		var tpos := Vector3(TABLE_X[i], 0, TABLE_Z)
		var table := Props.model("furniture/tableCloth")
		table.scale = Vector3.ONE * 3.2
		table.position = tpos + Vector3(-0.42, 0, 0.225) * 3.2
		add_child(table)
		var tcs := CollisionShape3D.new()
		var tsh := BoxShape3D.new()
		tsh.size = Vector3(2.6, 1.05, 1.4)
		tcs.shape = tsh
		tcs.position = tpos + Vector3(0, 0.52, 0)
		body.add_child(tcs)
		var chair := Props.model("furniture/chairCushion")
		chair.scale = Vector3.ONE * 3.2
		chair.position = tpos + Vector3(-0.1 * 3.2, 0, -1.0 + 0.1 * 3.2)
		add_child(chair)
		var who := Props.character(str(o.get("character", "character-female-a")))
		who.scale = Vector3.ONE * 1.6
		who.position = tpos + Vector3(0, 0.62, -1.0)     # sitting up on the chair
		add_child(who)
		_sit(who)
		var bubble := _label(self, str(o.say), 38, tpos + Vector3(0, 3.6, -1.2), Color.WHITE)
		bubble.width = 380
		bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bubbles.append(bubble)
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 2.0
		sh.height = 2.4
		cs.shape = sh
		area.add_child(cs)
		area.position = tpos + Vector3(0, 1.2, 0.3)
		add_child(area)
		area.body_entered.connect(_on_table.bind(i))
	if needs_fish():
		_chef_label.text = str(r.get("chef_says", "¡Hoy no hay pescado!\n¡Pesca uno en el mar!"))


func fish_served() -> bool:
	var orders: Array = reto.get("orders", [])
	for i in orders.size():
		if str(orders[i].get("want", "")) == "fish" and served.has(i):
			return true
	return false


func needs_fish() -> bool:
	for o in reto.get("orders", []):
		if str(o.get("want", "")) == "fish":
			return true
	return false


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 1.9, COUNTER_Z))


func dish_spot(k: int) -> Vector3:
	var n: int = reto.get("dishes", []).size()
	return to_global(Vector3(-4.5 + k * (9.0 / maxf(1.0, n - 1)), 0.3, COUNTER_Z + 0.8))


func table_spot(i: int) -> Vector3:
	return to_global(Vector3(TABLE_X[i], 0.3, TABLE_Z + 1.6))


func _process(delta: float) -> void:
	_cool -= delta
	_nag -= delta
	if _carry_node and is_instance_valid(_carry_node):
		_carry_node.rotation.y += delta * 2.0


## Put a dish in the player's hands (shown floating over their head).
func carry(id: String, model_name: String, scale := 2.5) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	if _carry_node and is_instance_valid(_carry_node):
		_carry_node.queue_free()
	carrying = id
	if id == "fish":
		_chef_label.text = "¡Un pescado! ¡Llévalo a la mesa!"
	_carry_node = Props.model(model_name)
	_carry_node.scale = Vector3.ONE * scale
	player.add_child(_carry_node)
	_carry_node.position = Vector3(0, 2.3, 0)


func _drop() -> void:
	carrying = ""
	if _carry_node and is_instance_valid(_carry_node):
		_carry_node.queue_free()
	_carry_node = null


func _on_dish(body: Node, k: int) -> void:
	if done or not body.is_in_group("player"):
		return
	var d: Dictionary = reto.get("dishes", [])[k]
	if carrying == str(d.id):
		return
	if carrying == "fish":
		# The fish was hard work - never swap it away by walking past the counter.
		if _nag <= 0:
			_nag = 2.0
			Game.show_toast("¡Llevas el pescado! Take it to the customer who ordered fish.")
		return
	carry(str(d.id), str(d.model), float(d.get("scale", 2.5)) * 0.8)
	Game.sfx("click", 1.2)


func _on_table(body: Node, i: int) -> void:
	if done or served.has(i) or _cool > 0 or not body.is_in_group("player"):
		return
	var o: Dictionary = reto.get("orders", [])[i]
	if carrying == "":
		_cool = 1.0
		Game.sfx("click")
		Game.show_toast("\"%s\" - fetch it from the kitchen counter!" % str(o.say))
		return
	if carrying != str(o.want):
		_cool = 1.5
		Game.sfx("wrong")
		_bubbles[i].text = str(o.get("wrong", "¡Eso no es lo que pedí!"))
		Game.show_toast("\"¡Eso no es lo que pedí!\" Read the order again: %s" % str(o.say))
		get_tree().create_timer(2.5).timeout.connect(func():
			if not served.has(i):
				_bubbles[i].text = str(o.say))
		return
	# Served!
	served[i] = true
	_drop()
	Game.sfx("correct")
	_bubbles[i].text = str(o.get("thanks", "¡Qué rico! ¡Gracias!"))
	_bubbles[i].modulate = Color(0.6, 1.0, 0.6)
	if str(o.want) == "fish":
		_chef_label.text = "¡Qué buen pescado!"
	var orders: Array = reto.get("orders", [])
	if served.size() < orders.size():
		Game.show_toast("¡Muy bien! %d / %d customers served." % [served.size(), orders.size()])
		return
	done = true
	_chef_label.text = "¡Buen trabajo!"
	Game.show_toast("¡Fantástico! Everyone has their food - the chef has a sweet for you on the counter!")
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _sit(n: Node3D) -> void:
	var anims := n.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap := anims[0] as AnimationPlayer
		var an := "sit" if ap.has_animation("sit") else "idle"
		ap.get_animation(an).loop_mode = Animation.LOOP_LINEAR
		ap.play(an)


func _idle(n: Node3D) -> void:
	var anims := n.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap := anims[0] as AnimationPlayer
		ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")


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
	l.outline_modulate = Color(0.3, 0.15, 0.3)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
