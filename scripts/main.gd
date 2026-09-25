extends Node
## Game flow: load config -> title (pick hero) -> pick island -> play -> prize.
## Choosing an island (or "play again") stores the choice in Game and reloads this scene,
## which then skips the title and starts straight on that island.

const WorldScript := preload("res://scripts/world.gd")
const UIScript := preload("res://scripts/ui.gd")
const CameraScript := preload("res://scripts/camera_rig.gd")
const LoaderScript := preload("res://scripts/lesson_loader.gd")

var world: Node3D
var ui: CanvasLayer
var cam: Node3D
var player: CharacterBody3D
var lesson: Dictionary
var loader: Node

var _preview: Node3D
var _title_cam: Camera3D
var _locked: Array = []     # cards/chests that need a whiteboard visit before retrying
var _nag_cooldown := 0.0
var _read_board := false
var _playing := false


func _ready() -> void:
	Game.reset_progress()
	ui = CanvasLayer.new()
	ui.set_script(UIScript)
	add_child(ui)
	loader = Node.new()
	loader.set_script(LoaderScript)
	add_child(loader)
	loader.config_loaded.connect(_on_config_loaded)
	loader.games_loaded.connect(_on_games_loaded, CONNECT_ONE_SHOT)
	loader.load_games()


## Which game? A ?game=... link (or a choice made earlier) skips the chooser.
func _on_games_loaded(games: Array, preselected: String) -> void:
	Game.games = games
	var ids := games.map(func(g): return str(g.get("id", "")))
	if preselected != "" and preselected in ids and Game.game_id == "":
		Game.game_id = preselected
		Game.game_locked = true
	if Game.game_id == "" or not Game.game_id in ids:
		if "--chooser-shot" in OS.get_cmdline_user_args():
			get_tree().create_timer(1.5).timeout.connect(func():
				get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir().path_join("shots/chooser.png"))
				get_tree().quit())
		Game.game_id = ids[0] if games.size() == 1 else await ui.show_game_chooser(games)
	var game: Dictionary = games[ids.find(Game.game_id)]
	loader.load_config(str(game.get("config", "config.json")))


func _process(delta: float) -> void:
	_nag_cooldown -= delta
	if _preview:
		_preview.rotation.y = sin(Time.get_ticks_msec() / 1000.0 * 0.8) * 0.35


func _on_config_loaded(cfg: Dictionary) -> void:
	Game.apply_config(cfg)
	var course: Array = Game.config.course
	# Dev: -- --autotest --island 2 tests a specific island (1-based).
	var args := OS.get_cmdline_user_args()
	if "--island" in args and not Game.has_meta("island_arg_used"):
		Game.set_meta("island_arg_used", true)
		Game.current_island = int(args[args.find("--island") + 1]) - 1
	var idx := clampi(Game.pending_island if Game.pending_island >= 0 else Game.current_island, 0, course.size() - 1)
	Game.current_island = idx
	loader.loaded.connect(_on_lesson_loaded, CONNECT_ONE_SHOT)
	loader.load_lesson(str(course[idx].file))


func _on_lesson_loaded(data: Dictionary) -> void:
	lesson = data
	Game.lesson = data
	world = Node3D.new()
	world.set_script(WorldScript)
	add_child(world)
	world.build(lesson, str(Game.config.course[Game.current_island].get("theme", "meadow")))

	# Dev tool: `-- --islandshots` visits every island through the real reload path
	# and saves a screenshot of each.
	if "--islandshots" in OS.get_cmdline_user_args() and not Game.has_meta("shots"):
		Game.set_meta("shots", true)
		_on_island_picked(0)
		return

	if Game.pending_island >= 0:
		Game.pending_island = -1
		_start_game()
		if Game.has_meta("shots"):
			_island_shot()
		return

	# Title screen: the hero stands on the island, framed to the right of the menu.
	_title_cam = Camera3D.new()
	world.add_child(_title_cam)
	var focus: Vector3 = WorldScript.SPAWN + Vector3(-1.2, 1.0, 0)
	_title_cam.position = WorldScript.SPAWN + Vector3(-1.2, 1.7, 4.6)
	_title_cam.look_at(focus + Vector3(0, 0.2, -4))
	_title_cam.fov = 50
	_title_cam.current = true

	ui.character_picked.connect(_show_preview)
	ui.play_pressed.connect(_on_play_pressed)
	ui.island_picked.connect(_on_island_picked)
	ui.games_pressed.connect(func():
		# Back to the game chooser: forget the game and start over.
		Game.game_id = ""
		Game.current_island = 0
		get_tree().reload_current_scene())
	ui.show_title()
	if Game.return_to_picker:
		Game.return_to_picker = false
		_on_play_pressed()

	if "--autotest" in OS.get_cmdline_user_args():
		var t := Node.new()
		t.set_script(load("res://scripts/autotest.gd"))
		t.main = self
		add_child(t)


