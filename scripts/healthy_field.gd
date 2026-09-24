extends Node3D
## "Comida sana": a fenced field where healthy food keeps popping up while junk food
## bounces around. Collect GOAL healthy things without touching the junk; touching junk
## knocks you back and resets your count. Then the sweet appears on the pedestal.
## Every item is named in Spanish when you touch it.

const RADIUS := 7.5
const GOAL := 5
const HEALTHY := [
	["una manzana", "food/apple", 4.0], ["una pera", "food/pear", 3.6], ["una zanahoria", "food/carrot", 1.8],
	["el brócoli", "food/broccoli", 2.4], ["el pescado", "food/fish", 2.4], ["el pan", "food/bread", 3.0],
]
const JUNK := [
	["las patatas fritas", "food/fries", 5.0], ["el perrito caliente", "food/hot-dog", 3.0], ["las galletas", "food/cookie", 7.5], ["el pastel", "food/cake", 2.6],
	["la hamburguesa", "food/burger", 4.5], ["el refresco", "food/soda-can", 4.5],
]
const JUNK_SPEED := 3.3
const LIVE_HEALTHY := 3

var done := false
var count := 0

var _sweet: Node3D
var _healthy: Array = []   # [{node, name}]
var _junk: Array = []      # [{node, name, vel}]
var _hit_cd := 0.0
var _t := 0.0
var _told_start := false
var _rng := RandomNumberGenerator.new()


func setup(sweet: Node3D) -> void:
	_rng.seed = 777
	_sweet = sweet
	_sweet.visible = false
	_sweet.gate = func() -> bool: return done

	# Low fence ring with an opening facing the middle of the island.
	var entry := atan2(-global_position.z, -global_position.x)
	var n := 22
	for i in n:
		var a := TAU * i / n
		if absf(wrapf(a - entry, -PI, PI)) < 0.3:
			continue
		var fence := Props.model("fence-low-straight")
		fence.scale = Vector3.ONE * 2.2
		fence.position = Vector3(cos(a), 0, sin(a)) * (RADIUS + 0.4)
		fence.rotation.y = -a + PI / 2
		add_child(fence)
	var sign := Props.place(get_parent(), "sign", global_position + Vector3(cos(entry), 0, sin(entry)) * (RADIUS + 1.8) + Vector3(1.8, 0, 0), -entry - PI / 2, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "Comida\nsana"
	sl.font_size = 40
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.45, 0.15)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)

	for i in LIVE_HEALTHY:
		_spawn_healthy()
	for i in JUNK.size():
		var j: Array = JUNK[i]
		var node := Props.model(j[1])
		node.scale = Vector3.ONE * j[2]
		add_child(node)
		node.position = _random_spot()
		var a := _rng.randf() * TAU
		_junk.append({"node": node, "name": j[0], "vel": Vector3(cos(a), 0, sin(a)) * JUNK_SPEED, "phase": _rng.randf() * TAU})


func _physics_process(delta: float) -> void:
	_t += delta
	_hit_cd -= delta
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	for h in _healthy:
		var hn: Node3D = h.node
		hn.rotation.y += delta * 1.8
		hn.position.y = 0.5 + sin(_t * 2.5 + hn.position.x) * 0.15
	for j in _junk:
		var jn: Node3D = j.node
		var p: Vector3 = jn.position + j.vel * delta
		var flat := Vector2(p.x, p.z)
		# Bounce off the fence and the pedestal in the middle.
		if flat.length() > RADIUS - 0.8 or flat.length() < 1.8:
			var normal := Vector3(p.x, 0, p.z).normalized()
			j.vel = (j.vel as Vector3).bounce(normal if flat.length() > 3.0 else -normal)
			p = jn.position
		jn.position = Vector3(p.x, absf(sin(_t * 4.0 + j.phase)) * 0.9, p.z)
		jn.rotation.y += delta * 2.0
	if done or not player or Game.ui_open:
		return
	var local := to_local(player.global_position)
	if Vector2(local.x, local.z).length() > RADIUS + 0.5:
		return
	if not _told_start:
		_told_start = true
		Game.show_toast("¡Comida sana! Coge %d cosas sanas... ¡pero cuidado con la comida basura!" % GOAL)
	# Junk food: bumping into it knocks you back and resets your count.
	if _hit_cd <= 0:
		for j in _junk:
			var d: Vector3 = local - (j.node as Node3D).position
			if Vector2(d.x, d.z).length() < 1.2 and local.y < 2.0:
				_hit_cd = 1.2
				var away := Vector3(d.x, 0, d.z).normalized()
				player.knockback(global_transform.basis * away * 9.0 + Vector3.UP * 6.0)
				count = 0
				var verb := "son" if (j.name as String).begins_with("los") or (j.name as String).begins_with("las") else "es"
				Game.sfx("wrong", 0.9)
				Game.show_toast("¡Puaj! %s %s comida basura. ¡Otra vez! 0 / %d" % [_sentence_case(j.name), verb, GOAL])
				return
	# Healthy food: collect it.
	for h in _healthy.duplicate():
		var d: Vector3 = local - (h.node as Node3D).position
		if Vector2(d.x, d.z).length() < 1.1 and local.y < 2.2:
			count += 1
			_healthy.erase(h)
			_pop(h.node)
			Game.sfx("pickup", 1.2)
			if count >= GOAL:
				_finish()
				return
			Game.show_toast("¡%s! Muy sano.  %d / %d" % [_sentence_case(h.name), count, GOAL])
			get_tree().create_timer(0.8).timeout.connect(_spawn_healthy)


func _finish() -> void:
	done = true
	Game.sfx("build")
	Game.show_toast("¡Muy bien! ¡Comes muy sano! The sweet has appeared - go and get it!")
	for j in _junk:
		_pop(j.node)
	_junk.clear()
	for h in _healthy:
		_pop(h.node)
	_healthy.clear()
	_sweet.visible = true
	_sweet.scale = Vector3.ONE * 0.01
	var t := create_tween()
	t.tween_property(_sweet, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_healthy() -> void:
	if done:
		return
	var h: Array = HEALTHY[_rng.randi() % HEALTHY.size()]
	var node := Props.model(h[1])
	node.scale = Vector3.ONE * h[2]
	add_child(node)
	node.position = _random_spot()
	_healthy.append({"node": node, "name": h[0]})


func _random_spot() -> Vector3:
	var a := _rng.randf() * TAU
	var d := _rng.randf_range(2.5, RADIUS - 1.2)
	return Vector3(cos(a) * d, 0.5, sin(a) * d)


func _pop(n: Node3D) -> void:
	var t := create_tween()
	t.tween_property(n, "scale", n.scale * 1.4, 0.1)
	t.tween_property(n, "scale", Vector3.ONE * 0.01, 0.15)
	t.tween_callback(n.queue_free)


static func _sentence_case(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)
