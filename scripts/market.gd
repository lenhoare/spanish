extends Node3D
## "El mercado": a shopping list, a budget, and four stalls with two choices each (one cheap,
## one dearer). Walk into an item to put it in your basket (it replaces your other choice from
## that stall). Then pay at the till: everything on the list, without going over budget.
## Faces local +Z (the middle of the island): stalls at the back, the till at the front.

const STALL_X := [-6.3, -2.1, 2.1, 6.3]

var reto: Dictionary
var sweet: Node3D
var done := false
var basket := {}                  # stall index -> item index

var _items: Array = []            # per stall: [{name, price, node}]
var _total_label: Label3D
var _cool := 0.0


func setup(r: Dictionary) -> void:
	reto = r
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	_flat(Vector3(17.0, 0.04, 10.0), Vector3(0, 0.02, 0), Props.mat(Color(0.9, 0.82, 0.68)))
	var stalls: Array = r.get("stalls", [])
	for s in mini(stalls.size(), STALL_X.size()):
		var st: Dictionary = stalls[s]
		var x: float = STALL_X[s]
		var awning := Props.model("fair/stall-food")
		awning.scale = Vector3.ONE * 2.6
		awning.position = Vector3(x, 0, -3.6)
		awning.rotation.y = PI           # the model's front faces -Z
		add_child(awning)
		_solid(body, Vector3(3.6, 0.95, 1.1), Vector3(x, 0.47, -1.6), Props.mat(Color(0.75, 0.55, 0.35)))
		_label(self, str(st.get("name", "")), 54, Vector3(x, 4.3, -2.2), Color(1, 0.9, 0.4))
		var list: Array = []
		var items: Array = st.get("items", [])
		for i in mini(items.size(), 2):
			var it: Dictionary = items[i]
			var ix := x + (-0.9 if i == 0 else 0.9)
			var m := Props.model(str(it.get("model", "food/apple")))
			m.scale = Vector3.ONE * float(it.get("scale", 3.0))
			m.position = Vector3(ix, 0.95, -1.6)
			add_child(m)
			var tag := _label(self, "%s\n%s" % [str(it.name), euros(float(it.price))], 44, Vector3(ix, 2.4, -1.0), Color.WHITE)
			tag.outline_modulate = Color(0.35, 0.2, 0.1)
			tag.font_size = 40
			tag.width = 260                    # long names wrap instead of running into the next tag
			tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var area := Area3D.new()
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = Vector3(1.2, 2.0, 0.6)      # shallow: you have to walk up to the table
			cs.shape = sh
			area.add_child(cs)
			area.position = Vector3(ix, 1.0, -0.9)
			add_child(area)
			area.body_entered.connect(_on_item.bind(s, i))
			list.append({"name": str(it.name), "price": float(it.price), "node": m, "tag": tag})
		_items.append(list)
	# The shopping list on a board by the entrance.
	var board_pos := Vector3(-4.0, 0, 4.2)
	_solid(body, Vector3(3.2, 3.0, 0.2), board_pos + Vector3(0, 2.0, 0), Props.mat(Color(0.3, 0.45, 0.35)))
	var lines := PackedStringArray(["LA LISTA", ""])
	for st in stalls:
		lines.append("- " + str(st.get("need", "")))
	lines.append("")
	lines.append("Tienes %s" % euros(budget()))
	var lst := _label(self, "\n".join(lines), 38, board_pos + Vector3(0, 2.0, 0.12), Color.WHITE)
	lst.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# The till, with a shopkeeper.
	_solid(body, Vector3(2.6, 1.0, 1.0), Vector3(4.0, 0.5, 3.4), Props.mat(Color(0.6, 0.4, 0.3)))
	var till := Props.model("arcade/cash-register")
	till.scale = Vector3.ONE * 1.6
	till.position = Vector3(4.4, 1.0, 3.4)
	till.rotation.y = PI
	add_child(till)
	var keeper := Props.character(str(r.get("character", "character-male-a")))
	keeper.scale = Vector3.ONE * 1.7
	keeper.position = Vector3(4.0, 0, 2.3)
	add_child(keeper)
	var anims := keeper.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		(anims[0] as AnimationPlayer).get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		(anims[0] as AnimationPlayer).play("idle")
	_label(self, "La caja", 60, Vector3(4.0, 4.2, 3.4), Color(1, 0.9, 0.4))
	_total_label = _label(self, "", 44, Vector3(4.0, 3.4, 3.4), Color.WHITE)
	_refresh()
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.0, 2.0, 1.4)
	cs.shape = sh
	area.add_child(cs)
	area.position = Vector3(4.0, 1.0, 4.4)
	add_child(area)
	area.body_entered.connect(_on_till)


func budget() -> float:
	return float(reto.get("budget", 6.0))


func total() -> float:
	var t := 0.0
	for s in basket:
		t += float(_items[s][basket[s]].price)
	return t


static func euros(v: float) -> String:
	return ("%.2f €" % v).replace(".", ",")


func sweet_spot() -> Vector3:
	return to_global(Vector3(3.2, 1.9, 3.4))


func item_spot(stall: int, i: int) -> Vector3:
	return to_global(Vector3(STALL_X[stall] + (-0.9 if i == 0 else 0.9), 0.3, -0.7))


func till_spot() -> Vector3:
	return to_global(Vector3(4.0, 0.3, 4.6))


func _process(delta: float) -> void:
	_cool -= delta


func _on_item(body: Node, s: int, i: int) -> void:
	if done or not body.is_in_group("player"):
		return
	if basket.get(s, -1) == i:
		return
	basket[s] = i
	var it: Dictionary = _items[s][i]
	Game.sfx("click", 1.2)
	var n: Node3D = it.node
	var t := create_tween()
	t.tween_property(n, "position:y", n.position.y + 0.4, 0.12)
	t.tween_property(n, "position:y", n.position.y, 0.15)
	Game.show_toast("En la cesta: %s (%s). Total: %s" % [it.name, euros(it.price), euros(total())])
	_refresh()


func _on_till(body: Node) -> void:
	if done or _cool > 0 or not body.is_in_group("player"):
		return
	_cool = 2.0
	var stalls: Array = reto.get("stalls", [])
	for s in mini(stalls.size(), _items.size()):
		if not basket.has(s):
			Game.sfx("wrong", 1.1)
			Game.show_toast("El tendero: \"Te falta %s.\" (Check the list!)" % str(stalls[s].get("need", "algo")))
			return
	var t := total()
	if t > budget() + 0.001:
		Game.sfx("wrong", 1.1)
		Game.show_toast("El tendero: \"Son %s... ¡pero solo tienes %s!\" Choose cheaper things." % [euros(t), euros(budget())])
		return
	done = true
	Game.sfx("win", 1.2)
	Game.show_toast("El tendero: \"Son %s. Aquí tienes el cambio: %s. ¡Gracias!\"" % [euros(t), euros(budget() - t)])
	_total_label.text = "¡Gracias!"
	if sweet:
		sweet.visible = true
		sweet.scale = Vector3.ONE * 0.01
		create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	_total_label.text = "Total: %s / %s" % [euros(total()), euros(budget())]
	# Chosen items glow a little; the other choice at that stall dims.
	for s in _items.size():
		for i in _items[s].size():
			var tag: Label3D = _items[s][i].tag
			tag.modulate = Color(0.6, 1.0, 0.6) if basket.get(s, -1) == i else Color.WHITE


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
	l.outline_modulate = Color(0.2, 0.2, 0.35)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l
