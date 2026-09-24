extends Node3D
## A pirate ship moored beside a jetty. Not sailable (yet!) - it's a playground:
##   - board it up the gangplank from the jetty
##   - two deck cannons take turns firing cannonballs along the deck (time your crossing!)
##   - a spiral of rigging planks winds up the main mast to a crow's nest lookout
## The ship's bow points along local +Z. Heights below are relative to the keel (ship origin).

const SCALE := 1.6
const DECK_Y := 3.36          # main deck height
const DECK_Z := Vector2(-4.3, 2.3)   # main deck runs between the stern castle and the forecastle
const MAST := Vector3(0, 0, -0.5)    # main mast position
const NEST_Y := 12.7          # crow's nest floor
const NEST_R := 1.3
const FORECASTLE_Y := 4.48    # raised front deck
const LANES := [-1.6, 1.6]    # cannonball lanes (x)
const BALL_SPEED := 7.5
const FIRE_EVERY := 2.4       # seconds between shots from each cannon
const GANGPLANK_SIDE := -1.0  # -1 = port side (-X), where the jetty is

var _balls: Array = []        # [{node, vel, life}]
var hits := 0                 # cannonball hits (for testing)
var _cannons: Array = []      # [{node, lane, t}]
var _wood: StandardMaterial3D
var _rope: StandardMaterial3D


## Where the two ship sweets sit (in ship-local space).
func deck_sweet_spot() -> Vector3:
	return Vector3(2.4, DECK_Y, -2.8)

func nest_sweet_spot() -> Vector3:
	return Vector3(-0.55, NEST_Y, MAST.z + 0.55)


func setup() -> void:
	_wood = Props.mat(Color(0.72, 0.47, 0.3))
	_rope = Props.mat(Color(0.93, 0.83, 0.6))

	var model := Props.model("pirate/ship-pirate-large")
	model.scale = Vector3.ONE * SCALE
	add_child(model)
	# The main sail hangs low over the deck and hides the cannons from the camera:
	# shorten it and hoist it higher (it still stops below the crow's nest), nudged forward.
	var main_sail := model.find_child("sail-a", true, false) as Node3D
	if main_sail:
		main_sail.scale.y = 0.62
		main_sail.position.y = 4.35      # model units: bottom edge ~3.6 m above the deck
		main_sail.position.z += 0.15
	# Walkable hull: trimesh collision from the hull mesh only (sails and flags stay ghostly).
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if not mi.name.begins_with("ship"):
			continue
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		cs.transform = global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform
		body.add_child(cs)

	_build_gangplank()
	_build_rigging()
	for i in 2:
		_add_cannon(LANES[i], i * FIRE_EVERY / 2.0)


func _physics_process(delta: float) -> void:
	for c in _cannons:
		c.t -= delta
		if c.t <= 0:
			c.t = FIRE_EVERY
			_fire(c)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	for b in _balls.duplicate():
		var n: Node3D = b.node
		n.position += b.vel * delta
		n.rotation.x -= delta * 8.0
		b.life -= delta
		if player and not Game.ui_open and n.global_position.distance_to(player.global_position + Vector3(0, 0.6, 0)) < 0.95:
			var push: Vector3 = (b.vel as Vector3).normalized()
			player.knockback(global_transform.basis * push * 9.0 + Vector3.UP * 6.0)
			Game.sfx("thud", 0.9)
			hits += 1
			Game.show_toast("¡Pum! Hit by a cannonball - back to the gangplank!")
			b.life = 0
			_send_back(player)
		if b.life <= 0 or n.position.z < DECK_Z.x + 0.2:
			_pop(n)
			_balls.erase(b)


## Penalty for being hit: after a moment of tumbling, the player is put back at the
## bottom of the gangplank on the jetty and has to board again.
func _send_back(player: CharacterBody3D) -> void:
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(player):
		player.send_to(to_global(Vector3(GANGPLANK_SIDE * 9.4, 2.4, -1.0)))


# ---------------------------------------------------------------- pieces

func _build_gangplank() -> void:
	# From the jetty (outside the port side) up over the rail onto the main deck.
	var s := GANGPLANK_SIDE
	var start := Vector3(s * 8.6, 2.1, -1.0)      # flush with the jetty (keel is 2.2 below the island)
	var finish := Vector3(s * 3.1, DECK_Y + 1.2, -1.0)
	var mid := (start + finish) / 2.0
	var length := start.distance_to(finish)
	var angle := atan2(finish.y - start.y, absf(finish.x - start.x))
	var plank := StaticBody3D.new()
	plank.add_to_group("solid_ground")
	add_child(plank)
	plank.position = mid
	plank.rotation.z = angle * -s
	var box := BoxMesh.new()
	box.size = Vector3(length + 0.4, 0.2, 1.6)
	box.material = _wood
	var mi := MeshInstance3D.new()
	mi.mesh = box
	plank.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box.size
	cs.shape = sh
	plank.add_child(cs)
	# Little cleats so it looks like a gangplank.
	for i in 6:
		var cleat := BoxMesh.new()
		cleat.size = Vector3(0.08, 0.08, 1.4)
		cleat.material = _rope
		var cm := MeshInstance3D.new()
		cm.mesh = cleat
		cm.position = Vector3(-length / 2.0 + 0.5 + i * (length - 1.0) / 5.0, 0.13, 0)
		plank.add_child(cm)


