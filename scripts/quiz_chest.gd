extends Node3D
## A treasure chest locked by a multiple-choice question. Answer it for coins.
## Chests come in levels (1 easy, 2 medium, 3 hard): a level stays locked until every
## chest of the level below is open, so students work from easy to hard.

signal touched(chest: Node3D)

var question: Dictionary
var opened := false
var level := 1
var level_locked := false

const LEVEL_COLORS := [Color(0.55, 0.95, 0.55), Color(1.0, 0.8, 0.35), Color(1.0, 0.5, 0.75)]

var _model: Node3D
var _anim: AnimationPlayer
var _cooldown := 0.0
var _lock: Node3D
var _t := 0.0
var _tag: Label3D


func setup(q: Dictionary, chest_level := 1) -> void:
	question = q
	level = chest_level
	var body := Props.place(self, "chest", Vector3.ZERO, 0.0, 2.6, "box")
	_model = body.get_child(0)
	var anims := _model.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		_anim = anims[0]

	_lock = Props.model("lock")
	_lock.scale = Vector3.ONE * 1.4
	_lock.position = Vector3(0, 1.45, 0.3)
	add_child(_lock)

	var tag := Label3D.new()
	_tag = tag
	tag.text = "Quiz Chest"
	tag.font_size = 48
	tag.pixel_size = 0.005
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_modulate = Color(0.45, 0.25, 0.1)
	tag.position.y = 2.4
	add_child(tag)
	_update_tag()

	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.8
	s.height = 2.5
	cs.shape = s
	cs.position.y = 1.0
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if _lock and not opened:
		_lock.rotation.y = sin(_t * 2.0) * 0.4
		_lock.position.y = 1.45 + sin(_t * 3.0) * 0.06


func _on_body(body: Node) -> void:
	if opened or Game.ui_open or _cooldown > 0 or not body.is_in_group("player"):
		return
	touched.emit(self)


func set_level_locked(on: bool) -> void:
	level_locked = on
	_update_tag()
	if not on:
		# Little hop to show it just unlocked.
		var t := create_tween()
		t.tween_property(_model, "position:y", 0.6, 0.15).set_ease(Tween.EASE_OUT)
		t.tween_property(_model, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Locked chests show only a padlock (bumping into one explains why);
## unlocked chests show their name and no padlock.
func _update_tag() -> void:
	_tag.visible = not level_locked and not opened
	_tag.text = "Quiz Chest L%d" % level
	_tag.modulate = LEVEL_COLORS[clampi(level - 1, 0, 2)]
	if _lock:
		_lock.visible = level_locked


func rest() -> void:
	_cooldown = 1.5
	var t := create_tween()
	var base := _model.position
	for i in 4:
		t.tween_property(_model, "position:x", base.x + (0.12 if i % 2 == 0 else -0.12), 0.05)
	t.tween_property(_model, "position:x", base.x, 0.05)


func open(player: Node3D) -> void:
	opened = true
	for c in get_children():
		if c is Label3D:
			c.visible = false
	var lt := create_tween()
	lt.tween_property(_lock, "position:y", 3.0, 0.3).set_ease(Tween.EASE_OUT)
	lt.parallel().tween_property(_lock, "scale", Vector3.ONE * 0.01, 0.3)
	lt.tween_callback(_lock.queue_free)
	if _anim and _anim.has_animation("open"):
		_anim.play("open")
	var n: int = question.get("coins", 10)
	for i in n:
		_spawn_coin(player, i * 0.06)


func _spawn_coin(player: Node3D, delay: float) -> void:
	var coin := Props.model("coin-gold")
	coin.scale = Vector3.ONE * 1.5
	add_child(coin)
	coin.position = Vector3(0, 1.0, 0)
	var up := Vector3(randf_range(-1.8, 1.8), randf_range(3.0, 4.5), randf_range(-1.8, 1.8))
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(coin, "position", up, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(coin, "rotation:y", TAU * 2, 0.8)
	t.tween_method(func(k: float):
		if is_instance_valid(player):
			var goal := to_local(player.global_position + Vector3(0, 0.8, 0))
			coin.position = up.lerp(goal, k)
	, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		Game.add_coins(1)
		Game.sfx("pickup", randf_range(1.3, 1.6), -8.0)
		coin.queue_free())
