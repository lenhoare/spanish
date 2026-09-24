extends AnimatableBody3D
## A rideable skateboard. Jump onto it (or push off while standing on it) and it rolls off that way,
## carrying you along (like a moving platform), then slowly coasts to a stop.

const MIN_SPEED := 6.0
const MAX_SPEED := 11.0
const FRICTION := 2.2        # m/s lost per second
const ISLAND_R := 28.5       # stay on the main island

var vel := Vector3.ZERO
var _was_on := false
var _model: Node3D


func setup(scale_factor: float) -> void:
	add_to_group("solid_ground")
	_model = Props.model("skate/skateboard")
	_model.scale = Vector3.ONE * scale_factor
	add_child(_model)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.3, 0.14, 0.7) * scale_factor
	cs.shape = sh
	cs.position.y = 0.07 * scale_factor + 0.04   # hover a hair above the ground
	add_child(cs)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	var on := player != null and _player_on(player)
	# Jump on (or run on) a still board: it shoots off the way the rider is moving.
	if on and vel.length() < 1.0:
		var h := Vector3(player.velocity.x, 0, player.velocity.z)
		if h.length() > (1.0 if not _was_on else 2.5):
			vel = h.normalized() * clampf(h.length() * 1.5, MIN_SPEED, MAX_SPEED)
			Game.sfx("spring", 1.4, -6.0)
	_was_on = on
	if vel.length() < 0.05:
		vel = Vector3.ZERO
		return
	# Face the direction of travel, bump off obstacles, keep to the island.
	rotation.y = lerp_angle(rotation.y, atan2(vel.x, vel.z), 1.0 - exp(-10.0 * delta))
	var hit := move_and_collide(vel * delta, true)
	if hit and (hit.get_collider() == player or absf(hit.get_normal().y) > 0.6):
		hit = null     # the rider on top, or the ground underneath, doesn't block the board
	if hit:
		var n := hit.get_normal()
		n.y = 0
		vel = vel.bounce(n.normalized()) * 0.5 if n.length() > 0.1 else Vector3.ZERO
		Game.sfx("thud", 1.3, -8.0)
	else:
		global_position += vel * delta
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > ISLAND_R:
		var inward := Vector3(-flat.x, 0, -flat.y).normalized()
		vel = vel.bounce(inward) * 0.5
		global_position -= Vector3(flat.x, 0, flat.y).normalized() * 0.1
	vel = vel.move_toward(Vector3.ZERO, FRICTION * delta)


func _player_on(p: CharacterBody3D) -> bool:
	var d := to_local(p.global_position)
	return p.is_on_floor() and absf(d.x) < 0.7 and absf(d.z) < 1.2 and d.y > 0.1 and d.y < 0.9