func _show_preview(character_name: String) -> void:
	Game.character = character_name
	if _preview:
		_preview.queue_free()
	_preview = Props.character(character_name)
	_preview.scale = Vector3.ONE * 1.5
	world.add_child(_preview)
	_preview.position = WorldScript.SPAWN
	var anims := _preview.find_children("*", "AnimationPlayer", true, false)
	if anims.size() > 0:
		var ap: AnimationPlayer = anims[0]
		ap.play("emote-yes")
		ap.queue("idle")
		if ap.has_animation("idle"):
			ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	# Little hop so switching feels lively.
	_preview.position.y += 0.4
	var t := create_tween()
	t.tween_property(_preview, "position:y", WorldScript.SPAWN.y, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_play_pressed() -> void:
	ui.show_island_picker()


func _on_island_picked(index: int) -> void:
	Game.pending_island = index
	Game.current_island = index
	get_tree().reload_current_scene()


func _start_game() -> void:
	_playing = true
	Game.play_music()
	if _preview:
		_preview.queue_free()
		_preview = null
	player = world.spawn_player(Game.character)
	cam = Node3D.new()
	cam.set_script(CameraScript)
	world.add_child(cam)
	cam.set_target(player)
	if _title_cam:
		_title_cam.queue_free()

	world.card_touched.connect(_on_card)
	world.chest_touched.connect(_on_chest)
	world.sweet_touched.connect(_on_sweet)
	world.reto_touched.connect(_on_reto)
	world.whiteboard_touched.connect(_on_whiteboard)
	world.read_panel.connect(func(title: String, text: String): ui.show_reading(title, text))
	world.prize_claimed.connect(_on_prize)
	world.bridge.completed.connect(func():
		Game.show_toast("The bridge is complete! Cross it to reach Star Island!"))
	ui.show_hud()
	ui.menu_pressed.connect(func():
		Game.return_to_picker = true
		get_tree().reload_current_scene())

	await get_tree().create_timer(0.6).timeout
	Game.show_toast("¡Hola, %s! Welcome to %s" % [Game.hero_name, lesson.title])
	await get_tree().create_timer(3.5).timeout
	if Game.is_touch():
		Game.show_toast("Left thumb to move, JUMP to jump (tap twice to double jump!)")
	else:
		Game.show_toast("WASD to move, SPACE to jump (twice for a double jump!), drag to look")
	await get_tree().create_timer(4.5).timeout
	Game.show_toast("Find the question cards to rebuild the bridge!")
	if Game.total_sweets > 0:
		await get_tree().create_timer(4.5).timeout
		Game.show_toast("Bonus: %d sweets are hidden on this island. Can you find them all?" % Game.total_sweets)


func _on_card(card: Node3D) -> void:
	if _check_locked(card):
		return
	var result: String = await ui.ask_question(card.question, "card")
	match result:
		"correct":
			Game.cards_solved += 1
			Game.cards_changed.emit()
			player.celebrate()
			card.fly_to(world.bridge.section_center(world.bridge.built) + Vector3(0, 0.5, 0))
			await get_tree().create_timer(1.4).timeout
			world.bridge.build_next()
			if Game.cards_solved < Game.total_cards:
				Game.show_toast("¡Muy bien, %s! A piece of the bridge appeared!  %d / %d" % [Game.hero_name, Game.cards_solved, Game.total_cards])
		"locked":
			_lock(card)
		_:
			card.rest()


func _on_chest(chest: Node3D) -> void:
	if chest.level_locked:
		chest.rest()
		if _nag_cooldown <= 0:
			_nag_cooldown = 2.5
			Game.sfx("wrong", 1.2, -6)
			Game.show_toast("This is a level %d chest - open both level %d chests first!" % [chest.level, chest.level - 1])
		return
	# Wrong chest answers don't lock anything - the panel just sends you to the whiteboard.
	var result: String = await ui.ask_question(chest.question, "chest")
	if result != "correct":
		chest.rest()
		return
	Game.chests_opened += 1
	player.celebrate()
	chest.open(player)
	Game.show_toast("¡Genial! +%d coins!" % chest.question.get("coins", 10))
	_unlock_next_chest_level(chest.level)


## When every chest of a level is open, the next level's chests unlock.
func _unlock_next_chest_level(level: int) -> void:
	for ch in world.chests:
		if ch.level == level and not ch.opened:
			return
	var unlocked := 0
	for ch in world.chests:
		if ch.level == level + 1 and ch.level_locked:
			ch.set_level_locked(false)
			unlocked += 1
	if unlocked > 0:
		await get_tree().create_timer(2.5).timeout
		Game.sfx("build", 1.3)
		Game.show_toast("Level %d quiz chests unlocked! They're harder - and further away..." % (level + 1))


func _on_sweet(sweet: Node3D) -> void:
	if _check_locked(sweet):
		return
	var result: String
	if sweet.question.has("interview"):
		# A job interview: several sentence-builder questions in a row. Progress is kept if
		# you walk away halfway.
		var qs: Array = sweet.question.interview
		var i: int = sweet.get_meta("interview_i", 0)
		result = "correct"
		while i < qs.size():
			var ch: Dictionary = qs[i]
			var stars: int = await ui.ask_sentence(ch, "LA ENTREVISTA (%d / %d)" % [i + 1, qs.size()])
			if stars < int(ch.get("stars_needed", 3)):
				result = "skipped"
				break
			i += 1
			sweet.set_meta("interview_i", i)
			if i < qs.size():
				Game.sfx("correct")
				Game.show_toast("\"Muy bien. Siguiente pregunta...\" (%d / %d)" % [i, qs.size()])
				await get_tree().create_timer(0.8).timeout
		if result == "correct":
			Game.show_toast("\"¡Enhorabuena! ¡Estás contratado/a!\" You got the job!")
			# The reward appears on the desk (hidden until now), then flies to you.
			if not sweet.visible:
				sweet.visible = true
				sweet.scale = Vector3.ONE * 0.01
				create_tween().tween_property(sweet, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(1.2).timeout
	elif sweet.question.has("sentence"):
		# Sentence-builder sweet: earn enough stars to take it.
		var ch: Dictionary = sweet.question.sentence
		var stars: int = await ui.ask_sentence(ch, "SWEET CHALLENGE")
		result = "correct" if stars >= int(ch.get("stars_needed", 3)) else "skipped"
	else:
		result = await ui.ask_question(sweet.question, "sweet")
	match result:
		"correct":
			Game.sweets += 1
			Game.sweets_changed.emit()
			player.celebrate()
			sweet.collect(player)
			Game.sfx("win", 1.2, -4)
			if Game.sweets == Game.total_sweets:
				Game.show_toast("¡Increíble, %s! You found every sweet!" % Game.hero_name)
			else:
				Game.show_toast("¡Qué rico! A sweet!  %d / %d" % [Game.sweets, Game.total_sweets])
		"locked":
			_lock(sweet)
		_:
			sweet.rest()


func _lock(item: Node3D) -> void:
	if not item in _locked:
		_locked.append(item)
	item.set_locked(true)
	item.rest()
	player.sad()


func _check_locked(item: Node3D) -> bool:
	if not item in _locked:
		return false
	item.rest()
	if _nag_cooldown <= 0:
		_nag_cooldown = 2.0
		Game.sfx("wrong", 1.2, -6)
		Game.show_toast("Locked! Jump at the whiteboard to read, then come back.")
	return true


func _on_whiteboard() -> void:
	await ui.open_lesson(lesson.pages)
	world.whiteboard.rest()
	if not _locked.is_empty():
		for item in _locked:
			if is_instance_valid(item):
				item.set_locked(false)
		_locked.clear()
		Game.show_toast("Your locked questions are open again - good luck!")
	elif not _read_board:
		Game.show_toast("Now go and find those question cards!")
	_read_board = true


## Retos: postcards (sentence builder), notice boards (verb gap-fill), detective (reading).
func _on_reto(node: Node3D, part: int) -> void:
	if node.done and not (node.has_method("record") and str(node.reto.get("kind", "")) == "postcard"):
		node.rest()
		return
	match str(node.reto.get("kind", "postcard")):
		"postcard":
			var stars: int = await ui.ask_sentence(node.reto)
			node.rest()
			if stars > 0:
				var first: bool = node.record(stars)
				player.celebrate()
				Game.sfx("win", 1.3, -4)
				Game.add_coins(stars * 2)
				if first:
					_reto_done()
				Game.show_toast("¡Postal enviada! %d estrellas, +%d coins%s" % [stars, stars * 2, "" if stars >= 5 else " - can you get 5?"])
		"notice":
			var fixed: bool = await ui.ask_notice(node.reto)
			node.rest()
			if fixed and node.record(1):
				player.celebrate()
				Game.add_coins(10)
				_reto_done()
				Game.show_toast("¡El tablón está arreglado! +10 coins")
		"chat":
			var ok: bool = await ui.ask_chat(node.reto)
			node.rest()
			if ok and node.record(1):
				player.celebrate()
				Game.add_coins(10)
				_reto_done()
				Game.show_toast("¡Qué buena conversación! +10 coins")
		"detective":
			if part >= 0:
				var sp: Dictionary = node.reto.speakers[part]
				await ui.show_reading(str(sp.get("name", "")), str(sp.get("review", "")))
				node.rest()
				node.mark_read(part)
				if node.all_read():
					Game.show_toast("You've read both reviews - now talk to the receptionist!")
				return
			if not node.all_read():
				Game.sfx("click")
				Game.show_toast("\"¿Quién lo dice?\" First read what the guests say - talk to them!")
				return
			node.rest()
			for q in node.reto.get("questions", []):
				var qq: Dictionary = preload("res://scripts/lesson_loader.gd")._question(q, "det")
				var res: String = await ui.ask_question(qq, "detective")
				if res != "correct":
					node.rest()
					return
			node.finish()
			player.celebrate()
			Game.add_coins(15)
			_reto_done()
			Game.show_toast("¡Detective genial! Every answer right. +15 coins")


func _reto_done() -> void:
	Game.retos_done += 1
	Game.retos_changed.emit()
	if Game.retos_done == Game.total_retos:
		Game.sfx("win")
		await get_tree().create_timer(2.5).timeout
		Game.show_toast("¡Todos los retos! Every challenge on the island complete!")


func _on_prize() -> void:
	Game.sfx("win")
	player.celebrate()
	_confetti(player.global_position + Vector3(0, 2, 0))
	var rating := rating()
	Game.save_result(str(Game.config.course[Game.current_island].file), rating, Game.sweets)
	await get_tree().create_timer(2.0).timeout
	var choice: String = await ui.show_results(lesson.prize, rating)
	if choice == "again":
		Game.pending_island = Game.current_island
	elif choice == "islands":
		Game.return_to_picker = true
	else:
		return   # keep exploring
	get_tree().reload_current_scene()


func _island_shot() -> void:
	await get_tree().create_timer(2.5).timeout
	cam.yaw = 0.6
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var dir := OS.get_user_data_dir().path_join("shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join("island_%d.png" % Game.current_island))
	print("ISLAND SHOT %d: %s (%s)" % [Game.current_island, lesson.title, Game.config.course[Game.current_island].theme])
	if Game.current_island + 1 < Game.config.course.size():
		_on_island_picked(Game.current_island + 1)
	else:
		get_tree().quit()


## 1-3 stars from answers right first time (60%) and stars collected (40%).
func rating() -> int:
	var q_total := maxi(Game.total_cards + Game.total_chests, 1)
	var score := 0.6 * float(Game.first_try) / q_total + 0.4 * float(Game.stars) / maxi(Game.total_stars, 1)
	return 1 + int(score >= 0.5) + int(score >= 0.85)


func _confetti(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 120
	p.lifetime = 3.0
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70
	p.initial_velocity_min = 6
	p.initial_velocity_max = 11
	p.gravity = Vector3(0, -6, 0)
	p.angular_velocity_min = -400
	p.angular_velocity_max = 400
	p.color = Color(1, 0.4, 0.6)
	p.hue_variation_min = -1.0
	p.hue_variation_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.1)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.mesh = q
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
