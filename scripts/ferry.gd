extends Node3D
## "El ferry": a big yellow car ferry moored beside a jetty (it doesn't sail). Walk up the
## gangway, climb the crates onto the containers, and up to the roof of the bridge where
## the sweet is. The ship's length runs along local Z; the bridge is at the +Z end.

const S := 2.8               # model scale
const KEEL_Y := -2.2         # the hull sits low in the water

var model: Node3D


func deck_y() -> float:
	return KEEL_Y + 1.104 * S


func setup(model_name := "water/ship-cargo-a") -> void:
	model = Props.model(model_name)
	model.scale = Vector3.ONE * S
	model.position.y = KEEL_Y
	add_child(model)
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		cs.transform = global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform if is_inside_tree() else _rel(mi)
		body.add_child(cs)
	# A crate by the gangway: an easy first step up towards the containers.
	var crate := Props.model("crate")
	crate.scale = Vector3.ONE * 1.6
	crate.position = Vector3(4.3, deck_y(), 0.2)
	add_child(crate)
	var ccs := CollisionShape3D.new()
	var csh := BoxShape3D.new()
	var box := Props.aabb(crate)
	csh.size = box.size * 1.6
	ccs.shape = csh
	ccs.position = crate.position + Vector3(0, csh.size.y / 2.0, 0)
	body.add_child(ccs)
	var sign := Label3D.new()
	sign.text = str(get_meta("name", "El ferry"))
	sign.font = preload("res://scripts/ui.gd").ui_font(700)
	sign.font_size = 110
	sign.pixel_size = 0.006
	sign.outline_size = 16
	sign.modulate = Color(1, 0.9, 0.3)
	sign.outline_modulate = Color(0.15, 0.25, 0.5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(0, 9.5, 8.0)
	add_child(sign)


## Where the gangway reaches the deck (a gap between the containers), in local space.
func gangway_spot() -> Vector3:
	return Vector3(4.4, deck_y(), -2.0)


## The sweet floats over the roof of the bridge, the highest deck.
func sweet_spot() -> Vector3:
	return to_global(Vector3(0, 6.2, 8.0))


## Container tops, for stars.
func container_tops() -> Array[Vector3]:
	return [to_global(Vector3(0, 4.7, -11)), to_global(Vector3(0, 4.7, -5)), to_global(Vector3(0, 4.7, 1))]


func _rel(n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur and cur != self:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
