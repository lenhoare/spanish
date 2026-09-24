extends Area3D
## One of the chef's lost ingredients. Pick it up and take it back to the café.

var id := ""            # e.g. "una pizza"
var _model: Node3D
var _t := randf() * TAU
var _taken := false


func setup(ingredient_id: String, model_name: String, model_scale: float) -> void:
	id = ingredient_id
	_model = Props.model(model_name)
	_model.scale = Vector3.ONE * model_scale
	_model.position.y = 0.8
	add_child(_model)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.9
	cs.shape = s
	cs.position.y = 0.9
	add_child(cs)
	body_entered.connect(_on_body)
	# No floating label - finding them is part of the fun. (The Spanish name shows when picked up.)


func _process(delta: float) -> void:
	_t += delta
	if not _taken:
		_model.rotation.y += delta * 1.8
		_model.position.y = 0.8 + sin(_t * 2.4) * 0.15


func _on_body(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	Game.ingredients.append(id)
	Game.ingredients_changed.emit()
	Game.sfx("pickup", 0.8)
	var n := Game.ingredients.size()
	if n < Game.ingredients_total:
		Game.show_toast("¡%s! (%d / %d)" % [_sentence_case(id), n, Game.ingredients_total])
	else:
		Game.show_toast("¡%s! (%d / %d) That's everything - take it all back to the stall!" % [_sentence_case(id), n, Game.ingredients_total])
	var t := create_tween().set_parallel()
	t.tween_property(_model, "position:y", 2.5, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.3).set_delay(0.25)
	t.chain().tween_callback(queue_free)


static func _sentence_case(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)
