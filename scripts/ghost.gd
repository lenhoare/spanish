extends Node3D
## A cheeky ghost that guards one area. It circles its post and swoops at players who
## come close. Touching it knocks you back, you drop a few coins, and it STEALS the sweet
## it guards for a while. Jumping on its head stuns it (and makes it drop the sweet).

const PATROL_SPEED := 1.25     # radians per second around the post
const MOVE_SPEED := 4.2        # metres per second (player runs at 6.5)
const HOME_RANGE := 5.5        # never strays further than this from its post
const NOTICE_RANGE := 8.0      # starts swooping when the player is this close to its post
const STUN_TIME := 3.5
const STEAL_TIME := 20.0       # seconds the ghost keeps a stolen sweet

var center := Vector3.ZERO
var radius := 3.2
var guarded_sweet: Node3D      # set by the world

var _model: Node3D
var _anim: AnimationPlayer
var _angle := 0.0
var _t := 0.0
var _stun := 0.0
var _hit_cd := 0.0
var _told_stomp := false
var _meshes: Array = []
var _tag: Label3D


func setup(post: Vector3, patrol_radius := 3.2) -> void:
	center = post
	radius = patrol_radius
	global_position = center + Vector3(radius, 0.3, 0)
	_model = Props.model("graveyard/character-ghost")
	_model.scale = Vector3.ONE * 2.8
	add_child(_model)
	_meshes = _model.find_children("*", "GeometryInstance3D", true, false)
	var anims := _model.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		_anim = anims[0]
		if _anim.has_animation("idle"):
			_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			_anim.play("idle")
	var tag := Label3D.new()
	_tag = tag
	tag.text = "¡Cuidado!"
	tag.font_size = 40
	tag.pixel_size = 0.005
	tag.outline_size = 12
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_modulate = Color(0.3, 0.2, 0.5)
	tag.position.y = 2.3
	add_child(tag)


func _physics_process(delta: float) -> void:
	_t += delta
	_hit_cd -= delta
	var has_it := _carrying()
	_tag.text = ("¡Mío! %d" % ceili(guarded_sweet.stolen_left)) if has_it else "¡Cuidado!"
	_tag.position.y = 3.6 if has_it else 2.3
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D

	if _stun > 0:
		_stun -= delta
		_model.rotation.z = sin(_t * 12.0) * 0.15   # dizzy wobble
		global_position.y = 0.1
		if _stun <= 0:
			_set_see_through(false)
			_model.rotation.z = 0
		return

	# Circle the post; swoop towards a nearby player (but never leave home).
	_angle += PATROL_SPEED * delta
	var target := center + Vector3(cos(_angle), 0, sin(_angle)) * radius
	if player and not Game.ui_open and player.global_position.distance_to(center) < NOTICE_RANGE:
		var toward := player.global_position
		toward.y = center.y
		var off := toward - center
		if off.length() > HOME_RANGE:
			toward = center + off.normalized() * HOME_RANGE
		target = target.lerp(toward, 0.55)
	var flat := Vector3(global_position.x, center.y, global_position.z)
	var next := flat.move_toward(target, MOVE_SPEED * delta)
	var move := next - flat
	global_position = Vector3(next.x, center.y + 0.3 + sin(_t * 2.5) * 0.2, next.z)
	if move.length() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(move.x, move.z), 1.0 - exp(-8.0 * delta))

	if player and not Game.ui_open:
		_check_contact(player)


func _check_contact(player: CharacterBody3D) -> void:
	var d := player.global_position - global_position
	var horizontal := Vector2(d.x, d.z).length()
	if horizontal > 1.1 or d.y < -1.2 or d.y > 2.1:
		return
	if d.y > 0.9 and player.velocity.y < 0:
		_stomped(player)
	elif _hit_cd <= 0:
		_hit_cd = 1.2
		var away := Vector3(d.x, 0, d.z).normalized() if horizontal > 0.05 else Vector3.BACK
		player.knockback(away * 10.0 + Vector3.UP * 7.0)
		var lost := mini(3, Game.coins)
		Game.add_coins(-lost)
		Game.sfx("wrong", 0.8)
		var coins_msg := " (-%d coins)" % lost if lost > 0 else ""
		if _can_steal():
			guarded_sweet.steal(self, STEAL_TIME)
			Game.show_toast("¡Ay! The ghost grabbed the lollipop!%s Stomp on it to get it back!" % coins_msg)
		else:
			Game.show_toast("¡Ay! The ghost got you!" + coins_msg)


func _stomped(player: CharacterBody3D) -> void:
	_stun = STUN_TIME
	_set_see_through(true)
	player.bounce(11.0)
	Game.sfx("spring", 0.8)
	if _carrying():
		guarded_sweet.give_back()
		Game.show_toast("Boing! The ghost dropped the lollipop - quick, grab it!")
		return
	if not _told_stomp:
		_told_stomp = true
		Game.show_toast("Boing! The ghost is dizzy - quick, get past!")


func _can_steal() -> bool:
	return guarded_sweet != null and is_instance_valid(guarded_sweet) and not guarded_sweet.collected and not guarded_sweet.is_stolen()


func _carrying() -> bool:
	return guarded_sweet != null and is_instance_valid(guarded_sweet) and not guarded_sweet.collected and guarded_sweet.is_stolen()


func _set_see_through(on: bool) -> void:
	for g in _meshes:
		(g as GeometryInstance3D).transparency = 0.6 if on else 0.0
