extends Node
## Global game state (autoload "Game"): config, lesson data, progress, sound, input setup.

signal stars_changed
signal coins_changed
signal cards_changed
signal sweets_changed
signal key_changed
signal ingredients_changed
signal toast(text: String)

## Answer check results
enum { WRONG, RIGHT, RIGHT_BUT_ACCENTS }

const DEFAULT_CONFIG := {
	"game_title": "Lesson Island",
	"tagline": "",
	"heroes": [
		{"name": "Girl", "color": "#f0508c", "models": ["character-female-f", "character-female-b", "character-female-c", "character-female-a", "character-female-e", "character-female-d"]},
		{"name": "Boy", "color": "#4fa3ff", "models": ["character-male-f", "character-male-a", "character-male-d", "character-male-e", "character-male-c", "character-male-b"]},
		{"name": "Buddy", "color": "#ff9a3c", "models": ["character-oobi", "character-oodi", "character-ooli", "character-oopi", "character-oozi"]},
	],
	"accents": "lenient",
	"beacons": true,
	"text_scale": 0.7,
	"text_scale_touch": 0.9,
	"course": [{"file": "lessons/sample_lesson.json", "title": "Sample", "theme": "meadow"}],
}
const PROGRESS_FILE := "user://progress.json"

var config: Dictionary = DEFAULT_CONFIG.duplicate(true)
var lesson: Dictionary = {}
var character := "character-female-f"
var hero_name := "Ester"
var hero_index := 0
var outfit_index := 0

## Scene-reload handoff: which island to jump straight into (index into config.course, -1 = title).
var pending_island := -1
var current_island := 0
var return_to_picker := false

# Progress for the current run.
var stars := 0
var total_stars := 0
var coins := 0
var cards_solved := 0
var total_cards := 0
var chests_opened := 0
var total_chests := 0
var sweets := 0       # bonus 'extension' challenges - they don't open the bridge
var total_sweets := 0
var has_key := false
var ingredients: Array[String] = []   # chef's ingredients found so far
var ingredients_total := 0
var first_try := 0   # questions answered correctly on the first attempt
var attempts := {}   # question id -> number of attempts

## True while a full-screen panel (question, lesson) is open; freezes the player.
var ui_open := false

## Movement vector from the on-screen joystick (x = right, y = down).
var touch_move := Vector2.ZERO

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _best := {}   # lesson file -> best star rating (1-3)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	for n in ["jump", "pickup", "spring", "build", "wrong", "open", "close", "click", "card", "correct", "win", "boom", "thud"]:
		_sounds[n] = load("res://assets/audio/%s.ogg" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	var m: AudioStreamOggVorbis = load("res://assets/audio/music.ogg")
	m.loop = true
	_music.stream = m
	_music.volume_db = -14.0
	add_child(_music)
	_load_progress()


## Merges a loaded config over the defaults.
func apply_config(c: Dictionary) -> void:
	config = DEFAULT_CONFIG.duplicate(true)
	for k in c:
		config[k] = c[k]
	if config.heroes.is_empty():
		config.heroes = DEFAULT_CONFIG.heroes.duplicate(true)
	hero_index = clampi(hero_index, 0, config.heroes.size() - 1)
	var title := str(config.game_title)
	DisplayServer.window_set_title(title)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title = %s" % JSON.stringify(title))


func heroes() -> Array:
	return config.heroes


func text_scale() -> float:
	return float(config.get("text_scale_touch", 0.9)) if is_touch() else float(config.get("text_scale", 0.7))


func reset_progress() -> void:
	stars = 0
	total_stars = 0
	coins = 0
	cards_solved = 0
	total_cards = 0
	chests_opened = 0
	total_chests = 0
	sweets = 0
	total_sweets = 0
	has_key = false
	ingredients.clear()
	ingredients_total = 0
	first_try = 0
	attempts.clear()
	ui_open = false
	touch_move = Vector2.ZERO


func add_star() -> void:
	stars += 1
	sfx("pickup", randf_range(0.95, 1.15))
	stars_changed.emit()


func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit()


func record_attempt(id: String, correct: bool) -> void:
	attempts[id] = attempts.get(id, 0) + 1
	if correct and attempts[id] == 1:
		first_try += 1


# ---------------------------------------------------------------- saved progress (best stars per island)

func best_rating(file: String) -> int:
	var b = _best.get(file, 0)
	return int(b.get("stars", 0)) if b is Dictionary else int(b)


func best_sweets(file: String) -> int:
	var b = _best.get(file, 0)
	return int(b.get("sweets", 0)) if b is Dictionary else 0


## Remembers the best star rating and most sweets found on each island.
func save_result(file: String, rating: int, sweets_found: int) -> void:
	if "--autotest" in OS.get_cmdline_user_args():
		return
	_best[file] = {"stars": maxi(rating, best_rating(file)), "sweets": maxi(sweets_found, best_sweets(file))}
	var f := FileAccess.open(PROGRESS_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_best))


func _load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_FILE):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_FILE))
	if data is Dictionary:
		_best = data


# ---------------------------------------------------------------- sound

func sfx(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not _sounds.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[name]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return


func play_music() -> void:
	if not _music.playing:
		_music.play()


func show_toast(text: String) -> void:
	toast.emit(text)


func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args()


# ---------------------------------------------------------------- answer checking

## Checks a typed answer against the accepted answers.
## Case, punctuation (including ¿ ¡) and extra spaces are ignored; numbers compare numerically.
## With "accents": "lenient" in the config, a missing/wrong accent still counts but is flagged.
func check_answer(given: String, accepted: Array) -> int:
	var g := normalise(given)
	if g.is_empty():
		return WRONG
	for a in accepted:
		var n := normalise(str(a))
		if g == n:
			return RIGHT
		if g.is_valid_float() and n.is_valid_float() and absf(g.to_float() - n.to_float()) < 0.0001:
			return RIGHT
	if str(config.get("accents", "lenient")) == "lenient":
		for a in accepted:
			if strip_accents(g) == strip_accents(normalise(str(a))):
				return RIGHT_BUT_ACCENTS
	return WRONG


static func normalise(s: String) -> String:
	var out := ""
	for c in s.strip_edges().to_lower():
		if c in ".,!?;:'\"()¿¡":
			continue
		out += c
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


static func strip_accents(s: String) -> String:
	var from := "áéíóúüñàèìòùâêîôû"
	var to := "aeiouunaeiouaeiou"
	var out := s
	for i in from.length():
		out = out.replace(from[i], to[i])
	return out


func _setup_input() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"cam_left": [KEY_Q],
		"cam_right": [KEY_E],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var pad := {"jump": JOY_BUTTON_A}
	for action in pad:
		var ev := InputEventJoypadButton.new()
		ev.button_index = pad[action]
		InputMap.action_add_event(action, ev)
