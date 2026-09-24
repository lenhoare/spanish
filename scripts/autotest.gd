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
	if Game.current_island == 1:
		await _island2(p, cam)
		return
	if Game.current_island == 2:
		await _island3(p, cam)
		return
	if Game.current_island == 3:
		await _island4(p, cam)
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
	_teleport(p, cam, W.KEY_SPOT + Vector3(0, 0.2, 2.0), 0.0)
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
	while p.global_position.z > W.PRIZE_CENTER.z + 0.8 and not Game.ui_open and Time.get_ticks_msec() - t0 < 9000:
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
