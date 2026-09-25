extends Node3D
## "La directora": a stealth challenge. A corridor of hedges with little alcoves along the sides
## leads to the headteacher's office, where the sweet is. The headteacher patrols the corridor;
## her cone of vision is drawn on the floor. If she sees you in the corridor, she tells you a
## school rule and sends you back to the start. Hide in an alcove while she passes, then sneak
## along behind her. The corridor runs along local -Z from the entrance (z=0) to the office.

const LENGTH := 20.0        # corridor length
const HALF_W := 2.4         # half the corridor width (alcoves are beyond this)
const SPEED := 2.3
const VIEW_RANGE := 7.5
const VIEW_HALF_ANGLE := deg_to_rad(38)
const RULES := [
	"¡Está prohibido correr en los pasillos!",
	"¡No se permite usar el móvil!",
	"¡Hay que ser puntual!",
	"¡Está prohibido comer chicle!",
	"¡Hay que respetar a los demás!",
	"¡No se debe llevar piercings!",
]

var sweet: Node3D
var caught_count := 0

var _npc: Node3D
var _anim: AnimationPlayer
var _cone: MeshInstance3D
var _dir := -1.0             # walking towards the office (-Z) or back (+Z)
var _z := -3.0
var _pause := 0.0
var _cool := 0.0
var _t := 0.0


func setup() -> void:
	var hedge := Props.mat(Color(0.25, 0.55, 0.3))
	var floor_mat := Props.mat(Color(0.85, 0.8, 0.7))
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	# Corridor floor (tiles) and hedge walls with alcoves every 5 m.
	_mesh(body, _box(Vector3(HALF_W * 2 + 3.6, 0.06, LENGTH + 2)), Vector3(0, 0.03, -LENGTH / 2.0), floor_mat)
	for side in [-1.0, 1.0]:
		var z := 0.5
		var k := 0
		while z > -LENGTH:
			var seg := 3.0
			if k % 2 == 1:
				# Alcove: a pocket set back into the wall.
				_solid(body, Vector3(0.6, 3.6, 2.4), Vector3(side * (HALF_W + 2.0), 1.8, z - 1.2), hedge)
				_solid(body, Vector3(1.9, 3.6, 0.5), Vector3(side * (HALF_W + 1.0), 1.8, z + 0.05), hedge)
				_solid(body, Vector3(1.9, 3.6, 0.5), Vector3(side * (HALF_W + 1.0), 1.8, z - 2.45), hedge)
				seg = 2.5
			else:
				_solid(body, Vector3(0.6, 3.6, seg), Vector3(side * (HALF_W + 0.3), 1.8, z - seg / 2.0), hedge)
			z -= seg
			k += 1
	# The office at the far end, with the desk the sweet sits on.
	var office_col := Props.mat(Color(0.75, 0.55, 0.85))
	var oz := -LENGTH - 2.0
	_solid(body, Vector3(6.0, 3.6, 0.3), Vector3(0, 1.8, oz - 2.5), office_col)
	_solid(body, Vector3(0.3, 3.6, 5.0), Vector3(-3.0, 1.8, oz), office_col)
	_solid(body, Vector3(0.3, 3.6, 5.0), Vector3(3.0, 1.8, oz), office_col)
	_solid(body, Vector3(6.6, 0.3, 5.6), Vector3(0, 3.75, oz), Props.mat(Color(0.5, 0.3, 0.6)))
	_solid(body, Vector3(2.0, 0.9, 0.9), Vector3(0, 0.45, oz - 1.2), Props.mat(Color(0.6, 0.4, 0.25)))
	var sign := Label3D.new()
	sign.text = "Dirección"
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.outline_size = 14
	sign.outline_modulate = Color(0.4, 0.2, 0.5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(0, 4.5, oz + 2.4)
	add_child(sign)
	var entry := Label3D.new()
	entry.text = "¡Silencio! No correr."
	entry.font = sign.font
	entry.font_size = 44
	entry.pixel_size = 0.006
	entry.outline_size = 12
	entry.outline_modulate = Color(0.4, 0.2, 0.5)
	entry.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	entry.position = Vector3(0, 3.0, 1.2)
	add_child(entry)

	# The headteacher, with her cone of vision on the floor.
	_npc = Props.character("character-female-d")
	_npc.scale = Vector3.ONE * 1.75
	add_child(_npc)
	var anims := _npc.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		_anim = anims[0]
		_anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
		_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		_anim.play("walk")
	_cone = MeshInstance3D.new()
	_cone.mesh = _cone_mesh()
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cone)


func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 0.95, -LENGTH - 3.2))


func start_spot() -> Vector3:
	return to_global(Vector3(0, 0.3, 2.5))


func _physics_process(delta: float) -> void:
	_t += delta
	_cool -= delta
	if Game.ui_open:
		return
	# Patrol up and down, pausing at each end to look around.
	if _pause > 0:
		_pause -= delta
		if _pause <= 0:
			_dir = -_dir
			if _anim:
				_anim.play("walk", 0.2)
	else:
		_z += _dir * SPEED * delta
		var lo := -LENGTH + 1.5
		var hi := -1.0
		if _z < lo or _z > hi:
			_z = clampf(_z, lo, hi)
			_pause = 1.3
			if _anim:
				_anim.play("idle", 0.2)
	_npc.position = Vector3(0, 0, _z)
	var face := 0.0 if _dir > 0 else PI          # model faces +Z at rotation 0
	if _pause > 0:
		face += sin(_t * 2.5) * 0.5              # looks left and right while paused
	_npc.rotation.y = lerp_angle(_npc.rotation.y, face, 1.0 - exp(-8.0 * delta))
	_cone.position = _npc.position + Vector3(0, 0.08, 0)
	_cone.rotation.y = _npc.rotation.y
	_look_for_player()


func _look_for_player() -> void:
	if _cool > 0 or (sweet and is_instance_valid(sweet) and sweet.collected):
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player:
		return
	var lp := to_local(player.global_position)
	# Only the corridor itself counts - alcoves and the office are safe.
	if absf(lp.x) > HALF_W or lp.z > 0.5 or lp.z < -LENGTH - 0.5 or lp.y > 3.5:
		return
	var to := Vector2(lp.x - _npc.position.x, lp.z - _npc.position.z)
	if to.length() > VIEW_RANGE:
		return
	var fwd := Vector2(sin(_npc.rotation.y), cos(_npc.rotation.y))
	if absf(fwd.angle_to(to)) > VIEW_HALF_ANGLE:
		return
	# ¡Pillado!
	_cool = 2.0
	caught_count += 1
	Game.sfx("wrong", 0.8)
	var rule: String = RULES[caught_count % RULES.size()]
	Game.show_toast("La directora: \"%s\" ¡Vuelve a la entrada!" % rule)
	if _anim:
		_anim.play("emote-no", 0.1)
		_anim.queue("walk")
	player.send_to(start_spot())


## A flat fan shape showing where she can see.
func _cone_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 12
	for i in n:
		var a0 := -VIEW_HALF_ANGLE + 2.0 * VIEW_HALF_ANGLE * i / n
		var a1 := -VIEW_HALF_ANGLE + 2.0 * VIEW_HALF_ANGLE * (i + 1) / n
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * VIEW_RANGE)
		st.add_vertex(Vector3(sin(a0), 0, cos(a0)) * VIEW_RANGE)
	var mesh := st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.85, 0.2, 0.35)
	mesh.surface_set_material(0, m)
	return mesh


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