## Where the climbing planks are (ship-local). They zig-zag up from the forecastle (front
## deck) towards the crow's nest, on the bow side of the main sail - hidden from anyone
## standing by the gangplank, and easy to see while you climb.
func climb_steps() -> Array[Vector3]:
	var steps: Array[Vector3] = []
	var n := 8
	var y0 := FORECASTLE_Y + 1.0
	var dy := (NEST_Y - 0.9 - y0) / (n - 1)
	for i in n:
		var z := lerpf(4.8, 1.9, float(i) / (n - 1))   # last plank stays outside the nest
		steps.append(Vector3(-1.0 if i % 2 == 0 else 1.0, y0 + i * dy, z))
	return steps


## Zig-zag planks up to a lookout platform on the main mast.
func _build_rigging() -> void:
	var steps := climb_steps()
	for p in steps:
		_plank(p, 0.0)
	# Crow's nest: round platform with a rail.
	var nest := StaticBody3D.new()
	nest.add_to_group("solid_ground")
	add_child(nest)
	nest.position = Vector3(MAST.x, NEST_Y, MAST.z)
	var disc := CylinderMesh.new()
	disc.top_radius = NEST_R
	disc.bottom_radius = NEST_R - 0.3
	disc.height = 0.35
	disc.material = _wood
	var dm := MeshInstance3D.new()
	dm.mesh = disc
	dm.position.y = -0.175
	nest.add_child(dm)
	var dcs := CollisionShape3D.new()
	var dsh := CylinderShape3D.new()
	dsh.radius = NEST_R
	dsh.height = 0.35
	dcs.shape = dsh
	dcs.position.y = -0.175
	nest.add_child(dcs)
	# Rail posts all round, except a gap facing the last plank so you can climb in.
	var last: Vector3 = steps[-1]
	var entry := atan2(last.z - MAST.z, last.x - MAST.x)
	for k in 12:
		var a := TAU * k / 12.0
		if absf(wrapf(a - entry, -PI, PI)) < deg_to_rad(55):
			continue
		var post := CylinderMesh.new()
		post.top_radius = 0.06
		post.bottom_radius = 0.06
		post.height = 0.8
		post.material = _wood
		var pm := MeshInstance3D.new()
		pm.mesh = post
		pm.position = Vector3(cos(a) * (NEST_R - 0.08), 0.4, sin(a) * (NEST_R - 0.08))
		nest.add_child(pm)
	var flag := Props.model("pirate/flag-pirate-high")
	flag.scale = Vector3.ONE * 1.2
	flag.position = Vector3(0.5, 0, -0.6)
	nest.add_child(flag)


func _plank(p: Vector3, a: float) -> void:
	var b := StaticBody3D.new()
	b.add_to_group("solid_ground")
	add_child(b)
	b.position = p
	b.rotation.y = -a
	var box := BoxMesh.new()
	box.size = Vector3(1.3, 0.18, 0.9)
	box.material = _wood
	var mi := MeshInstance3D.new()
	mi.mesh = box
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box.size
	cs.shape = sh
	b.add_child(cs)
	# Rope from the plank to the mast.
	var rope := CylinderMesh.new()
	rope.top_radius = 0.04
	rope.bottom_radius = 0.04
	rope.height = 1.6
	rope.material = _rope
	var ro := MeshInstance3D.new()
	ro.mesh = rope
	ro.position = Vector3(-0.55, 0.75, 0)
	ro.rotation.z = 0.6
	b.add_child(ro)


func _add_cannon(lane: float, delay: float) -> void:
	var c := Props.model("pirate/cannon")
	c.scale = Vector3.ONE * 1.1
	c.position = Vector3(lane, DECK_Y, DECK_Z.y - 0.2)
	c.rotation.y = PI    # face the stern (-Z)
	add_child(c)
	var body := StaticBody3D.new()
	c.add_child(body)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.3, 1.0, 2.0)
	cs.shape = sh
	cs.position.y = 0.5
	body.add_child(cs)
	_cannons.append({"node": c, "lane": lane, "t": delay + 1.0})


func _fire(c: Dictionary) -> void:
	var ball := Props.model("pirate/cannon-ball")
	ball.scale = Vector3.ONE * 1.3
	add_child(ball)
	ball.position = Vector3(c.lane, DECK_Y + 0.62, DECK_Z.y - 1.4)
	_balls.append({"node": ball, "vel": Vector3(0, 0, -BALL_SPEED), "life": 3.0})
	# Recoil + puff of smoke, and a boom if the player is close enough to hear it.
	var cn: Node3D = c.node
	var t := create_tween()
	t.tween_property(cn, "position:z", DECK_Z.y + 0.2, 0.06)
	t.tween_property(cn, "position:z", DECK_Z.y - 0.2, 0.4)
	_smoke(ball.position, 10)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and player.global_position.distance_to(global_position) < 30:
		Game.sfx("boom", randf_range(0.9, 1.1), -6.0)


func _pop(n: Node3D) -> void:
	_smoke(n.position, 8)
	n.queue_free()


func _smoke(at: Vector3, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.6
	p.explosiveness = 0.9
	p.spread = 180
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.gravity = Vector3(0, 1, 0)
	var m := SphereMesh.new()
	m.radius = 0.18
	m.height = 0.36
	m.radial_segments = 8
	m.rings = 4
	m.material = Props.unshaded(Color(0.95, 0.95, 0.95, 0.8))
	p.mesh = m
	add_child(p)
	p.position = at
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
