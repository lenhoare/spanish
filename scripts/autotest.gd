extends Node
## Developer tool: run with `-- --autotest` to click through the game and save
## screenshots to user://shots (no effect in normal play).

const W := preload("res://scripts/world.gd")

var main: Node
var out_dir := ""


func _ready() -> void:
	out_dir = OS.get_user_data_dir().path_join("shots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("SHOT ", name)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _teleport(p: CharacterBody3D, cam, pos: Vector3, yaw: float) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	cam.yaw = yaw
	cam.global_position = pos + Vector3(0, 1.1, 0)


func _run() -> void:
	await _wait(1.5)
	await _shot("01_title")
	main.ui.show_island_picker()
	await _wait(0.8)
	await _shot("01b_islands")
	main.ui._picker.queue_free()
	main.ui._title.queue_free()
	main._start_game()
	await _wait(1.5)
	await _shot("02_start")
	if "--phone" in OS.get_cmdline_user_args():
		await _phone_pass()
		return

	var p: CharacterBody3D = main.player
	var cam = main.cam
	if Game.game_id == "retos":
		if Game.current_island == 1:
			await _retos2(p, cam)
		elif Game.current_island == 2:
			await _retos3(p, cam)
		elif Game.current_island == 3:
			await _retos4(p, cam)
		elif Game.current_island == 4:
			await _retos5(p, cam)
		elif Game.current_island == 5:
			await _retos6(p, cam)
		else:
			await _retos1(p, cam)
		return
	if Game.current_island == 1:
		await _island2(p, cam)
		return
	if Game.current_island == 2:
		await _island3(p, cam)
		return
	if Game.current_island == 3:
		await _island4(p, cam)
		return
	if Game.current_island == 4:
		await _island5(p, cam)
		return
	if Game.current_island == 5:
		await _island6(p, cam)
		return

	# Movement checks: run forward, jump, use the spring.
	var start := p.global_position
	Input.action_press("move_forward")
	await _wait(1.0)
	Input.action_release("move_forward")
	print("MOVE: moved %.2f m" % start.distance_to(p.global_position))
	var y0 := p.global_position.y
	var peak := y0
	Input.action_press("jump")
	for i in 40:
		await get_tree().physics_frame
		peak = maxf(peak, p.global_position.y)
	Input.action_release("jump")
	print("JUMP: peak height %.2f m" % (peak - y0))
	await _wait(0.8)
	_teleport(p, cam, Vector3(12.8, 1.5, -5.2), 0.0)
	peak = 0.0
	for i in 90:
		await get_tree().physics_frame
		peak = maxf(peak, p.global_position.y)
	print("SPRING: peak y %.2f (tower top is 5.0)" % peak)
	await _wait(1.0)

	# Look around the bigger island.
	var views := [
		["03_start_view", Vector3(0, 0.2, 14), 0.0],
		["04_tower_and_shop", Vector3(8, 0.2, -2), -0.7],
		["05_ghost_garden", Vector3(-10, 0.2, 22), 0.9],
		["06_west_island", Vector3(-25, 0.2, 14), 1.57],
		["07_east_islands", Vector3(22, 0.2, 10), -1.3],
		["08_bridge", Vector3(0, 0.2, -24), 0.0],
		["09_islet_path", Vector3(8, 0.2, 18), -0.9],
	]
	for v in views:
		_teleport(p, cam, v[1], v[2])
		await _wait(0.9)
		await _shot(v[0])

	# Whiteboard: walking into the zone must NOT open it; jumping must.
	_teleport(p, cam, Vector3(0, 0.2, 4), 0.0)
	Input.action_press("move_forward")
	await _wait(0.7)
	Input.action_release("move_forward")
	await _wait(0.3)
	var opened_by_walking := Game.ui_open
	Input.action_press("jump")
	await _wait(0.25)
	Input.action_release("jump")
	await _wait(1.0)
	print("WHITEBOARD: opened_by_walking=%s opened_by_jump=%s (want false/true)" % [opened_by_walking, Game.ui_open])
	await _shot("10_lesson_first")
	main.ui._lesson_closed.emit()
	await _wait(0.5)

	# --- Sweet 1: key -> sweet shop door -> cupcake question
	_teleport(p, cam, W.SWEET_SHOP + (-W.SWEET_SHOP.normalized()) * 6.5, 0.0)
	await _wait(0.6)
	print("SHOP: door opened without key? %s (want false)" % main.world.get_children().any(func(n): return n.has_method("setup") and "opened" in n and n.opened))
	_teleport(p, cam, main.world.KEY_SPOT + Vector3(0, 0.2, 2.0), 0.0)
	Input.action_press("move_forward")
	await _wait(0.6)
	Input.action_release("move_forward")
	await _wait(0.5)
	print("KEY: has_key=%s (want true)" % Game.has_key)
	await _shot("20_key_hud")
	var to_c := -W.SWEET_SHOP.normalized()
	_teleport(p, cam, W.SWEET_SHOP + to_c * 6.5 + Vector3(0, 0.2, 0), atan2(-to_c.x, -to_c.z) + PI)
	await _wait(1.8)
	await _shot("21_shop_door_open")
	# Walk in through the door.
	cam.yaw = atan2(to_c.x, to_c.z)
	Input.action_press("move_forward")
	await _wait(1.4)
	Input.action_release("move_forward")
	await _wait(0.6)
	var in_panel := Game.ui_open
	print("SHOP: walked in, sweet question open=%s (want true)" % in_panel)
	await _shot("22_sweet_question")
	if in_panel:
		main.ui._question_done.emit("correct")
		await _wait(1.5)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])

	# --- Sweet 2: the ghost
	var ghost = main.world.ghost
	Game.add_coins(5)
	var coins_before := Game.coins
	# Stand still right where the ghost is heading.
	_teleport(p, cam, ghost.global_position + Vector3(0, 0, 0), 0.0)
	await _wait(1.0)
	print("GHOST HIT: coins %d -> %d (want fewer), lollipop stolen=%s (want true)" % [coins_before, Game.coins, ghost.guarded_sweet.is_stolen()])
	await _shot("30_ghost")
	# Stomp: drop onto the ghost from above.
	await _wait(1.5)
	var gp: Vector3 = ghost.global_position
	_teleport(p, cam, gp + Vector3(0, 2.4, 0), 0.0)
	p.velocity = Vector3(0, -3, 0)
	await _wait(0.3)
	print("GHOST STOMP: stunned=%s (want true), lollipop back=%s (want true)" % [ghost._stun > 0, not ghost.guarded_sweet.is_stolen()])
	# Grab the lollipop while it's dizzy.
	_teleport(p, cam, W.GHOST_GARDEN + Vector3(0, 1.5, 0), 0.0)
	await _wait(0.5)
	print("GHOST SWEET: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.5)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])

	# Chest levels: level 2 is locked until both level 1 chests are open.
	var chests: Array = main.world.chests
	var l2 = chests.filter(func(ch): return ch.level == 2)[0]
	main._on_chest(l2)
	await _wait(0.3)
	print("CHEST L2 before: locked=%s, panel opened=%s (want true/false)" % [l2.level_locked, Game.ui_open])
	for ch in chests.filter(func(ch): return ch.level == 1):
		main._on_chest(ch)
		await _wait(0.2)
		main.ui._question_done.emit("correct")
		await _wait(0.4)
	await _wait(3.0)
	print("CHEST L2 after opening both L1: locked=%s (want false); L3 locked=%s (want true)" % [l2.level_locked, chests.filter(func(ch): return ch.level == 3)[0].level_locked])
	await _shot("35_chest_levels")

	# Answer every card, then cross the bridge.
	for c in main.world.cards.duplicate():
		main._on_card(c)
		await _wait(0.2)
		main.ui._question_done.emit("correct")
		await _wait(1.8)
	print("CARDS: solved %d/%d, bridge built %d/%d" % [Game.cards_solved, Game.total_cards, main.world.bridge.built, main.world.bridge.sections])
	_teleport(p, cam, Vector3(0, 0.2, -26), 0.0)
	cam.pitch = deg_to_rad(-15)
	await _wait(1.2)
	await _shot("40_bridge_built")
	Input.action_press("move_forward")
	var t0 := Time.get_ticks_msec()
	while p.global_position.z > main.world.PRIZE_CENTER.z + 0.8 and not Game.ui_open and Time.get_ticks_msec() - t0 < 9000:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	print("BRIDGE WALK: reached z=%.1f" % p.global_position.z)
	await _wait(3.0)
	print("RESULTS SHOWN: %s" % Game.ui_open)
	await _shot("50_results")
	get_tree().quit()


## Island 2: pirate ship (gangplank, cannons, deck sweet, rigging climb, crow's nest) and the chef.
func _island2(p: CharacterBody3D, cam) -> void:
	var w = main.world
	var ship: Node3D = w.ship
	print("ISLAND2: sweets total=%d ingredients total=%d" % [Game.total_sweets, Game.ingredients_total])
	_teleport(p, cam, Vector3(2, 0.2, 21), PI - 0.45)
	cam.pitch = deg_to_rad(-8)
	await _wait(1.2)
	await _shot("i2_01_ship_from_island")

	# Walk from the jetty up the gangplank (towards +X, i.e. yaw -90 degrees).
	_teleport(p, cam, ship.to_global(Vector3(-9.3, 2.3, -1.0)), -PI / 2)
	await _wait(0.5)
	Input.action_press("move_forward")
	await _wait(1.6)
	Input.action_release("move_forward")
	await _wait(0.8)
	var local := ship.to_local(p.global_position)
	print("GANGPLANK: player now at ship-local %s (deck is y=3.36, |x|<3.4) on_floor=%s" % [local, p.is_on_floor()])
	cam.yaw = PI   # look towards the bow and the cannons
	await _wait(0.6)
	await _shot("i2_02_on_deck")

	# Stand in a cannon lane and wait to be hit.
	await _wait(1.0)   # let any earlier "back to the gangplank" finish first
	var hits_before: int = ship.hits
	_teleport(p, cam, ship.to_global(Vector3(-1.6, 3.5, -2.5)), PI)
	await _wait(0.5)
	print("LANE: standing at ship-local %s on_floor=%s" % [ship.to_local(p.global_position), p.is_on_floor()])
	await _wait(5.0)
	var after_hit := ship.to_local(p.global_position)
	print("CANNONS: hits %d -> %d (want more); sent back to gangplank? local=%s (want x about -9.4)" % [hits_before, ship.hits, after_hit])
	await _shot("i2_03_cannons")

	# Deck sweet.
	_teleport(p, cam, ship.to_global(ship.deck_sweet_spot() + Vector3(0, 0.3, 0.8)), 0.0)
	await _wait(0.6)
	print("DECK SWEET: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		await _shot("i2_04_deck_question")
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# Rigging: every plank should be standable, and the nest reachable from the top plank.
	var ok := 0
	var steps: Array[Vector3] = ship.climb_steps()
	for s in steps:
		_teleport(p, cam, ship.to_global(s + Vector3(0, 0.3, 0)), 0.0)
		await _wait(0.35)
		if p.is_on_floor() and ship.to_local(p.global_position).y > s.y - 0.2:
			ok += 1
	print("RIGGING: standable planks %d / %d" % [ok, steps.size()])
	# Real jumps between the first two planks: start on the forecastle, jump to plank 0, then plank 1.
	_teleport(p, cam, ship.to_global(Vector3(-1.0, 4.8, 5.8)), 0.0)
	await _wait(0.5)
	Input.action_press("jump")
	Input.action_press("move_forward")
	await _wait(0.45)
	Input.action_release("move_forward")
	Input.action_release("jump")
	await _wait(0.6)
	print("CLIMB JUMP: forecastle -> plank 0: y=%.2f (plank 0 top ~%.2f)" % [ship.to_local(p.global_position).y, steps[0].y + 0.09])
	# Sideways-and-up jump to plank 1 (to the +X side).
	_teleport(p, cam, ship.to_global(steps[0] + Vector3(0, 0.2, 0)), 0.0)
	await _wait(0.4)
	var to1: Vector3 = ship.global_transform.basis * (steps[1] - steps[0])
	cam.yaw = atan2(-to1.x, -to1.z)
	await _wait(0.1)
	Input.action_press("jump")
	Input.action_press("move_forward")
	await _wait(0.4)
	Input.action_release("move_forward")
	Input.action_release("jump")
	await _wait(0.8)
	print("CLIMB JUMP: plank 0 -> plank 1: y=%.2f (plank 1 top ~%.2f)" % [ship.to_local(p.global_position).y, steps[1].y + 0.09])
	_teleport(p, cam, ship.to_global(steps[-1] + Vector3(0, 0.3, 0)), 0.0)
	await _wait(0.5)
	await _shot("i2_05_top_plank")
	# Real jump from the top plank into the nest: face the mast and jump.
	var world_in: Vector3 = ship.global_transform.basis * (Vector3(0, 0, -0.5) - Vector3(steps[-1].x, 0, steps[-1].z))
	cam.yaw = atan2(-world_in.x, -world_in.z)
	await _wait(0.2)
	Input.action_press("jump")
	Input.action_press("move_forward")
	await _wait(0.6)
	Input.action_release("jump")
	await _wait(0.4)
	Input.action_release("move_forward")
	await _wait(0.8)
	print("NEST: jumped in, ship-local y=%.2f (nest floor 12.7), sweet question open=%s" % [ship.to_local(p.global_position).y, Game.ui_open])
	await _shot("i2_06_crows_nest")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS after ship: %d / %d" % [Game.sweets, Game.total_sweets])

	# Chef: no ingredients -> no question; collect all three -> question.
	var cafe: Node3D = w.cafe
	var front: Vector3 = cafe.to_global(Vector3(0, 0.2, 2.3))
	_teleport(p, cam, front + (front - cafe.global_position).normalized() * 3.0, 0.0)
	await _wait(0.3)
	cam.yaw = atan2(-(cafe.global_position - p.global_position).x, -(cafe.global_position - p.global_position).z)
	await _wait(0.8)
	await _shot("i2_07_cafe")
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("CHEF without ingredients: question open=%s (want false)" % Game.ui_open)
	for spot in w.QUESTS.chef.items:
		_teleport(p, cam, spot[3] + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("INGREDIENTS: %s" % [Game.ingredients])
	await _shot("i2_08_ingredients_hud")
	_teleport(p, cam, front + Vector3(0, 0, 0) + (front - cafe.global_position).normalized() * 3.0, cam.yaw)
	await _wait(0.4)
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("CHEF with ingredients: question open=%s (want true)" % Game.ui_open)
	await _shot("i2_09_chef_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])
	get_tree().quit()


## Island 3: the healthy-food field and the trainer's quest.
func _island3(p: CharacterBody3D, cam) -> void:
	var w = main.world
	var field: Node3D = w.healthy_field
	print("ISLAND3: sweets total=%d quest items=%d" % [Game.total_sweets, Game.ingredients_total])
	var edge: Vector3 = field.global_position + (-field.global_position.normalized()) * (field.RADIUS + 3.0)
	var look: Vector3 = field.global_position - edge
	_teleport(p, cam, edge + Vector3(0, 0.2, 0), atan2(-look.x, -look.z))
	cam.pitch = deg_to_rad(-25)
	await _wait(1.2)
	await _shot("i3_01_field")
	# Walk into a junk item: should knock back and reset the count.
	field.count = 3
	var junk: Node3D = field._junk[0].node
	_teleport(p, cam, junk.global_position + Vector3(0, 0.1, 0), cam.yaw)
	await _wait(0.4)
	print("JUNK: count after touching junk = %d (want 0)" % field.count)
	await _wait(1.5)
	# Collect healthy food until the goal is reached.
	var tries := 0
	while not field.done and tries < 30:
		tries += 1
		if field._healthy.is_empty():
			await _wait(1.0)
			continue
		var h: Node3D = field._healthy[0].node
		_teleport(p, cam, h.global_position + Vector3(0, -0.3, 0), cam.yaw)
		await _wait(0.3)
	print("HEALTHY: done=%s count=%d after %d tries, sweet visible=%s" % [field.done, field.count, tries, field._sweet.visible])
	await _wait(1.0)
	_teleport(p, cam, field.global_position + Vector3(0.6, 1.6, 0), cam.yaw)   # onto the pedestal
	await _wait(0.8)
	print("FIELD SWEET: question open=%s (want true)" % Game.ui_open)
	await _shot("i3_02_field_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# Trainer quest.
	var stall: Node3D = w.cafe
	var front: Vector3 = stall.to_global(Vector3(0, 0.2, 2.3))
	var back_off: Vector3 = front + (front - stall.global_position).normalized() * 4.0
	var to_stall: Vector3 = stall.global_position - back_off
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("i3_03_gym_stall")
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("TRAINER without items: question open=%s (want false)" % Game.ui_open)
	for item in w.QUESTS.trainer.items:
		_teleport(p, cam, item[3] + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("ITEMS: %s" % [Game.ingredients])
	_teleport(p, cam, back_off, cam.yaw)
	await _wait(0.4)
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("TRAINER with items: question open=%s (want true)" % Game.ui_open)
	await _shot("i3_04_trainer_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])

	# Skateboard: jump onto it while moving; it should roll off carrying the player.
	var board: Node3D = w.skateboard
	var start: Vector3 = board.global_position
	var dir := (Vector3(0, 0, 0) - start)
	dir.y = 0
	dir = dir.normalized()
	_teleport(p, cam, start - dir * 1.2 + Vector3(0, 1.4, 0), atan2(-dir.x, -dir.z))
	p.velocity = dir * 5.0
	await _wait(0.2)
	Input.action_press("move_forward")
	await _wait(0.25)
	Input.action_release("move_forward")
	var p0 := p.global_position
	var b0: Vector3 = board.global_position
	await _wait(0.5)
	print("SKATEBOARD ride: in 0.5s board moved %.1f m, player moved %.1f m" % [board.global_position.distance_to(b0), p.global_position.distance_to(p0)])
	await _wait(0.7)
	var moved: float = board.global_position.distance_to(start)
	var riding: bool = p.global_position.distance_to(board.global_position) < 1.2
	print("SKATEBOARD: board moved %.1f m, player riding=%s, speed now %.1f" % [moved, riding, board.vel.length()])
	await _shot("i3_05_skateboard")
	# Abandoned away from the gym, it goes home.
	await _wait(3.0)
	_teleport(p, cam, Vector3(-20, 0.3, 20), 0.0)
	await _wait(8.0)
	print("SKATEBOARD abandoned: %.1f m from home (want ~0) vel=%s idle=%.1f home=%s pos=%s" % [board.global_position.distance_to(board.home), board.vel, board._idle, board.home, board.global_position])
	get_tree().quit()


## Island 4: row to Isla Secreta; the recycler's quest.
func _island4(p: CharacterBody3D, cam) -> void:
	var w = main.world
	var boat: Node3D = w.rowboat
	print("ISLAND4: sweets total=%d quest items=%d" % [Game.total_sweets, Game.ingredients_total])
	var d: Vector3 = w.BOAT_DIR
	# Stand on the jetty, look out to sea at the boat.
	_teleport(p, cam, d * (w.MAIN_R + 3.0) + Vector3(0, 0.3, 0), atan2(-d.x, -d.z))
	cam.pitch = deg_to_rad(-14)
	await _wait(1.2)
	await _shot("i4_01_jetty")
	# Walk off the end of the jetty and hop into the boat.
	Input.action_press("move_forward")
	await _wait(0.9)
	Input.action_press("jump")
	await _wait(0.3)
	Input.action_release("jump")
	await _wait(0.6)
	Input.action_release("move_forward")
	await _wait(0.5)
	print("BOARD: riding=%s" % (p.vehicle != null))
	if p.vehicle == null:
		_teleport(p, cam, boat.global_position + Vector3(0, 1.5, 0), cam.yaw)
		await _wait(0.5)
		print("BOARD (dropped in): riding=%s" % (p.vehicle != null))
	# Row out a bit and try to get out at sea: should be refused.
	var goal := Vector2(w.SECRET_ISLAND.x, w.SECRET_ISLAND.z)
	var steps := 0
	var reached := false
	Input.action_press("move_forward")
	while steps < 200:
		steps += 1
		var bp := Vector2(boat.global_position.x, boat.global_position.z)
		var to := goal - bp
		cam.yaw = atan2(-to.x, -to.y)
		if steps == 25:
			Input.action_release("move_forward")
			await _wait(0.2)
			Input.action_press("jump")
			await get_tree().physics_frame
			await get_tree().physics_frame
			Input.action_release("jump")
			print("EXIT AT SEA: still riding=%s (want true)" % (p.vehicle != null))
			await _shot("i4_02_rowing")
			Input.action_press("move_forward")
		if to.length() - w.SECRET_R < 4.5:
			reached = true
			break
		await _wait(0.15)
	Input.action_release("move_forward")
	print("ROW: reached Isla Secreta=%s after %.1f s, boat at %s" % [reached, steps * 0.15, boat.global_position])
	await _wait(0.8)
	await _shot("i4_03_arrived")
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	await _wait(1.2)
	var on_isle: bool = Vector2(p.global_position.x - w.SECRET_ISLAND.x, p.global_position.z - w.SECRET_ISLAND.z).length() < w.SECRET_R
	print("LAND: riding=%s on Isla Secreta=%s y=%.2f" % [p.vehicle != null, on_isle, p.global_position.y])
	# Walk to the sweet.
	var sweet_at: Vector3 = w.SECRET_ISLAND + Vector3(-0.5, 0.3, -0.5)
	_teleport(p, cam, sweet_at, cam.yaw)
	await _wait(0.6)
	print("BOAT SWEET: question open=%s (want true)" % Game.ui_open)
	await _shot("i4_04_secret_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# Jump into the sea: should splash back into the boat.
	_teleport(p, cam, boat.global_position + Vector3(3.0, -2.0, 0), cam.yaw)
	p.velocity = Vector3(0, -10, 0)
	await _wait(1.0)
	print("SPLASH: back in boat=%s" % (p.vehicle == boat))
	# Row to the secret white ship and hop onto its deck.
	var row_to := func(target: Vector2, gap: float) -> bool:
		Input.action_press("move_forward")
		for i in 400:
			var bp := Vector2(boat.global_position.x, boat.global_position.z)
			var to := target - bp
			cam.yaw = atan2(-to.x, -to.y)
			if to.length() < gap:
				Input.action_release("move_forward")
				return true
			await _wait(0.15)
		Input.action_release("move_forward")
		return false
	var ws := Vector2(w.WHITE_SHIP.x, w.WHITE_SHIP.z)
	# Row round the west and south coasts rather than through the island.
	for wp in [Vector2(-72, 20), Vector2(-30, 62), Vector2(30, 70)]:
		await row_to.call(wp, 6.0)
	var ok: bool = await row_to.call(ws, 9.0)
	print("ROW to white ship: reached=%s" % ok)
	await _wait(0.8)
	await _shot("i4_06_white_ship")
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	await _wait(1.5)
	print("DECK: riding=%s player y=%.2f (deck ~1.2)" % [p.vehicle != null, p.global_position.y])
	var sweet_node = w.sweets.filter(func(s): return is_instance_valid(s) and s.get_meta("area") == w.WHITE_SHIP)[0]
	_teleport(p, cam, sweet_node.global_position + Vector3(0, 0.4, 0.3), cam.yaw)
	await _wait(0.6)
	print("SHIP SWEET: question open=%s (want true)" % Game.ui_open)
	await _shot("i4_07_ship_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	# Back into the boat (jump in the sea), then sneak to Star Island before the bridge is built.
	_teleport(p, cam, boat.global_position + Vector3(2.0, -2.5, 0), cam.yaw)
	p.velocity = Vector3(0, -10, 0)
	await _wait(1.0)
	for wp in [Vector2(75, 5), Vector2(40, -55)]:
		await row_to.call(wp, 6.0)
	ok = await row_to.call(Vector2(w.PRIZE_CENTER.x, w.PRIZE_CENTER.z), 10.0)
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	await _wait(1.2)
	var coins_before := Game.coins
	_teleport(p, cam, w.PRIZE_CENTER + Vector3(0, 0.4, 0.5), cam.yaw)
	await _wait(1.0)
	print("SNEAKY: reached=%s coins %d -> %d, prize claimed=%s (want false)" % [ok, coins_before, Game.coins, Game.ui_open])
	await _shot("i4_08_sneaky")

	# Recycler quest.
	var stall: Node3D = w.cafe
	var front: Vector3 = stall.to_global(Vector3(0, 0.2, 2.3))
	var back_off: Vector3 = front + (front - stall.global_position).normalized() * 4.0
	var to_stall: Vector3 = stall.global_position - back_off
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("i4_05_recycling_stall")
	for item in w.QUESTS.recycler.items:
		_teleport(p, cam, item[3] + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("ITEMS: %s" % [Game.ingredients])
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	await _wait(0.4)
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("RECYCLER with items: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])
	get_tree().quit()


## Island 5: El circuito (real jumps between every piece) and the tourist's quest.
func _island5(p: CharacterBody3D, cam) -> void:
	var w = main.world
	var ci: Node3D = w.circuit
	print("ISLAND5: sweets total=%d quest items=%d" % [Game.total_sweets, Game.ingredients_total])
	var fwd: Vector3 = ci.global_transform.basis.x
	var course_yaw := atan2(-fwd.x, -fwd.z)
	_teleport(p, cam, ci.to_global(Vector3(-3, 0.3, 0)), course_yaw)
	cam.pitch = deg_to_rad(-16)
	await _wait(1.2)
	await _shot("i5_01_circuit")
	# Start: walk over the start line.
	Input.action_press("move_forward")
	await _wait(0.5)
	Input.action_release("move_forward")
	await _wait(0.3)
	print("START: running=%s time=%.1f" % [ci.running, ci.time_left])
	await _shot("i5_02_timer")
	# Real jumps like a player: aim at the next piece, let go of forward once above it.
	ci.running = false
	ci._cool = 9999.0     # keep the start line from restarting the clock during the hops
	var hop := func(src: Vector3, dst: Vector3, label: String) -> bool:
		_teleport(p, cam, ci.to_global(src + Vector3(0, 0.3, 0)), 0.0)
		var tg: Vector3 = ci.to_global(dst)
		var dirv: Vector3 = tg - p.global_position
		cam.yaw = atan2(-dirv.x, -dirv.z)
		await _wait(0.35)
		Input.action_press("jump")
		Input.action_press("move_forward")
		for i in 60:
			await get_tree().physics_frame
			if i == 18:
				Input.action_release("jump")
			var hd := Vector2(p.global_position.x - tg.x, p.global_position.z - tg.z).length()
			if hd < 0.35:
				Input.action_release("move_forward")
		Input.action_release("move_forward")
		Input.action_release("jump")
		await _wait(0.5)
		var l: Vector3 = ci.to_local(p.global_position)
		var good: bool = p.is_on_floor() and Vector2(l.x - dst.x, l.z - dst.z).length() < 1.0 and l.y > dst.y - 0.3
		if not good:
			print("  HOP FAILED %s: landed at local %s floor=%s" % [label, l, p.is_on_floor()])
		return good
	var pieces := [
		[Vector3(2.5, 0.0, 0), Vector3(5.5, 0.0, 0.6), "pad -> stone 1"],
		[Vector3(5.5, 0.0, 0.6), Vector3(8.1, 0.0, -0.6), "stone 1 -> stone 2"],
		[Vector3(8.1, 0.0, -0.6), Vector3(10.7, 0.0, 0.6), "stone 2 -> stone 3"],
		[Vector3(10.7, 0.0, 0.6), Vector3(13.3, 0.0, 0), "stone 3 -> dock"],
		[Vector3(13.3, 0.0, 0), Vector3(15.8, 0.0, 0), "over hurdle 1"],
		[Vector3(15.8, 0.0, 0), Vector3(18.3, 0.0, 0), "over hurdle 2"],
		[Vector3(18.3, 0.0, 0), Vector3(20.8, 0.0, 0), "over hurdle 3"],
		[Vector3(20.8, 0.0, 0), Vector3(22.0, 0.8, 0), "dock -> step"],
		[Vector3(22.0, 0.8, 0), Vector3(23.6, 0.93, 0), "step -> beam"],
		[Vector3(29.0, 0.93, 0), Vector3(30.5, 1.3, 0), "beam -> post 1"],
		[Vector3(30.5, 1.3, 0), Vector3(32.8, 2.0, 0), "post 1 -> post 2"],
		[Vector3(32.8, 2.0, 0), Vector3(35.0, 2.7, 0), "post 2 -> post 3"],
	]
	var ok := 0
	for pc in pieces:
		var landed: bool = await hop.call(pc[0], pc[1], pc[2])
		if landed:
			ok += 1
	print("HOPS: %d / %d landed" % [ok, pieces.size()])
	# Walk the beam end to end.
	_teleport(p, cam, ci.to_global(Vector3(23.2, 1.2, 0)), course_yaw)
	await _wait(0.4)
	Input.action_press("move_forward")
	await _wait(0.8)
	Input.action_release("move_forward")
	await _wait(0.3)
	var lb: Vector3 = ci.to_local(p.global_position)
	print("BEAM: walked to local x=%.1f still on beam=%s" % [lb.x, p.is_on_floor() and lb.y > 0.8])
	# Can we stand on the sliding platform at all?
	_teleport(p, cam, ci._mover.global_position + Vector3(0, 0.6, 0), course_yaw)
	await _wait(0.6)
	print("  STAND on mover: floor=%s local %s mover %s" % [p.is_on_floor(), ci.to_local(p.global_position), ci._mover.position])
	# Post 3 -> sliding platform (when it's lined up), then platform -> finish.
	while absf(ci._mover.position.z) > 0.3 or cos(ci._mover_t * ci.MOVER_SPEED) < 0:
		await get_tree().physics_frame
	var got_on: bool = await hop.call(Vector3(35.0, 2.7, 0), Vector3(38.8, 2.7, ci._mover.position.z + 0.8), "post 3 -> sliding platform")
	print("MOVER: on platform=%s" % got_on)
	ci._cool = 0.0
	ci.running = true
	ci.time_left = 20.0
	var made_it: bool = await hop.call(Vector3(39.9, 2.7, ci._mover.position.z), Vector3(44.5, 2.7, 0), "sliding platform -> finish")
	await _wait(0.5)
	print("FINISH: done=%s sweet visible=%s" % [ci.done, ci.sweet.visible])
	await _shot("i5_03_finish")
	_teleport(p, cam, ci.sweet.global_position + Vector3(0, 0.3, 0.2), course_yaw)
	await _wait(0.6)
	print("CIRCUIT SWEET: question open=%s (want true)" % Game.ui_open)
	await _shot("i5_04_question")
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# Tourist quest.
	var stall: Node3D = w.cafe
	var front: Vector3 = stall.to_global(Vector3(0, 0.2, 2.3))
	var back_off: Vector3 = front + (front - stall.global_position).normalized() * 4.0
	var to_stall: Vector3 = stall.global_position - back_off
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("i5_05_souvenir_stall")
	for item in w.QUESTS.tourist.items:
		_teleport(p, cam, item[3] + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("ITEMS: %s" % [Game.ingredients])
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	await _wait(0.4)
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("TOURIST with items: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])
	get_tree().quit()


## A real jump from one spot to another (global positions), aiming and letting go like a player.
func _hop(p: CharacterBody3D, cam, src: Vector3, dst: Vector3) -> bool:
	_teleport(p, cam, src + Vector3(0, 0.3, 0), 0.0)
	var dirv := dst - src
	cam.yaw = atan2(-dirv.x, -dirv.z)
	await _wait(0.35)
	Input.action_press("jump")
	Input.action_press("move_forward")
	for i in 60:
		await get_tree().physics_frame
		if i == 18:
			Input.action_release("jump")
		if Vector2(p.global_position.x - dst.x, p.global_position.z - dst.z).length() < 0.35:
			Input.action_release("move_forward")
	Input.action_release("move_forward")
	Input.action_release("jump")
	await _wait(0.5)
	return p.is_on_floor() and Vector2(p.global_position.x - dst.x, p.global_position.z - dst.z).length() < 1.0 and p.global_position.y > dst.y - 0.3


## Island 6: routine pads, speedboat to La Torre and the climb, La profesora.
func _island6(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("ISLAND6: sweets total=%d quest items=%d" % [Game.total_sweets, Game.ingredients_total])
	var r: Node3D = w.routine
	var hut: Node3D = r.hut
	var look: Vector3 = hut.global_position - r.to_global(Vector3(0, 0, 9))
	_teleport(p, cam, r.to_global(Vector3(0, 0.3, 9.0)), atan2(-look.x, -look.z))
	cam.pitch = deg_to_rad(-22)
	await _wait(1.2)
	await _shot("i6_01_routine")
	# Wrong first pad, then the right order.
	_teleport(p, cam, r.to_global(r.SPOTS["me ducho"] + Vector3(0, 0.4, 0)), cam.yaw)
	await _wait(1.3)
	print("ROUTINE wrong pad: next=%d (want 0)" % r._next)
	for phrase in r.ORDER:
		_teleport(p, cam, r.to_global(Vector3(0, 0.4, 9.0)), cam.yaw)
		await _wait(0.2)
		_teleport(p, cam, r.to_global(r.SPOTS[phrase] + Vector3(0, 0.4, 0)), cam.yaw)
		await _wait(0.35)
	print("ROUTINE: solved=%s door open=%s" % [r.done, hut.opened])
	await _wait(1.2)
	await _shot("i6_02_routine_open")
	# Walk in through the door.
	_teleport(p, cam, hut.to_global(Vector3(0, 0.3, 6.5)), atan2(-look.x, -look.z))
	Input.action_press("move_forward")
	await _wait(1.6)
	Input.action_release("move_forward")
	await _wait(0.6)
	print("ROUTINE SWEET: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# Speedboat to La Torre.
	var boat: Node3D = w.speedboat
	var d: Vector3 = w.SPEED_DIR
	_teleport(p, cam, d * (w.MAIN_R + 3.0) + Vector3(0, 0.3, 0), atan2(-d.x, -d.z))
	cam.pitch = deg_to_rad(-14)
	await _wait(1.0)
	await _shot("i6_03_speed_jetty")
	_teleport(p, cam, boat.global_position + Vector3(0, 1.5, 0), cam.yaw)
	await _wait(0.5)
	print("SPEEDBOAT: riding=%s" % (p.vehicle == boat))
	var goal := Vector2(w.TOWER_ISLE.x, w.TOWER_ISLE.z)
	var t0 := Time.get_ticks_msec()
	var reached := false
	Input.action_press("move_forward")
	for i in 300:
		var bp := Vector2(boat.global_position.x, boat.global_position.z)
		var to := goal - bp
		cam.yaw = atan2(-to.x, -to.y)
		if i == 20:
			await _shot("i6_04_speeding")
		if to.length() - w.TOWER_ISLE_R < 4.5:
			reached = true
			break
		await _wait(0.1)
	Input.action_release("move_forward")
	print("SPEED RUN: reached La Torre=%s in %.1f s" % [reached, (Time.get_ticks_msec() - t0) / 1000.0])
	await _wait(2.0)
	print("  boat speed after letting go 2s: %.1f" % boat.vel.length())
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	await _wait(1.0)
	print("LAND on La Torre isle: riding=%s" % (p.vehicle != null))
	await _shot("i6_05_tower")
	# Climb: ground -> plank 0 -> ... -> plank 10 -> lookout, all real jumps.
	var steps := []
	for i in 11:
		var a := i * deg_to_rad(40)
		var y: float = 1.1 + i * ((w.TOWER_TOP - 1.2 - 1.1) / 10.0)
		steps.append(w.TOWER_ISLE + Vector3(cos(a) * 3.8, y + 0.1, sin(a) * 3.8))
	var ok := 0
	var first_from: Vector3 = w.TOWER_ISLE + Vector3(5.3, 0.0, -1.8)
	if await _hop(p, cam, first_from, steps[0]):
		ok += 1
	else:
		print("  CLIMB FAILED ground -> plank 0 (at %s)" % p.global_position)
	for i in range(1, steps.size()):
		if await _hop(p, cam, steps[i - 1], steps[i]):
			ok += 1
		else:
			print("  CLIMB FAILED plank %d -> %d (at %s)" % [i - 1, i, p.global_position])
	var top_ok: bool = await _hop(p, cam, steps[-1], w.TOWER_ISLE + Vector3(0.9, w.TOWER_TOP, 0.9))
	print("CLIMB: %d / %d planks, onto the lookout=%s, question open=%s" % [ok, steps.size(), top_ok, Game.ui_open])
	await _shot("i6_06_top")
	if not Game.ui_open:
		_teleport(p, cam, w.TOWER_ISLE + Vector3(0.6, w.TOWER_TOP + 0.3, 0.6), 0.0)
		await _wait(0.6)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)

	# La profesora.
	var stall: Node3D = w.cafe
	var front: Vector3 = stall.to_global(Vector3(0, 0.2, 2.3))
	var back_off: Vector3 = front + (front - stall.global_position).normalized() * 4.0
	var to_stall: Vector3 = stall.global_position - back_off
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("i6_07_escuela")
	for item in w.QUESTS.teacher.items:
		_teleport(p, cam, item[3] + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("ITEMS: %s" % [Game.ingredients])
	_teleport(p, cam, back_off, atan2(-to_stall.x, -to_stall.z))
	await _wait(0.4)
	_teleport(p, cam, front, cam.yaw)
	await _wait(0.8)
	print("TEACHER with items: question open=%s (want true)" % Game.ui_open)
	if Game.ui_open:
		main.ui._question_done.emit("correct")
		await _wait(1.2)
	print("SWEETS: %d / %d" % [Game.sweets, Game.total_sweets])
	get_tree().quit()


# ---------------------------------------------------------------- panel helpers (retos)

func _all(n: Node, out: Array) -> Array:
	out.append(n)
	for ch in n.get_children():
		_all(ch, out)
	return out


func _button(text: String) -> Button:
	for n in _all(main.ui.root, []):
		if n is Button and (n as Button).visible and (n as Button).text == text:
			return n
	return null


func _press(text: String) -> bool:
	var b := _button(text)
	if b:
		b.pressed.emit()
	return b != null


func _first(cls: String) -> Node:
	for n in _all(main.ui.root, []):
		if n.is_class(cls) and n.visible:
			return n
	return null


## La Isla de los Retos, Isla 1: postcards, the notice board, the detective, and the sentence sweets.
func _retos1(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS1: retos=%d sweets=%d quest items=%d island radius=%.0f" % [Game.total_retos, Game.total_sweets, Game.ingredients_total, w.MAIN_R])
	_teleport(p, cam, Vector3(0, 0.3, 30), 0.0)
	cam.pitch = deg_to_rad(-18)
	await _wait(1.2)
	await _shot("r1_02_outer_ring")
	var postcards: Array = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "postcard")
	var notice = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "notice")[0]
	var det = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "detective")[0]

	# Postcard 1: write a 5-star answer.
	var pc = postcards[0]
	var look: Vector3 = pc.global_position
	_teleport(p, cam, pc.global_position + (-pc.global_position.normalized()) * 5.0 + Vector3(0, 0.3, 0), 0.0)
	cam.yaw = atan2(-(look - p.global_position).x, -(look - p.global_position).z)
	await _wait(1.0)
	await _shot("r1_03_postbox")
	_teleport(p, cam, pc.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _wait(0.8)
	print("POSTCARD panel open=%s" % Game.ui_open)
	var box: TextEdit = _first("TextEdit")
	box.text = "Fui"
	_press("Comprobar")
	await _wait(0.4)
	await _shot("r1_04_postcard_1star")
	print("  short answer: send button visible=%s (want false)" % (_button("¡Enviar!") != null))
	box.text = "El verano pasado fui a Italia con mi familia. Lo mejor fue la comida, sin embargo el hotel era muy ruidoso."
	_press("Comprobar otra vez")
	await _wait(0.5)
	await _shot("r1_05_postcard_5stars")
	_press("¡Enviar!")
	await _wait(1.0)
	print("POSTCARD: best=%d (want 5) retos_done=%d" % [pc.best, Game.retos_done])

	# Notice board: fill in the gaps (one deliberately wrong first).
	_teleport(p, cam, notice.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _wait(0.8)
	var edits := _all(main.ui.root, []).filter(func(n): return n is LineEdit and n.visible)
	var answers := ["pasa", "estar", "se quedaron", "lujoso", "es", "cómodo", "visitaré", "hacer", "muchos"]
	for i in edits.size():
		edits[i].text = answers[i]
	_press("Comprobar")
	await _wait(0.4)
	await _shot("r1_06_notice_one_wrong")
	edits[3].text = "lujosos"
	_press("Comprobar")
	await _wait(0.4)
	var fixed := _press("¡Arreglar el tablón!")
	await _wait(1.0)
	print("NOTICE: fixed button=%s done=%s retos_done=%d" % [fixed, notice.done, Game.retos_done])

	# Detective: desk first (refused), read both reviews, then answer the questions.
	_teleport(p, cam, det.to_global(Vector3(0, 0.3, 2.6)), cam.yaw)
	await _wait(0.8)
	print("DETECTIVE desk before reading: panel open=%s (want false)" % Game.ui_open)
	for i in 2:
		_teleport(p, cam, det.to_global(Vector3(-4.5 if i == 0 else 4.5, 0.3, 3.6)), cam.yaw)
		await _wait(0.8)
		if i == 0:
			await _shot("r1_07_review")
		_press("Entendido")
		await _wait(0.6)
		_teleport(p, cam, det.to_global(Vector3(0, 0.3, 9.0)), cam.yaw)
		await _wait(1.6)
	var to_det: Vector3 = det.global_position - det.to_global(Vector3(0, 0, 10))
	_teleport(p, cam, det.to_global(Vector3(0, 0.3, 10.0)), atan2(-to_det.x, -to_det.z))
	await _wait(1.0)
	await _shot("r1_08_hotel")
	_teleport(p, cam, det.to_global(Vector3(0, 0.3, 2.6)), cam.yaw)
	await _wait(0.8)
	var qs: Array = det.reto.questions
	for q in qs:
		_press(q.choices[q.correct])
		await _wait(0.3)
		_press("¡Siguiente!")
		await _wait(0.5)
	await _wait(0.5)
	print("DETECTIVE: done=%s retos_done=%d / %d" % [det.done, Game.retos_done, Game.total_retos])

	# Sentence sweets: the traveller (after finding his luggage) and Isla Secreta.
	for item in w.QUESTS.traveller.items:
		_teleport(p, cam, w.ex(item[3]) + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("LUGGAGE: %s" % [Game.ingredients])
	var stall: Node3D = w.cafe
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 6.0)), cam.yaw)
	await _wait(0.4)
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 2.3)), cam.yaw)
	await _wait(0.8)
	box = _first("TextEdit")
	print("TRAVELLER sentence panel=%s" % (box != null))
	if box:
		box.text = "El verano pasado perdí mi maleta en el aeropuerto y fue un desastre, pero el hotel era muy acogedor."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r1_09_traveller")
		_press("¡Enviar!")
		await _wait(1.0)
	var bottle_sweet = w.sweets.filter(func(s): return is_instance_valid(s) and s.get_meta("area") == w._at([250.0, 0.92]))[0]
	var bp: Vector3 = bottle_sweet.global_position
	_teleport(p, cam, Vector3(bp.x * 0.8, 0.3, bp.z * 0.8), atan2(-bp.x, -bp.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("r1_10a_bottle")
	_teleport(p, cam, bp + Vector3(0, -0.5, 0), 0.0)
	await _wait(0.8)
	box = _first("TextEdit")
	if box:
		box.text = "Mis vacaciones ideales serían en Japón porque me encanta la comida, y el año que viene voy a ahorrar dinero."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r1_10_ideal")
		_press("¡Enviar!")
		await _wait(1.0)
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


## A camera high above `target`, looking down at it, for layout shots.
func _aerial(name: String, target: Vector3, height: float, back: Vector3) -> void:
	var old := get_viewport().get_camera_3d()
	var c := Camera3D.new()
	main.world.add_child(c)
	c.global_position = target + back + Vector3(0, height, 0)
	c.look_at(target)
	c.make_current()
	await _wait(0.5)
	await _shot(name)
	c.queue_free()
	old.make_current()


## La Isla de los Retos, Isla 2 (El instituto): the timetable race, the headteacher's
## corridor, the new student's lost things, and the retos.
func _retos2(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS2: retos=%d sweets=%d quest items=%d" % [Game.total_retos, Game.total_sweets, Game.ingredients_total])
	await _aerial("r2_01_island", Vector3.ZERO, 95.0, Vector3(0, 0, 45))
	var tt = w.timetable
	var ht = w.headteacher
	await _aerial("r2_02_timetable", tt.global_position, 22.0, (-tt.global_position.normalized()) * 16.0)
	await _aerial("r2_03_corridor", ht.to_global(Vector3(0, 0, -11)), 30.0, (-ht.global_position.normalized()) * 12.0)

	# El horario: ring the bell, try a wrong room, then run to the right one - three times.
	var face_board: float = tt.rotation.y
	_teleport(p, cam, tt.to_global(Vector3(0, 0.3, 9.0)), face_board)
	cam.pitch = deg_to_rad(-12)
	await _wait(0.5)
	await _aerial("r2_04_board", tt.to_global(Vector3(-1.5, 2.2, 3.0)), 1.0, (-tt.global_position.normalized()) * 9.0)
	var subjects: Array = ["química", "historia", "dibujo", "informática"]
	for r in 3:
		_teleport(p, cam, tt.to_global(Vector3(3.5, 0.3, 4.2)), face_board)
		await _wait(0.2)
		_teleport(p, cam, tt.to_global(Vector3(3.5, 0.3, 3.0)), face_board)
		await _wait(0.6)
		print("  round %d: running=%s prompt=%s" % [r + 1, tt.running, tt._prompt.text.replace("\n", " / ")])
		var ans: String = tt.reto.rounds[r].answer
		var wrong: int = (subjects.find(ans) + 1) % 4
		_teleport(p, cam, tt.to_global(Vector3(-9.0 + wrong * 6.0, 0.3, -4.2)), face_board)
		await _wait(0.6)
		if r == 0:
			await _shot("r2_05_wrong_room")
		_teleport(p, cam, tt.to_global(Vector3(-9.0 + subjects.find(ans) * 6.0, 0.3, 1.0)), face_board)
		await _wait(0.2)
		_teleport(p, cam, tt.to_global(Vector3(-9.0 + subjects.find(ans) * 6.0, 0.3, -4.2)), face_board)
		await _wait(0.6)
		print("  after room: round_i=%d running=%s" % [tt.round_i, tt.running])
	print("TIMETABLE: done=%s sweet visible=%s" % [tt.done, tt.sweet.visible])
	_teleport(p, cam, tt.sweet.global_position + Vector3(0, 0.3, 0), cam.yaw)
	await _wait(0.8)
	var line: LineEdit = _first("LineEdit")
	if line:
		line.text = "tengo quimica los martes"
		_press("Check!")
		await _wait(0.4)
		await _shot("r2_06_timetable_sweet")
		_press("Grab the sweet!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# La directora: walk into her view and get sent back; hide in an alcove; reach the office.
	_teleport(p, cam, ht.start_spot(), ht.rotation.y)
	cam.pitch = deg_to_rad(-20)
	await _wait(1.2)
	await _shot("r2_07_corridor_start")
	var npc_z: float = ht._npc.position.z
	var ahead: float = -1.0 if ht._dir < 0 else 1.0
	var caught0: int = ht.caught_count
	_teleport(p, cam, ht.to_global(Vector3(0.5, 0.3, clampf(npc_z + ahead * 3.5, -19.0, -0.5))), ht.rotation.y)
	await _wait(0.3)
	await _shot("r2_08_caught")
	await _wait(0.6)
	var back_d: float = p.global_position.distance_to(ht.start_spot())
	print("HEADTEACHER: caught %d -> %d, distance from start %.1f (want small)" % [caught0, ht.caught_count, back_d])
	# Alcove: the first pocket is local x 2.4..4.4, z -3..-5.4 - wait there while she walks past.
	_teleport(p, cam, ht.to_global(Vector3(3.5, 0.3, -4.2)), ht.rotation.y)
	var c1: int = ht.caught_count
	await _wait(9.0)
	print("  hiding in the alcove for 9 s: caught %d -> %d (want same), still there=%s" % [c1, ht.caught_count, ht.to_local(p.global_position).x > 2.4])
	_teleport(p, cam, ht.to_global(Vector3(0, 0.3, -21.5)), ht.rotation.y)
	await _wait(0.3)
	await _shot("r2_09_office")
	_teleport(p, cam, ht.sweet.global_position + Vector3(0, 0.3, 0), cam.yaw)
	await _wait(0.8)
	var box: TextEdit = _first("TextEdit")
	print("HEADTEACHER sentence panel=%s" % (box != null))
	if box:
		box.text = "Estoy en contra del uniforme escolar porque es muy incómodo, sin embargo en la primaria no había uniforme y era mejor."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r2_10_uniforme")
		_press("¡Enviar!")
		await _wait(1.0)

	# El alumno nuevo: find his three things, then answer his question.
	for item in w.QUESTS.newstudent.items:
		_teleport(p, cam, w.ex(item[3]) + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("SCHOOL THINGS: %s" % [Game.ingredients])
	var stall: Node3D = w.cafe
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 6.0)), stall.rotation.y)
	await _wait(0.4)
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 2.3)), stall.rotation.y)
	await _wait(0.8)
	box = _first("TextEdit")
	print("NEWSTUDENT sentence panel=%s" % (box != null))
	if box:
		box.text = "El año próximo me gustaría estudiar química porque me encanta, sin embargo el año pasado era muy difícil."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r2_11_newstudent")
		_press("¡Enviar!")
		await _wait(1.0)

	# Retos: look at each one, and fix the notice board.
	var i := 0
	for r in w.retos:
		var pos: Vector3 = r.global_position
		var from := pos + (-pos.normalized()) * 9.0 + Vector3(0, 0.3, 0)
		_teleport(p, cam, from, atan2(-(pos - from).x, -(pos - from).z))
		cam.pitch = deg_to_rad(-15)
		await _wait(0.8)
		await _shot("r2_12_reto_%d_%s" % [i, str(r.reto.get("kind", ""))])
		i += 1
	var notice = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "notice")[0]
	_teleport(p, cam, notice.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _wait(0.8)
	var edits := _all(main.ui.root, []).filter(func(n): return n is LineEdit and n.visible)
	var answers := ["adicta", "saca", "descarga", "leer", "perdió", "tuvimos"]
	for k in mini(edits.size(), answers.size()):
		edits[k].text = answers[k]
	_press("Comprobar")
	await _wait(0.4)
	await _shot("r2_13_notice")
	_press("¡Arreglar el tablón!")
	await _wait(1.0)
	print("NOTICE: gaps=%d done=%s" % [edits.size(), notice.done])
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


## La Isla de los Retos, Isla 3 (Familia y tecnología): the chat, the antenna towers, the grandma.
func _retos3(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS3: retos=%d sweets=%d quest items=%d circuit=%s" % [Game.total_retos, Game.total_sweets, Game.ingredients_total, w.circuit != null])
	await _aerial("r3_01_island", Vector3.ZERO, 95.0, Vector3(0, 0, 45))

	# El chat: one wrong reply first, then a whole conversation.
	var chat = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "chat")[0]
	var to_c: Vector3 = -chat.global_position.normalized()
	_teleport(p, cam, chat.global_position + to_c * 6.0 + Vector3(0, 0.3, 0), atan2(to_c.x, to_c.z))
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("r3_02_chat_bench")
	_teleport(p, cam, chat.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	var replies := ["Hola", "Estoy escuchando música en mi dormitorio.", "No puedo porque tengo que hacer los deberes.",
		"A las siete y media.", "Delante del cine.", "Me llevo bien con mi madre porque es muy comprensiva."]
	for i in replies.size():
		# Wait for the typing to finish and the reply box to open.
		var t0 := Time.get_ticks_msec()
		var line: LineEdit = null
		while Time.get_ticks_msec() - t0 < 8000:
			await _wait(0.2)
			line = _first("LineEdit")
			if line and line.editable:
				break
		if not (line and line.editable):
			print("  CHAT: no reply box for reply %d" % i)
			break
		line.text = replies[i]
		_press("Enviar")
		await _wait(0.8)
		if i == 0:
			await _wait(1.5)
			await _shot("r3_03_chat_hint")
	await _wait(3.0)
	await _shot("r3_04_chat_done")
	_press("¡Genial!")
	await _wait(1.0)
	print("CHAT: done=%s retos_done=%d" % [chat.done, Game.retos_done])

	# Sin señal: climb... well, pop up to each switch.
	var tw = w.towers
	await _aerial("r3_05_tower", w.TOWER_SPOTS[0] + Vector3(0, 5, 0), 8.0, (-w.TOWER_SPOTS[0].normalized()) * 16.0)
	# Walk up the first few steps for real to check they're climbable.
	var step0: Vector3 = tw.get_child(0).to_global(Vector3(cos(0.0) * tw.STEP_R, 1.5, sin(0.0) * tw.STEP_R))
	_teleport(p, cam, step0, 0.0)
	await _wait(0.6)
	print("TOWER step 1: standing at y=%.2f (want ~1.15)" % p.global_position.y)
	for i in 3:
		_teleport(p, cam, tw.top_of(i) + Vector3(0, 0.4, 0), 0.0)
		await _wait(0.8)
		if i == 0:
			await _shot("r3_06_tower_top")
	print("TOWERS: connected=%s done=%s sweet visible=%s" % [tw.connected, tw.done, tw.sweet.visible])
	var hub: Vector3 = w.TOWER_HUB
	_teleport(p, cam, hub + (-hub.normalized()) * 7.0 + Vector3(0, 0.3, 0), atan2(hub.normalized().x, hub.normalized().z) + PI)
	await _wait(1.0)
	await _shot("r3_07_hub")
	_teleport(p, cam, tw.sweet.global_position + Vector3(0, 0.1, 0), cam.yaw)
	await _wait(0.8)
	var ln: LineEdit = _first("LineEdit")
	if ln:
		ln.text = "lo unico malo es que te engancha"
		_press("Check!")
		await _wait(0.4)
		_press("Grab the sweet!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# La abuela.
	for item in w.QUESTS.grandma.items:
		_teleport(p, cam, w.ex(item[3]) + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("GRANDMA THINGS: %s" % [Game.ingredients])
	var stall: Node3D = w.cafe
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 6.0)), stall.rotation.y)
	await _wait(0.8)
	await _shot("r3_08_grandma")
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 2.3)), stall.rotation.y)
	await _wait(0.8)
	var box: TextEdit = _first("TextEdit")
	print("GRANDMA sentence panel=%s" % (box != null))
	if box:
		box.text = "Creo que es importante pasar tiempo en familia porque hablamos mucho, y ayer cenamos juntos en casa de mi abuela."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r3_09_grandma_sentence")
		_press("¡Enviar!")
		await _wait(1.0)

	# The notice board.
	var notice = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "notice")[0]
	_teleport(p, cam, notice.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _wait(0.8)
	var edits := _all(main.ui.root, []).filter(func(n): return n is LineEdit and n.visible)
	var answers := ["tenía", "escribía", "usan", "mandé", "subí", "tengo", "veré"]
	for k in mini(edits.size(), answers.size()):
		edits[k].text = answers[k]
	_press("Comprobar")
	await _wait(0.4)
	_press("¡Arreglar el tablón!")
	await _wait(1.0)
	print("NOTICE: gaps=%d done=%s" % [edits.size(), notice.done])
	var i := 0
	for r in w.retos:
		var pos: Vector3 = r.global_position
		var from := pos + (-pos.normalized()) * 9.0 + Vector3(0, 0.3, 0)
		_teleport(p, cam, from, atan2(-(pos - from).x, -(pos - from).z))
		cam.pitch = deg_to_rad(-15)
		await _wait(0.8)
		await _shot("r3_10_reto_%d_%s" % [i, str(r.reto.get("kind", ""))])
		i += 1
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


## Types a whole chat conversation (waits for each reply box). Returns when the chat closes.
func _chat(replies: Array, shot_prefix: String) -> void:
	for i in replies.size():
		var t0 := Time.get_ticks_msec()
		var line: LineEdit = null
		while Time.get_ticks_msec() - t0 < 8000:
			await _wait(0.2)
			line = _first("LineEdit")
			if line and line.editable:
				break
		if not (line and line.editable):
			print("  CHAT: no reply box for reply %d" % i)
			break
		line.text = replies[i]
		_press("Enviar")
		await _wait(0.8)
	await _wait(3.5)
	await _shot(shot_prefix + "_chat_done")
	_press("¡Genial!")
	await _wait(1.0)


## La Isla de los Retos, Isla 4 (El tiempo libre): the dance stage, the Ferris wheel, the musician.
func _retos4(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS4: retos=%d sweets=%d quest items=%d" % [Game.total_retos, Game.total_sweets, Game.ingredients_total])
	await _aerial("r4_01_island", Vector3.ZERO, 95.0, Vector3(0, 0, 45))
	var st = w.stage
	await _aerial("r4_02_stage", st.to_global(Vector3(0, 2, -1)), 9.0, (-st.global_position.normalized()) * 20.0)
	var nr = w.noria
	await _aerial("r4_03_noria", nr.to_global(Vector3(0, 8, 0)), 4.0, (-nr.global_position.normalized()) * 26.0)

	# El escenario: three rounds; one wrong step first.
	var centre: Vector3 = st.to_global(Vector3(0, 0.3, 1.5))
	var rounds: Array = st.reto.get("rounds", st.DEFAULT_ROUNDS)
	for r in rounds.size():
		_teleport(p, cam, st.to_global(Vector3(0, 0.3, 11.0)), st.rotation.y)
		await _wait(0.4)
		_teleport(p, cam, st.start_spot(), st.rotation.y)
		if r == 0:
			await _wait(2.1)
			await _aerial("r4_04_stage_calling", st.to_global(Vector3(0, 2.5, -1)), 3.0, (-st.global_position.normalized()) * 13.0)
			await _wait(rounds[r].size() * 0.9 - 0.4)
		else:
			await _wait(1.3 + rounds[r].size() * 0.9 + 0.4)
		print("  round %d: listening=%s" % [r + 1, st.is_listening()])
		if r == 0:
			# A wrong pad first.
			var wrong: String = "amarillo" if rounds[0][0] != "amarillo" else "rojo"
			_teleport(p, cam, st.pad_spot(wrong), st.rotation.y)
			await _wait(0.5)
			print("  wrong pad -> listening=%s (want false)" % st.is_listening())
			_teleport(p, cam, st.to_global(Vector3(0, 0.3, 11.0)), st.rotation.y)
			await _wait(1.2)
			_teleport(p, cam, st.start_spot(), st.rotation.y)
			await _wait(1.3 + rounds[r].size() * 0.9 + 0.4)
		for word in rounds[r]:
			_teleport(p, cam, centre, st.rotation.y)
			await _wait(0.25)
			_teleport(p, cam, st.pad_spot(str(word)), st.rotation.y)
			await _wait(0.35)
		print("  after round %d: round_i=%d done=%s" % [r + 1, st.round_i, st.done])
	await _shot("r4_05_stage_done")
	_teleport(p, cam, st.sweet.global_position + Vector3(0, -0.4, 0), st.rotation.y)
	await _wait(0.8)
	var box: TextEdit = _first("TextEdit")
	print("STAGE sweet sentence panel=%s" % (box != null))
	if box:
		box.text = "Me chifla el rock porque es muy emocionante, pero de pequeño escuchaba música pop todos los días."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r4_06_stage_sentence")
		_press("¡Enviar!")
		await _wait(1.0)

	# La noria: ride a gondola from the bottom to the top for real.
	var g: AnimatableBody3D = nr.bottom_gondola()
	_teleport(p, cam, g.global_position + Vector3(0, 0.6, 0), nr.rotation.y + PI)
	await _wait(1.0)
	var y0 := p.global_position.y
	await _shot("r4_07_noria_board")
	var peak := y0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 22000:
		await _wait(0.5)
		peak = maxf(peak, p.global_position.y)
		if g == nr.top_gondola() and absf(g.position.x) < 0.8:
			break
	print("NORIA ride: started at y=%.1f, rode up to y=%.1f (top gondola floor ~%.1f)" % [y0, peak, nr.lookout().y])
	await _shot("r4_08_noria_top")
	# Hop across to the lookout.
	_teleport(p, cam, nr.lookout() + Vector3(0, 0.3, 0), nr.rotation.y)
	await _wait(0.6)
	_teleport(p, cam, w.sweets.filter(func(s): return is_instance_valid(s) and s.get_meta("area") == nr.position)[0].global_position, cam.yaw)
	await _wait(0.8)
	var ln: LineEdit = _first("LineEdit")
	if ln:
		ln.text = "solia jugar al futbol"
		_press("Check!")
		await _wait(0.4)
		await _shot("r4_09_noria_sweet")
		_press("Grab the sweet!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# El músico.
	for item in w.QUESTS.musician.items:
		_teleport(p, cam, w.ex(item[3]) + Vector3(0, 0.3, 0), 0.0)
		await _wait(0.5)
	print("MUSICIAN THINGS: %s" % [Game.ingredients])
	var stall: Node3D = w.cafe
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 6.0)), stall.rotation.y)
	await _wait(0.8)
	await _shot("r4_10_musician")
	_teleport(p, cam, stall.to_global(Vector3(0, 0.3, 2.3)), stall.rotation.y)
	await _wait(0.8)
	box = _first("TextEdit")
	if box:
		box.text = "El fin de semana que viene voy a dormir mucho porque estoy cansado, y el sábado pasado jugué al fútbol."
		_press("Comprobar")
		await _wait(0.4)
		_press("¡Enviar!")
		await _wait(1.0)

	# El chat with Marcos.
	var chat = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "chat")[0]
	_teleport(p, cam, chat.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _chat(["Juego al baloncesto y toco la guitarra.", "El sábado pasado fui al cine con mis amigos.",
		"Me encanta el rock, pero no aguanto el reggaeton.", "¡Sí, claro! Me encantaría."], "r4_11")
	print("CHAT: done=%s" % chat.done)

	var i := 0
	for r in w.retos:
		var pos: Vector3 = r.global_position
		var from := pos + (-pos.normalized()) * 9.0 + Vector3(0, 0.3, 0)
		_teleport(p, cam, from, atan2(-(pos - from).x, -(pos - from).z))
		cam.pitch = deg_to_rad(-15)
		await _wait(0.8)
		await _shot("r4_12_reto_%d_%s" % [i, str(r.reto.get("kind", ""))])
		i += 1
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


## La Isla de los Retos, Isla 5 (La ciudad): the ferry, directions, the market.
func _retos5(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS5: retos=%d sweets=%d" % [Game.total_retos, Game.total_sweets])
	await _aerial("r5_01_island", Vector3.ZERO, 95.0, Vector3(0, 0, 45))
	var f = w.ferry
	await _aerial("r5_02_ferry", f.to_global(Vector3(0, 4, 0)), 14.0, (-f.global_position.normalized()).rotated(Vector3.UP, 0.9) * 26.0)
	var tn = w.town
	await _aerial("r5_03_town", tn.to_global(Vector3(0, 0, 0)), 26.0, tn.global_position.normalized() * -14.0)
	var mk = w.market
	await _aerial("r5_04_market", mk.to_global(Vector3(0, 1.5, 0)), 7.0, (-mk.global_position.normalized()) * 15.0)

	# El ferry: walk up the gangway for real, then (teleport-)climb to the bridge roof.
	var land: Vector3 = f.to_global(f.gangway_spot())
	var side := Vector3(-f.global_position.normalized().z, 0, f.global_position.normalized().x)
	var dir := (land - (Vector3(land.x, 0, land.z) - side * 1.9)).normalized()
	var start: Vector3 = Vector3(land.x, 0.3, land.z) - side * 4.0
	var toward := Vector3(land.x, 0, land.z) - Vector3(start.x, 0, start.z)
	_teleport(p, cam, start, atan2(-toward.x, -toward.z))
	cam.pitch = deg_to_rad(-15)
	await _wait(0.6)
	await _shot("r5_05_gangway")
	Input.action_press("move_forward")
	await _wait(1.6)
	Input.action_release("move_forward")
	await _wait(0.4)
	print("FERRY gangway: player y=%.2f (deck ~%.2f)" % [p.global_position.y, f.deck_y()])
	_teleport(p, cam, f.to_global(Vector3(0, 4.5, -5)), f.rotation.y)
	await _wait(0.8)
	print("  on the containers: y=%.2f (want ~4.0)" % p.global_position.y)
	await _shot("r5_06_containers")
	var fs = w.sweets.filter(func(s): return is_instance_valid(s) and s.get_meta("area") == f.position)[0]
	_teleport(p, cam, fs.global_position + Vector3(0, -0.5, 0), f.rotation.y)
	await _wait(0.8)
	var ln: LineEdit = _first("LineEdit")
	if ln:
		ln.text = "el ferry sale a las diez"
		_press("Check!")
		await _wait(0.4)
		_press("Grab the sweet!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# ¿Dónde está?: guide, a wrong box, then the three right ones.
	var down: float = tn.rotation.y        # facing down the main street (local -Z)
	_teleport(p, cam, tn.guide_spot(), down)
	cam.pitch = deg_to_rad(-10)
	await _wait(1.0)
	await _shot("r5_07_guide")
	_press("Entendido")
	await _wait(0.5)
	_teleport(p, cam, tn.box_spot("B"), down)
	await _wait(0.8)
	print("TOWN wrong box: round=%d (want 0)" % tn.round_i)
	for r in 3:
		_teleport(p, cam, tn.guide_spot() + tn.global_transform.basis.z * 3.0, down)
		await _wait(1.2)
		_teleport(p, cam, tn.guide_spot(), down)
		await _wait(0.8)
		_press("Entendido")
		await _wait(0.4)
		var b: String = tn.current_box()
		_teleport(p, cam, tn.box_spot(b) + tn.global_transform.basis.x * 2.5, down)
		await _wait(0.4)
		_teleport(p, cam, tn.box_spot(b), down)
		await _wait(1.2)
		print("  box %s -> round %d done=%s" % [b, tn.round_i, tn.done])
	_teleport(p, cam, tn.sweet.global_position + Vector3(0, -0.8, 0), down)
	await _wait(0.8)
	var box: TextEdit = _first("TextEdit")
	print("TOWN sweet sentence panel=%s" % (box != null))
	if box:
		box.text = "En mi barrio hay un museo muy interesante y se puede visitar el castillo, pero antes había más tiendas."
		_press("Comprobar")
		await _wait(0.4)
		await _shot("r5_08_town_sentence")
		_press("¡Enviar!")
		await _wait(1.0)

	# El mercado: an expensive basket first (refused), then the cheap one.
	var face_mk: float = mk.rotation.y
	for st in 4:
		_teleport(p, cam, mk.item_spot(st, 1 if st != 1 else 0) + mk.global_transform.basis.z * 1.5, face_mk)
		await _wait(0.2)
		_teleport(p, cam, mk.item_spot(st, 1 if st != 1 else 0), face_mk)
		await _wait(0.5)
	print("MARKET dear basket: total=%.2f" % mk.total())
	_teleport(p, cam, mk.till_spot(), face_mk)
	await _wait(0.6)
	await _shot("r5_09_market_too_dear")
	print("  paid? %s (want false)" % mk.done)
	var cheap := [0, 1, 0, 1]
	for st in 4:
		_teleport(p, cam, mk.item_spot(st, cheap[st]) + mk.global_transform.basis.z * 1.5, face_mk)
		await _wait(0.2)
		_teleport(p, cam, mk.item_spot(st, cheap[st]), face_mk)
		await _wait(0.5)
	print("  cheap basket: total=%.2f" % mk.total())
	_teleport(p, cam, mk.till_spot() + mk.global_transform.basis.z * 2.0, face_mk)
	await _wait(2.2)
	_teleport(p, cam, mk.till_spot(), face_mk)
	await _wait(0.8)
	print("MARKET paid=%s sweet visible=%s" % [mk.done, mk.sweet.visible])
	_teleport(p, cam, mk.sweet.global_position + Vector3(0, -0.6, 0.0) + mk.global_transform.basis.z * 0.4, face_mk)
	await _wait(0.8)
	ln = _first("LineEdit")
	if ln:
		ln.text = "cuanto cuestan las naranjas"
		_press("Check!")
		await _wait(0.4)
		_press("Grab the sweet!")
		await _wait(1.0)

	# The chat with Lucas.
	var chat = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "chat")[0]
	_teleport(p, cam, chat.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _chat(["Hay un castillo y se puede ir de compras.", "Sigue todo recto y toma la primera calle a la derecha.",
		"Hace calor y hace sol.", "¡Sí, vale!"], "r5_10")
	print("CHAT: done=%s" % chat.done)
	var i := 0
	for r in w.retos:
		var pos: Vector3 = r.global_position
		var from := pos + (-pos.normalized()) * 9.0 + Vector3(0, 0.3, 0)
		_teleport(p, cam, from, atan2(-(pos - from).x, -(pos - from).z))
		cam.pitch = deg_to_rad(-15)
		await _wait(0.8)
		await _shot("r5_11_reto_%d_%s" % [i, str(r.reto.get("kind", ""))])
		i += 1
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


## La Isla de los Retos, Isla 6 (La fiesta): the restaurant (and fishing), La Tomatina, the piñata.
func _retos6(p: CharacterBody3D, cam) -> void:
	var w = main.world
	print("RETOS6: retos=%d sweets=%d" % [Game.total_retos, Game.total_sweets])
	await _aerial("r6_01_island", Vector3.ZERO, 95.0, Vector3(0, 0, 45))
	var rs = w.restaurant
	await _aerial("r6_02_restaurant", rs.to_global(Vector3(0, 1, -1)), 8.0, (-rs.global_position.normalized()) * 15.0)
	var tm = w.tomatina
	await _aerial("r6_03_tomatina", tm.to_global(Vector3(0, 0, -14)), 22.0, (-tm.global_position.normalized()) * 14.0)

	# The restaurant: a wrong dish first, then the burger and the ice cream.
	var face_rs: float = rs.rotation.y
	_teleport(p, cam, rs.to_global(Vector3(0, 0.3, 8.0)), face_rs)
	cam.pitch = deg_to_rad(-12)
	await _wait(1.0)
	await _shot("r6_04_customers")
	var dishes: Array = rs.reto.dishes
	var idx := func(id: String) -> int:
		for k in dishes.size():
			if dishes[k].id == id:
				return k
		return 0
	var serve := func(dish: String, table: int) -> void:
		_teleport(p, cam, rs.dish_spot(idx.call(dish)) + rs.global_transform.basis.z * 1.5, face_rs)
		await _wait(0.3)
		_teleport(p, cam, rs.dish_spot(idx.call(dish)), face_rs)
		await _wait(0.5)
		_teleport(p, cam, rs.table_spot(table) + rs.global_transform.basis.z * 2.0, face_rs)
		await _wait(0.3)
		_teleport(p, cam, rs.table_spot(table), face_rs)
		await _wait(0.6)
	await serve.call("pizza", 1)
	print("RESTAURANT wrong dish: served=%s carrying=%s" % [rs.served, rs.carrying])
	await _shot("r6_05_wrong_dish")
	await _wait(1.6)
	await serve.call("burger", 1)
	await _wait(1.6)
	await serve.call("icecream", 2)
	print("  after burger + ice cream: served=%s" % [rs.served])
	# Row out to catch the fish.
	var boat = w.rowboat
	_teleport(p, cam, boat.global_position + Vector3(0, 1.5, 0), 0.0)
	await _wait(0.6)
	print("FISHING: riding=%s" % (p.vehicle != null))
	var goal := Vector2(w.fishing.global_position.x, w.fishing.global_position.z)
	Input.action_press("move_forward")
	var steps := 0
	while steps < 240 and rs.carrying != "fish":
		steps += 1
		var bp := Vector2(boat.global_position.x, boat.global_position.z)
		var to := goal - bp
		cam.yaw = atan2(-to.x, -to.y)
		await _wait(0.1)
	Input.action_release("move_forward")
	print("  caught=%s carrying=%s after %.1f s" % [w.fishing.caught, rs.carrying, steps * 0.1])
	await _shot("r6_06_fish")
	# Back on land (teleport), take the fish to the first table.
	if p.vehicle:
		boat.rider = null
		p.unride(rs.table_spot(0) + rs.global_transform.basis.z * 2.0)
	await _wait(0.3)
	_teleport(p, cam, rs.table_spot(0) + rs.global_transform.basis.z * 2.0, face_rs)
	await _wait(0.4)
	_teleport(p, cam, rs.table_spot(0), face_rs)
	await _wait(0.8)
	print("RESTAURANT: served=%s done=%s sweet visible=%s" % [rs.served, rs.done, rs.sweet.visible])
	_teleport(p, cam, rs.sweet.global_position + Vector3(0, -0.6, 0) + rs.global_transform.basis.z * 0.8, face_rs)
	await _wait(0.8)
	var box: TextEdit = _first("TextEdit")
	if box:
		box.text = "El sábado pasado comí en un restaurante italiano con mi familia. Pedí pizza porque me encanta, pero el camarero era muy lento."
		_press("Comprobar")
		await _wait(0.4)
		_press("¡Enviar!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# La Tomatina: stand in the street for a bit (get splatted), then run to the plaza.
	_teleport(p, cam, tm.start_spot(), tm.rotation.y)
	cam.pitch = deg_to_rad(-12)
	await _wait(0.5)
	_teleport(p, cam, tm.to_global(Vector3(0, 0.3, -8)), tm.rotation.y)
	await _wait(1.6)
	await _shot("r6_07_tomatoes")
	await _wait(3.0)
	print("TOMATINA: hits after standing still 4.6 s = %d, progress now %.2f" % [tm.hits, tm.progress(p.global_position)])
	_teleport(p, cam, tm.sweet.global_position + Vector3(0, -0.5, 0), tm.rotation.y)
	await _wait(0.8)
	var ln: LineEdit = _first("LineEdit")
	if ln:
		ln.text = "el año pasado fui a un festival"
		_press("Check!")
		await _wait(0.4)
		_press("Grab the sweet!")
		await _wait(1.0)
	print("  sweets now %d" % Game.sweets)

	# La piñata: land on it three times (drop onto it from above).
	var pn = w.pinata
	_teleport(p, cam, pn.to_global(Vector3(0, 0.3, 5.0)), pn.rotation.y)
	await _wait(0.8)
	await _shot("r6_08_pinata")
	for k in 3:
		_teleport(p, cam, pn.top() + Vector3(0, 1.2, 0), pn.rotation.y)
		p.velocity = Vector3(0, -2, 0)
		await _wait(1.4)
	print("PINATA: hits=%d done=%s" % [pn.hits, pn.done])
	await _shot("r6_09_pinata_burst")
	_teleport(p, cam, pn.sweet.global_position + Vector3(0, -0.6, 0), pn.rotation.y)
	await _wait(0.8)
	box = _first("TextEdit")
	if box:
		box.text = "El año que viene voy a celebrar mi cumpleaños con una fiesta enorme porque me encanta bailar, y el año pasado comí tarta."
		_press("Comprobar")
		await _wait(0.4)
		_press("¡Enviar!")
		await _wait(1.0)

	var chat = w.retos.filter(func(r): return str(r.reto.get("kind", "")) == "chat")[0]
	_teleport(p, cam, chat.to_global(Vector3(0, 0.3, 1.2)), cam.yaw)
	await _chat(["Comí paella y bebí un zumo.", "¡Sí, claro! Me encantaría.", "Me encanta la tarta de chocolate.",
		"Normalmente hago una fiesta con mis amigos."], "r6_10")
	print("CHAT: done=%s" % chat.done)
	var i := 0
	for r in w.retos:
		var pos: Vector3 = r.global_position
		var from := pos + (-pos.normalized()) * 9.0 + Vector3(0, 0.3, 0)
		_teleport(p, cam, from, atan2(-(pos - from).x, -(pos - from).z))
		cam.pitch = deg_to_rad(-15)
		await _wait(0.8)
		await _shot("r6_11_reto_%d_%s" % [i, str(r.reto.get("kind", ""))])
		i += 1
	print("SWEETS: %d / %d   RETOS: %d / %d" % [Game.sweets, Game.total_sweets, Game.retos_done, Game.total_retos])
	get_tree().quit()


func _phone_pass() -> void:
	await _wait(5.0)
	await _shot("p1_hud")
	main.ui.open_lesson(main.lesson.pages, 1)
	await _wait(0.8)
	await _shot("p2_lesson")
	main.ui._lesson_closed.emit()
	await _wait(0.3)
	main.ui.ask_question(main.lesson.sweets[0], "sweet")
	await _wait(0.8)
	await _shot("p3_sweet")
	get_tree().quit()
