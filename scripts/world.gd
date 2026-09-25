extends Node3D
## "Meadow Island" world template.
##
## The layout is hand-designed; the lesson file fills the slots:
##   - question cards go into CARD_SLOTS (in order, easiest first)
##   - multiple-choice chests go into CHEST_SLOTS
##   - the bridge to Star Island has one section per card
##   - sweets (bonus challenges) go to the sweet shop ("key") or the ghost garden ("guarded")

signal card_touched(card: Node3D)
signal chest_touched(chest: Node3D)
signal sweet_touched(sweet: Node3D)
signal reto_touched(reto: Node3D, part: int)
signal read_panel(title: String, markdown: String)   # set-pieces that want a text panel
signal whiteboard_touched
signal prize_claimed

const BASE_R := 30.0
const SPAWN := Vector3(0, 0.2, 14)
## The island's size can grow ("world_scale" in config.json). Everything beyond the base
## coastline (side islands, stepping stones, Star Island...) is pushed outwards by the same
## amount, leaving a new outer ring of land; the middle of the island stays the same.
var MAIN_R := BASE_R
var D := 0.0                                   # how much bigger than the base radius
var PRIZE_CENTER := Vector3(0, 0, -(BASE_R + 21))
var EAST_ISLAND := Vector3(40, 0, 8)
var WEST_ISLAND := Vector3(-40, 0, 14)
const SWEET_SHOP := Vector3(16, 0, -20)
const GHOST_GARDEN := Vector3(-18, 0, 16)
var KEY_SPOT := Vector3(-42, 0, 11.5)
const CAFE := Vector3(16, 0, -20)           # the chef's café uses the sweet shop's spot
const SHIP := Vector3(17, -2.2, 44)         # pirate ship moored off the south coast (keel below the sea)
const JETTY_X := 9.0
const JETTY_Z := Vector2(26, 47)
const HEALTHY_FIELD := Vector3(-18, 0, 16)  # "Comida sana" uses the ghost garden's spot
const BOAT_DIR := Vector3(-0.707, 0, -0.707)  # the rowing jetty is on the far north-west shore
const SECRET_ISLAND := Vector3(-66, 0, -50)
const SECRET_R := 5.0
const WHITE_SHIP := Vector3(70, -2.2, 56)      # far out to the south-east, opposite Isla Secreta
const CIRCUIT_DIR := Vector3(-0.6, 0, -0.8)    # El circuito runs out to sea from the far north-west shore
const ROUTINE_HUT := Vector3(-20, 0, -16)       # La rutina diaria puzzle hut, far north-west
const SPEED_DIR := Vector3(0.951, 0, -0.309)   # the speedboat jetty points east-north-east
const TOWER_ISLE := Vector3(80, 0, -42)        # La Torre, far out to the east
const TOWER_ISLE_R := 6.5
const TOWER_SCALE := 1.4
const TOWER_TOP := 14.8                        # lookout platform height
## Characters with a 3-item fetch quest (lesson sweet "kind" -> set-up). Items are
## [spanish name, model, scale, where it's hidden]. All speech is Spanish only.
const QUESTS := {
	"chef": {
		"sign": "Café del Cocinero", "character": "character-male-e", "hat": "chef",
		"speaker": "El cocinero", "greeting": "¡Hola! Soy cocinero.\n¡Necesito ingredientes!",
		"thanks": "¡Gracias!\n¡Toma un dulce!", "awning": Color(0.93, 0.3, 0.35),
		"reward": "food/cupcake", "counter": [["food/burger", 2.5, -1.4]],
		"items": [
			["una pizza", "food/pizza", 2.6, Vector3(-17.5, 1.8, -6)],                   # west plateau
			["un limón", "food/lemon", 4.0, Vector3(38.5, 0, 11.5)],                     # east island
			["una botella de limonada", "food/soda-bottle", 3.0, Vector3(17.2, 2.7, 16)],  # floating islet
		],
	},
	"trainer": {
		"sign": "El Gimnasio", "character": "skate/character-skate-girl", "hat": "headband", "npc_scale": 2.9,
		"speaker": "La entrenadora", "greeting": "¡Hola! Soy entrenadora.\n¡Necesito mis cosas!",
		"thanks": "¡Genial!\n¡Toma un dulce!", "awning": Color(0.25, 0.6, 0.95),
		"reward": "food/donut-chocolate", "reward_scale": 4.0, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"floor_props": [["skate/skateboard", 2.6, Vector3(4.0, 0.0, 3.0), 0.4]],
		"counter": [["dumbbell", 0.8, -1.45, -0.25], ["dumbbell", 0.8, -0.7, 0.25], ["arena/trophy", 1.6, 1.5]],
		"items": [
			["una botella de agua", "survival/bottle", 6.0, Vector3(24, 0.5, -4)],     # on the east mound
			["un plátano", "food/banana", 2.6, Vector3(-42.5, 0, 15.5)],              # west island
			["una pelota", "minigolf/ball-red", 10.0, Vector3(20.5, 3.8, 12.4)],      # top floating islet
		],
	},
	"recycler": {
		"sign": "Reciclaje", "character": "character-female-c", "hat": "",
		"speaker": "La ecologista", "greeting": "¡Hola! ¡Reciclamos!\n¡Necesito tres cosas!",
		"thanks": "¡Genial!\n¡Toma un dulce!", "awning": Color(0.3, 0.72, 0.35),
		"reward": "food/popsicle", "reward_scale": 5.0, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["bins", 1.0, -1.1]],
		"items": [
			["una botella de plástico", "survival/bottle", 6.0, Vector3(-42.5, 0, 15.5)],   # west island
			["una lata", "food/soda-can", 3.0, Vector3(38.5, 0, 11.5)],                      # east island
			["un vaso de vidrio", "food/glass", 4.5, SECRET_ISLAND + Vector3(2.5, 0, 1.5)],   # Isla Secreta!
		],
	},
	"tourist": {
		"sign": "Tienda de recuerdos", "character": "character-female-d", "hat": "",
		"speaker": "La turista", "greeting": "¡Hola! Estoy de vacaciones.\n¡Necesito mis recuerdos!",
		"thanks": "¡Gracias!\n¡Toma un dulce!", "awning": Color(1.0, 0.6, 0.2),
		"reward": "food/cupcake", "reward_scale": 3.2, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["food/cup-coffee", 2.8, -1.5], ["flag", 1.2, 1.5]],
		"items": [
			["una taza", "food/cup-tea", 3.5, Vector3(24, 0.5, -4)],                    # on the east mound
			["un llavero", "key", 3.5, Vector3(-41, 0, 11)],                            # west island
			["una figurita", "skate/character-skate-boy", 1.3, Vector3(17.2, 2.7, 16)],  # middle floating islet
		],
	},
	"traveller": {
		"sign": "Objetos perdidos", "character": "character-male-b", "hat": "",
		"speaker": "El viajero", "greeting": "¡Hola! ¡Qué desastre!\n¡Perdí mi equipaje!",
		"thanks": "¡Qué alivio!\n¡Toma un dulce!", "awning": Color(0.2, 0.7, 0.7),
		"reward": "food/ice-cream", "reward_scale": 4.0, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["city/detail-parasol-a", 2.0, -1.6]],
		"items": [
			["la maleta", "proc/suitcase", 3.0, Vector3(38.5, 0, 11.5)],      # east island
			["la cartera", "proc/wallet", 4.0, Vector3(-41, 0, 11)],           # west island
			["las llaves", "key", 3.5, Vector3(16.6, 5.0, -9.4)],             # top of the spring tower
		],
	},
	"newstudent": {
		"sign": "Secretaría", "character": "character-male-a", "hat": "",
		"speaker": "El alumno nuevo", "greeting": "¡Hola! Soy nuevo aquí.\n¡Perdí mis cosas!",
		"thanks": "¡Muchas gracias!\n¡Toma un dulce!", "awning": Color(0.45, 0.4, 0.9),
		"reward": "food/cupcake", "reward_scale": 3.2, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["furniture/books", 9.0, -1.6], ["food/apple", 3.0, 1.4]],
		"items": [
			["la mochila", "proc/backpack", 3.0, Vector3(38.5, 0, 11.5)],       # east island
			["el estuche", "proc/pencilcase", 4.0, Vector3(-41, 0, 11)],        # west island
			["la calculadora", "proc/calculator", 4.5, Vector3(16.6, 5.0, -9.4)],  # top of the spring tower
		],
	},
	"grandma": {
		"sign": "Casa de la abuela", "character": "character-female-d", "hat": "",
		"speaker": "La abuela", "greeting": "¡Hola, cariño!\n¡No encuentro mis cosas!",
		"thanks": "¡Eres un sol!\n¡Toma un dulce!", "awning": Color(0.95, 0.5, 0.65),
		"reward": "food/cake", "reward_scale": 1.7, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["proc/photo", 3.0, -1.5], ["food/cup-tea", 3.0, 1.4]],
		"items": [
			["el móvil", "proc/phone", 3.0, Vector3(38.5, 0, 11.5)],               # east island
			["las gafas", "characters/aid-glasses", 6.0, Vector3(-41, 0, 11)],      # west island
			["el cargador", "proc/charger", 3.0, Vector3(16.6, 5.0, -9.4)],        # top of the spring tower
		],
	},
	"musician": {
		"sign": "Escenario 2", "character": "character-male-d", "hat": "headband",
		"speaker": "El músico", "greeting": "¡Hola! ¡Tengo un concierto!\n¡Busca mis cosas!",
		"thanks": "¡Qué guay!\n¡Toma un dulce!", "awning": Color(0.95, 0.45, 0.2),
		"reward": "food/donut-sprinkles", "reward_scale": 4.0, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"floor_props": [["skate/skateboard", 2.6, Vector3(4.0, 0.0, 3.0), 0.4]],
		"counter": [["proc/speaker", 1.2, -1.5], ["proc/speaker", 1.2, 1.5]],
		"items": [
			["la guitarra", "proc/guitar", 2.6, Vector3(38.5, 0, 11.5)],          # east island
			["el micrófono", "proc/microphone", 3.0, Vector3(-41, 0, 11)],        # west island
			["las baquetas", "proc/drumsticks", 3.5, Vector3(16.6, 5.0, -9.4)],   # top of the spring tower
		],
	},
	"teacher": {
		"sign": "La Escuela", "character": "character-female-a", "hat": "",
		"speaker": "La profesora", "greeting": "¡Hola! Soy profesora.\n¡Necesito mis cosas!",
		"thanks": "¡Muy bien!\n¡Toma un dulce!", "awning": Color(0.55, 0.35, 0.85),
		"reward": "food/cupcake", "reward_scale": 3.2, "reward_hidden": true, "reward_pos": Vector3(0.6, 0.75, 1.7),
		"counter": [["furniture/books", 9.0, -1.6], ["food/apple", 3.0, 1.4]],
		"items": [
			["un libro", "furniture/books", 11.0, Vector3(-11.4, 1.0, -19.6)],           # on the little hill
			["unas gafas", "characters/aid-glasses", 6.0, Vector3(38.5, 0, 11.5)],      # east island
			["una taza de café", "food/cup-coffee", 3.0, Vector3(16.6, 5.0, -9.4)],     # top of the tower (spring!)
		],
	},
}

## Where cards go, easiest first.
const CARD_SLOTS := [
	Vector3(-10, 1.0, -18),     # little hill, north-west
	Vector3(-16, 1.8, -4),      # west plateau (up the stepping stones)
	Vector3(16, 5.0, -8),       # top of the tower (use the spring!)
	Vector3(20, 4.5, 8),        # end of the floating islet path
	Vector3(41, 0, 10.5),       # east island (stepping stones)
	Vector3(-24, 0.8, -7),      # far west hill
	Vector3(8, 0, 24),
	Vector3(-26, 0, 2),
]
## Chests in pairs: level 1 near the start, level 2 further out, level 3 hardest to reach.
const CHEST_SLOTS := [
	Vector3(-8, 0, 11),         # L1 near the start
	Vector3(6, 0.6, -12),       # L1 on the mound behind the whiteboard
	Vector3(40, 0, 4.5),        # L2 east island (stepping stones)
	Vector3(-4, 0, 25),         # L2 south meadow
	Vector3(-38.5, 0, 17),      # L3 west island (moving platform)
	Vector3(23, 0, -14),        # L3 past the tower, near the sweet shop
]

## Colour themes: each island (chapter) can pick one with "theme" in the course/lesson.
const THEMES := {
	"meadow":   {"grass": Color(0.4, 0.72, 0.27),  "dirt": Color(0.78, 0.48, 0.3),  "sand": Color(1.0, 0.84, 0.52),  "sky": Color(0.2, 0.48, 0.95),  "horizon": Color(0.78, 0.9, 1.0),  "deep": Color(0.07, 0.36, 0.8),  "shallow": Color(0.18, 0.6, 0.93),  "trees": ["tree", "tree", "tree-pine", "tree-pine-small"]},
	"sunset":   {"grass": Color(0.9, 0.58, 0.2),   "dirt": Color(0.82, 0.38, 0.32), "sand": Color(1.0, 0.82, 0.66),  "sky": Color(0.93, 0.45, 0.5),  "horizon": Color(1.0, 0.82, 0.6),  "deep": Color(0.35, 0.3, 0.7),   "shallow": Color(0.95, 0.55, 0.55), "trees": ["tree", "tree", "tree-pine"]},
	"mint":     {"grass": Color(0.16, 0.55, 0.42), "dirt": Color(0.3, 0.5, 0.68),   "sand": Color(0.9, 0.93, 0.78), "sky": Color(0.25, 0.68, 0.9),  "horizon": Color(0.82, 1.0, 0.95), "deep": Color(0.05, 0.45, 0.65), "shallow": Color(0.2, 0.78, 0.82),  "trees": ["tree", "tree-pine", "tree-pine-small"]},
	"lavender": {"grass": Color(0.56, 0.42, 0.86), "dirt": Color(0.5, 0.38, 0.75),  "sand": Color(0.96, 0.87, 1.0),  "sky": Color(0.45, 0.4, 0.92),  "horizon": Color(0.92, 0.84, 1.0), "deep": Color(0.25, 0.25, 0.75), "shallow": Color(0.45, 0.55, 0.95), "trees": ["tree", "tree", "tree-pine-small"]},
	"candy":    {"grass": Color(0.82, 0.33, 0.55), "dirt": Color(0.9, 0.7, 0.45),   "sand": Color(1.0, 0.94, 0.82),  "sky": Color(0.5, 0.62, 1.0),   "horizon": Color(1.0, 0.86, 0.93), "deep": Color(0.3, 0.45, 0.9),  "shallow": Color(0.55, 0.78, 1.0),  "trees": ["tree", "tree", "tree-pine"]},
	"tropical": {"grass": Color(0.32, 0.57, 0.22), "dirt": Color(0.85, 0.62, 0.38), "sand": Color(1.0, 0.9, 0.62), "sky": Color(0.15, 0.55, 0.98), "horizon": Color(0.75, 0.95, 1.0), "deep": Color(0.0, 0.45, 0.75), "shallow": Color(0.15, 0.85, 0.85), "trees": ["pirate/palm-straight", "pirate/palm-bend", "pirate/palm-detailed-bend", "tree"], "tree_scale": 0.75, "props": [["city/detail-parasol-a", 6.0, 14], ["city/detail-parasol-b", 6.0, 10]]},
	"digital":  {"grass": Color(0.42, 0.42, 0.68), "dirt": Color(0.45, 0.33, 0.6),  "sand": Color(0.82, 0.78, 0.96), "sky": Color(0.16, 0.12, 0.42), "horizon": Color(0.98, 0.55, 0.78), "deep": Color(0.06, 0.18, 0.5), "shallow": Color(0.25, 0.55, 0.95), "sun": Color(1.0, 0.8, 0.9), "sun_energy": 0.9, "trees": ["tree-pine", "tree-pine-small", "tree"], "props": [["proc/lamp", 2.0, 16], ["proc/screen", 1.6, 8]]},
	"festival": {"grass": Color(0.93, 0.56, 0.74), "dirt": Color(0.75, 0.42, 0.7), "sand": Color(1.0, 0.9, 0.82), "sky": Color(0.42, 0.55, 1.0), "horizon": Color(1.0, 0.85, 0.93), "deep": Color(0.25, 0.35, 0.85), "shallow": Color(0.45, 0.7, 1.0), "trees": ["fair/tree", "fair/tree-large"], "tree_scale": 2.2, "props": [["fair/stall-food", 2.6, 5], ["fair/stall-drinks", 2.6, 5], ["proc/speaker", 2.0, 8], ["arcade/claw-machine", 2.6, 4]]},
	"industria": {"grass": Color(0.46, 0.49, 0.56), "dirt": Color(0.88, 0.55, 0.2), "sand": Color(0.85, 0.82, 0.74), "sky": Color(0.4, 0.6, 0.85), "horizon": Color(0.9, 0.9, 0.95), "deep": Color(0.08, 0.3, 0.55), "shallow": Color(0.2, 0.5, 0.75), "trees": ["tree-pine", "tree-pine-small"], "tree_scale": 0.9, "props": [["water/cargo-container-a", 1.4, 8, "box"], ["water/cargo-container-c", 1.4, 8, "box"], ["conveyor/box-large", 1.4, 10, "box"], ["barrel", 2.0, 10]]},
	"volcan":   {"grass": Color(0.36, 0.3, 0.33), "dirt": Color(0.9, 0.42, 0.15), "sand": Color(0.25, 0.22, 0.25), "sky": Color(0.5, 0.35, 0.45), "horizon": Color(1.0, 0.62, 0.42), "deep": Color(0.08, 0.2, 0.45), "shallow": Color(0.2, 0.42, 0.6), "sun": Color(1.0, 0.75, 0.6), "trees": ["graveyard/pine-crooked", "tree-pine", "tree-pine-small"], "props": [["pirate/rocks-a", 0.9, 10], ["pirate/rocks-b", 0.9, 10]]},
	"fiesta":   {"grass": Color(0.5, 0.74, 0.32), "dirt": Color(0.86, 0.52, 0.32), "sand": Color(1.0, 0.86, 0.6), "sky": Color(0.32, 0.58, 1.0), "horizon": Color(1.0, 0.86, 0.66), "deep": Color(0.06, 0.36, 0.78), "shallow": Color(0.2, 0.64, 0.95), "trees": ["tree", "fair/tree-large", "tree"], "props": [["proc/bunting", 1.0, 12, ""], ["graveyard/lantern-candle", 2.6, 10], ["fair/stall-drinks", 2.6, 4]]},
	"ciudad":   {"grass": Color(0.42, 0.74, 0.74), "dirt": Color(0.4, 0.5, 0.62), "sand": Color(1.0, 0.93, 0.78), "sky": Color(0.22, 0.52, 0.98), "horizon": Color(0.85, 0.94, 1.0), "deep": Color(0.03, 0.16, 0.5), "shallow": Color(0.12, 0.34, 0.78), "trees": ["tree", "tree", "fair/tree-large"], "tree_scale": 1.0, "props": [["holiday/bench", 2.4, 10], ["fair/trash", 2.6, 8], ["flag", 2.0, 6]]},
	"campus":   {"grass": Color(0.86, 0.66, 0.28), "dirt": Color(0.72, 0.42, 0.26), "sand": Color(0.98, 0.88, 0.62), "sky": Color(0.35, 0.55, 0.92), "horizon": Color(1.0, 0.9, 0.75), "deep": Color(0.08, 0.35, 0.72), "shallow": Color(0.25, 0.6, 0.9), "trees": ["tree", "tree", "tree-pine", "tree-pine-small"], "props": [["holiday/bench", 2.4, 14], ["flag", 2.0, 6]]},
	"snow":     {"grass": Color(0.84, 0.89, 0.97), "dirt": Color(0.58, 0.68, 0.85), "sand": Color(0.85, 0.9, 0.98),  "sky": Color(0.42, 0.58, 0.85), "horizon": Color(0.9, 0.95, 1.0),  "deep": Color(0.1, 0.3, 0.55),   "shallow": Color(0.4, 0.65, 0.85),  "trees": ["tree-snow", "tree-pine-snow", "tree-pine-snow-small"]},
}

var player: CharacterBody3D
var theme: Dictionary = THEMES.meadow
var bridge: Node3D
var whiteboard: Node3D
var ghost: Node3D
var ship: Node3D
var cafe: Node3D
var healthy_field: Node3D
var skateboard: AnimatableBody3D
var rowboat: Node3D
var circuit: Node3D
var routine: Node3D
var speedboat: Node3D
var timetable: Node3D
var headteacher: Node3D
var towers: Node3D
var stage: Node3D
var ferry: Node3D
var town: Node3D
var restaurant: Node3D
var fishing: Node3D
var tomatina: Node3D
var pinata: Node3D
var sorter: Node3D
var crane: Node3D
var office: Node3D
var towing: Node3D
var volcano: Node3D
var reforest: Node3D
var liner: Node3D
var liner_boat: Node3D
var _nostar: Array = []    # [Vector2 centre, radius]: big set-pieces the fixed star trail must avoid
var tug: Node3D
var market: Node3D
var noria: Node3D
var cards: Array[Node3D] = []
var chests: Array[Node3D] = []
var sweets: Array[Node3D] = []
var retos: Array[Node3D] = []

var _grass: StandardMaterial3D
var _dirt: StandardMaterial3D
var _sand: StandardMaterial3D
var _foam: StandardMaterial3D
var _rng := RandomNumberGenerator.new()
var _keepout: Array = []   # [Vector2 center, radius]
var _jetty_rects: Array = []   # every jetty, as a solid rectangle for boats that collide with them
var _mover: AnimatableBody3D
var _mover_t := 0.0
var _mover_a := Vector3(-28.2, -0.4, 14)
var _mover_b := Vector3(-33.4, -0.4, 14)
var _clouds: Array[Node3D] = []


## Pushes a point that lies beyond the base coastline outwards to match a bigger island.
func ex(p: Vector3) -> Vector3:
	var f := Vector2(p.x, p.z)
	if D <= 0.0 or f.length() < 29.0:
		return p
	var n := f.normalized() * D
	return p + Vector3(n.x, 0, n.y)


func build(lesson: Dictionary, theme_name := "meadow") -> void:
	_rng.seed = 12345
	MAIN_R = BASE_R * float(Game.config.get("world_scale", 1.0))
	D = MAIN_R - BASE_R
	PRIZE_CENTER = Vector3(0, 0, -(MAIN_R + 21))
	EAST_ISLAND = ex(Vector3(40, 0, 8))
	WEST_ISLAND = ex(Vector3(-40, 0, 14))
	KEY_SPOT = ex(Vector3(-42, 0, 11.5))
	_mover_a = ex(Vector3(-28.2, -0.4, 14))
	_mover_b = ex(Vector3(-33.4, -0.4, 14))
	var t = lesson.get("theme", "")
	if t is String and THEMES.has(t):
		theme_name = t
	theme = THEMES.get(theme_name, THEMES.meadow)
	_grass = Props.mat(theme.grass)
	_dirt = Props.mat(theme.dirt)
	_sand = Props.mat(theme.sand)
	_foam = Props.unshaded(Color(1, 1, 1, 0.55))

	_environment()
	_sea()

	# Islands
	_island(Vector3.ZERO, MAIN_R, 96)
	_island(PRIZE_CENTER, 6.0)
	_island(EAST_ISLAND, 5.0)
	_island(WEST_ISLAND, 5.0)

	# West plateau with stepping-stone steps up to it
	_pillar(Vector3(-16, 0, -4), 3.5, 1.8)
	_pillar(Vector3(-17.5, 0, 1.6), 1.1, 0.6)
	_pillar(Vector3(-16.2, 0, 0.3), 1.0, 1.2)
	_keep(Vector3(-16, 0, -4), 4.2)
	_keep(Vector3(-17, 0, 1), 2.4)
	# Tower (reach the top with the spring)
	_pillar(Vector3(16, 0, -8), 2.2, 5.0)
	_keep(Vector3(16, 0, -8), 3.2)
	var spring := Node3D.new()
	spring.set_script(preload("res://scripts/spring_pad.gd"))
	add_child(spring)
	spring.position = Vector3(12.8, 0, -5.2)
	_keep(spring.position, 1.8)
	# Floating islets leading up to a tall pillar
	for p in [Vector3(14, 1.6, 15), Vector3(17.2, 2.7, 16), Vector3(20.5, 3.8, 12.4)]:
		_floating_islet(p, 1.35)
	_pillar(Vector3(20, 0, 8), 1.8, 4.5)
	_keep(Vector3(20, 0, 8), 2.8)
	# Little hill and some gentle mounds for variety
	_pillar(Vector3(-10, 0, -18), 2.5, 1.0)
	_keep(Vector3(-10, 0, -18), 3.2)
	for m in [[Vector3(6, 0, -12), 3.5, 0.6], [Vector3(-24, 0, -7), 3.2, 0.8], [Vector3(24, 0, -4), 3.0, 0.5], [Vector3(-8, 0, 22), 2.6, 0.5]]:
		_pillar(m[0], m[1], m[2])
		_keep(m[0], m[1] + 0.6)

	# Stepping stones to the east island
	for x in [30.8, 32.9]:
		_pillar(ex(Vector3(x, 0, 8)), 0.8, 0.2, 5.0)
	# Moving platform to the west island
	_mover = AnimatableBody3D.new()
	_mover.add_to_group("moving")
	var mm := Props.model("platform-fortified")
	mm.scale = Vector3(2.6, 2.0, 2.6)
	_mover.add_child(mm)
	var mcs := CollisionShape3D.new()
	var mshape := BoxShape3D.new()
	mshape.size = Vector3(2.6, 0.42, 2.6)
	mcs.shape = mshape
	mcs.position.y = 0.21
	_mover.add_child(mcs)
	add_child(_mover)
	_mover.position = _mover_a

	# Whiteboard
	whiteboard = Node3D.new()
	whiteboard.set_script(preload("res://scripts/whiteboard.gd"))
	add_child(whiteboard)
	whiteboard.position = Vector3(0, 0, -2)
	whiteboard.setup(lesson)
	whiteboard.touched.connect(func(): whiteboard_touched.emit())
	_keep(Vector3(0, 0, -2), 5.5)
	_keep(Vector3(0, 0, 1.5), 3.0)
	_keep(SPAWN, 3.0)

	# Bridge to Star Island: one section per question card.
	var n_cards := mini(lesson.cards.size(), CARD_SLOTS.size())
	bridge = Node3D.new()
	bridge.set_script(preload("res://scripts/bridge.gd"))
	add_child(bridge)
	bridge.position = Vector3(0, 0, -MAIN_R + 0.6)
	# From just inside the main island's edge to just inside Star Island's edge.
	var blen := (-PRIZE_CENTER.z - 6.0 + 0.4) - (MAIN_R - 0.6)
	bridge.setup(maxi(n_cards, 1), blen)
	for x in [-2.4, 2.4]:
		Props.place(self, "flag", Vector3(x, 0, -MAIN_R + 1.4), 0.0, 2.2, "cyl")
	var sign := Props.place(self, "sign", Vector3(3.6, 0, -MAIN_R + 2.0), -0.3, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "Star\nIsland"
	sl.font_size = 40
	sl.pixel_size = 0.005
	sl.modulate = Color(0.4, 0.22, 0.1)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)
	for x in range(-3, 4):
		_keep(Vector3(x, 0, -MAIN_R + 2), 2.0)
	if n_cards == 0:
		bridge.build_next()

	# Prize
	var prize := Node3D.new()
	prize.set_script(preload("res://scripts/prize.gd"))
	add_child(prize)
	prize.position = PRIZE_CENTER + Vector3(0, 0, -1)
	prize.setup(lesson.prize.name)
	prize.claimed.connect(func(): prize_claimed.emit())
	prize.can_claim = func() -> bool: return bridge.built >= bridge.sections
	# Keep the walk from the bridge to the prize clear of trees.
	for z in range(int(PRIZE_CENTER.z) + 6, int(PRIZE_CENTER.z) - 3, -1):
		_keep(Vector3(0, 0, z), 2.2)

	# Question cards
	var tex: Texture2D = preload("res://scripts/question_card.gd").card_texture()
	for i in n_cards:
		var c := Node3D.new()
		c.set_script(preload("res://scripts/question_card.gd"))
		add_child(c)
		c.position = ex(CARD_SLOTS[i])
		c.setup(lesson.cards[i], i, tex)
		c.touched.connect(func(card): card_touched.emit(card))
		cards.append(c)
		_keep(c.position, 2.0)

	# Quiz chests
	for i in mini(lesson.chests.size(), CHEST_SLOTS.size()):
		var ch := Node3D.new()
		ch.set_script(preload("res://scripts/quiz_chest.gd"))
		add_child(ch)
		ch.position = ex(CHEST_SLOTS[i])
		ch.rotation.y = atan2(-ch.position.x, -ch.position.z)
		ch.setup(lesson.chests[i], int(lesson.chests[i].get("level", i / 2 + 1)))
		ch.set_level_locked(ch.level > 1)
		ch.touched.connect(func(chest): chest_touched.emit(chest))
		chests.append(ch)
		_keep(ch.position, 2.5)

	# Sweets: bonus challenges in special places. Each island's lesson picks which ones.
	var ship_qs := {}
	var sweet_list: Array = lesson.get("sweets", []).duplicate()
	sweet_list.sort_custom(func(a, b): return str(a.get("kind", "")) == "boat" and str(b.get("kind", "")) != "boat")
	for q in sweet_list:
		match str(q.get("kind", "")):
			"key":
				if not _has_sweet_at(SWEET_SHOP):
					_build_sweet_shop(q)
			"guarded":
				if not _has_sweet_at(GHOST_GARDEN):
					_build_ghost_garden(q)
			"ship_deck", "ship_crow":
				ship_qs[str(q.kind)] = q
			"boat":
				if rowboat == null:
					_build_boat_trip(q)
			"white_ship":
				_build_white_ship(q)
			"circuit":
				if circuit == null:
					_build_circuit(q)
			"routine":
				if routine == null:
					_build_routine(q)
			"tower":
				if speedboat == null:
					_build_tower_trip(q)
			"timetable":
				if timetable == null:
					_build_timetable(q)
			"headteacher":
				if headteacher == null:
					_build_headteacher(q)
			"towers":
				if towers == null:
					_build_towers(q)
			"hidden":
				_build_hidden(q)
			"ferry":
				if ferry == null:
					_build_ferry(q)
			"restaurant":
				if restaurant == null:
					_build_restaurant(q)
			"tomatina":
				if tomatina == null:
					_build_tomatina(q)
			"pinata":
				if pinata == null:
					_build_pinata(q)
			"sorter":
				if sorter == null:
					_build_sorter(q)
			"crane":
				if crane == null:
					_build_crane(q)
			"interview":
				if office == null:
					_build_office(q)
			"tug":
				if towing == null:
					_build_tug(q)
			"volcano":
				if volcano == null:
					_build_volcano(q)
			"trees":
				if reforest == null:
					_build_reforest(q)
			"liner":
				if liner == null:
					_build_liner(q)
			"directions":
				if town == null:
					_build_town(q)
			"market":
				if market == null:
					_build_market(q)
			"rhythm":
				if stage == null:
					_build_stage(q)
			"ferris":
				if noria == null:
					_build_noria(q)
			"chef", "trainer", "recycler", "tourist", "teacher", "traveller", "newstudent", "grandma", "musician":
				if not _has_sweet_at(CAFE):
					_build_quest(q, QUESTS[str(q.kind)])
			"healthy_field":
				if not _has_sweet_at(HEALTHY_FIELD):
					_build_healthy_field(q)
	if not ship_qs.is_empty():
		_build_ship(ship_qs)

	_build_retos(lesson.get("retos", []))
	_stars()
	_decorate()
	_make_clouds()

	Game.total_cards = n_cards
	Game.total_chests = chests.size()
	Game.total_sweets = sweets.size()


func spawn_player(character_name: String) -> CharacterBody3D:
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/player.gd"))
	player.add_to_group("player")
	# Position before entering the tree, otherwise physics briefly sees it at the origin
	# (inside the whiteboard's trigger zone).
	player.position = SPAWN
	add_child(player)
	player.setup(character_name, SPAWN)
	return player


func _physics_process(delta: float) -> void:
	if _mover:
		_mover_t += delta
		_mover.position = _mover_a.lerp(_mover_b, sin(_mover_t * 0.9) * 0.5 + 0.5)


func _process(delta: float) -> void:
	for c in _clouds:
		c.position.x += delta * 0.6
		if c.position.x > 110:
			c.position.x = -110


# ---------------------------------------------------------------- sweets

func _has_sweet_at(p: Vector3) -> bool:
	for s in sweets:
		if s.get_meta("area") == p:
			return true
	return false


func _add_sweet(q: Dictionary, model: String, pos: Vector3, area: Vector3, scale := 5.0) -> Node3D:
	var s := Node3D.new()
	s.set_script(preload("res://scripts/sweet.gd"))
	add_child(s)
	s.global_position = pos
	s.setup(q, model, scale)
	s.set_meta("area", area)
	s.touched.connect(func(sweet): sweet_touched.emit(sweet))
	sweets.append(s)
	return s


## The sweet shop: locked hut; the key is hidden on the west island.
func _build_sweet_shop(q: Dictionary) -> void:
	var shop := Node3D.new()
	shop.set_script(preload("res://scripts/sweet_shop.gd"))
	add_child(shop)
	shop.position = SWEET_SHOP
	var to_centre := -SWEET_SHOP.normalized()
	shop.rotation.y = atan2(to_centre.x, to_centre.z)   # door faces the middle of the island
	shop.setup()
	_keep(SWEET_SHOP, 6.5)
	_keep(SWEET_SHOP + to_centre * 6.0, 2.0)
	_add_sweet(q, "food/cupcake", SWEET_SHOP + Vector3(0, 0.1, 0), SWEET_SHOP)

	var key := Area3D.new()
	key.set_script(preload("res://scripts/key_pickup.gd"))
	key.position = KEY_SPOT
	add_child(key)
	_keep(KEY_SPOT, 1.5)


## The ghost garden: a lollipop on a pedestal, guarded by a patrolling ghost.
func _build_ghost_garden(q: Dictionary) -> void:
	_pillar(GHOST_GARDEN, 1.2, 1.2)
	_keep(GHOST_GARDEN, 6.5)
	var lolly := _add_sweet(q, "food/lollypop", GHOST_GARDEN + Vector3(0, 1.2, 0), GHOST_GARDEN)
	ghost = Node3D.new()
	ghost.set_script(preload("res://scripts/ghost.gd"))
	add_child(ghost)
	ghost.setup(GHOST_GARDEN, 3.2)
	ghost.guarded_sweet = lolly
	# Spooky-cute decorations in a ring: pumpkins, lanterns and gravestones.
	var deco := ["graveyard/pumpkin-carved", "graveyard/lantern-candle", "graveyard/gravestone-round", "graveyard/pumpkin"]
	for i in 12:
		var a := TAU * i / 12.0 + 0.2
		var p := GHOST_GARDEN + Vector3(cos(a), 0, sin(a)) * 6.0
		Props.place(self, deco[i % deco.size()], p, -a + PI / 2, 2.6, "")
	var warn := Props.place(self, "sign", GHOST_GARDEN + Vector3(5.5, 0, -4.5), -0.8, 2.5, "box")
	var wl := Label3D.new()
	wl.text = "¡Cuidado!\nFantasma"
	wl.font_size = 34
	wl.pixel_size = 0.005
	wl.modulate = Color(0.45, 0.15, 0.35)
	wl.position = Vector3(0, 1.1, 0.22)
	warn.add_child(wl)


## The pirate ship beside a jetty: one sweet on deck (past the cannons), one in the crow's nest.
func _build_ship(qs: Dictionary) -> void:
	# Jetty from the beach out along the ship's side.
	var jetty := StaticBody3D.new()
	jetty.add_to_group("solid_ground")
	add_child(jetty)
	var length := JETTY_Z.y - JETTY_Z.x
	jetty.position = Vector3(JETTY_X, 0, (JETTY_Z.x + JETTY_Z.y) / 2.0)
	var deck := BoxMesh.new()
	deck.size = Vector3(3.0, 0.3, length)
	deck.material = Props.mat(Color(0.7, 0.48, 0.32))
	var dmi := MeshInstance3D.new()
	dmi.mesh = deck
	dmi.position.y = -0.15
	jetty.add_child(dmi)
	var dcs := CollisionShape3D.new()
	var dsh := BoxShape3D.new()
	dsh.size = deck.size
	dcs.shape = dsh
	dcs.position.y = -0.15
	jetty.add_child(dcs)
	var post_mat := Props.mat(Color(0.5, 0.33, 0.22))
	for i in int(length / 3.0) + 1:
		for side in [-1.5, 1.5]:
			var post := CylinderMesh.new()
			post.top_radius = 0.16
			post.bottom_radius = 0.16
			post.height = 2.6
			post.material = post_mat
			var pm := MeshInstance3D.new()
			pm.mesh = post
			pm.position = Vector3(side, -0.9, -length / 2.0 + i * 3.0)
			jetty.add_child(pm)
	for z in range(int(JETTY_Z.x) - 2, int(JETTY_Z.y) + 1, 2):
		_keep(Vector3(JETTY_X, 0, z), 2.2)
	# Clutter on the jetty - kept well clear of the gangplank (which starts at ship z-1).
	Props.place(self, "pirate/barrel", Vector3(JETTY_X - 0.9, 0, JETTY_Z.y - 0.8), 0.3, 1.0, "cyl")
	Props.place(self, "pirate/crate-bottles", Vector3(JETTY_X + 0.7, 0, JETTY_Z.x + 5.0), 0.2, 1.3, "box")

	ship = Node3D.new()
	ship.set_script(preload("res://scripts/pirate_ship.gd"))
	add_child(ship)
	ship.position = SHIP
	ship.setup()
	if qs.has("ship_deck"):
		_add_sweet(qs.ship_deck, "food/donut-sprinkles", ship.to_global(ship.deck_sweet_spot()), SHIP)
	if qs.has("ship_crow"):
		_add_sweet(qs.ship_crow, "food/candy-bar-wrapper", ship.to_global(ship.nest_sweet_spot()), SHIP + Vector3.UP)
	# Stars up the rigging, to lure climbers.
	var steps: Array[Vector3] = ship.climb_steps()
	for k: int in [1, 3, 5, 7]:
		_star(ship.to_global(steps[k] + Vector3(0, 0.7, 0)))


## The rowing trip: a jetty on the far shore, a boat, buoys and rocks, and Isla Secreta.
func _build_boat_trip(q: Dictionary) -> void:
	var d := BOAT_DIR
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 7.0))
	for k in range(int(MAIN_R) - 6, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	var sign := Props.place(self, "sign", d * (MAIN_R - 3.5) + side * 2.4, atan2(d.x, d.z) + PI, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "¡A remar!"
	sl.font_size = 40
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.3, 0.6)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)

	# Isla Secreta: a tiny palm island far out to sea with the sweet on it.
	_island(SECRET_ISLAND, SECRET_R)
	_add_sweet(q, "food/ice-cream", SECRET_ISLAND + Vector3(-0.5, 0.1, -0.5), SECRET_ISLAND, 4.0)
	for p in [Vector3(-2.8, 0, 1.8), Vector3(2.4, 0, -2.6), Vector3(-1.5, 0, -3.3)]:
		Props.place(self, "pirate/palm-detailed-bend", SECRET_ISLAND + p, _rng.randf() * TAU, 1.3, "trunk")
	var flag := Props.model("pirate/flag-pirate-high")
	flag.scale = Vector3.ONE * 1.6
	flag.position = SECRET_ISLAND + Vector3(3.2, 0, 2.6)
	add_child(flag)
	var isl := Label3D.new()
	isl.text = "Isla Secreta"
	isl.font = preload("res://scripts/ui.gd").ui_font(700)
	isl.font_size = 96
	isl.pixel_size = 0.01
	isl.outline_size = 20
	isl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	isl.outline_modulate = Color(0.3, 0.2, 0.5)
	isl.position = SECRET_ISLAND + Vector3(0, 6.5, 0)
	add_child(isl)

	# The boat, moored at the end of the jetty.
	rowboat = Node3D.new()
	rowboat.set_script(preload("res://scripts/rowboat.gd"))
	add_child(rowboat)
	rowboat.global_position = d * (MAIN_R + 9.0) + side * 0.5
	rowboat.rotation.y = atan2(-d.x, -d.z)
	rowboat.setup()
	rowboat.shores = [[Vector3.ZERO, MAIN_R], [SECRET_ISLAND, SECRET_R], [EAST_ISLAND, 5.0], [WEST_ISLAND, 5.0], [PRIZE_CENTER, 6.0]]
	for s in rowboat.shores:
		rowboat.blockers.append([Vector2(s[0].x, s[0].z), s[1] + 2.2])

	# Slalom out to sea: rocks to dodge, buoys to row between, stars to grab on the way.
	var start := Vector2(rowboat.global_position.x, rowboat.global_position.z)
	var goal := Vector2(SECRET_ISLAND.x, SECRET_ISLAND.z)
	var path := goal - start
	var across := Vector2(-path.y, path.x).normalized()
	for i in 5:
		var t := (i + 1) / 6.0
		var mid := start + path * t
		var wiggle := across * (4.5 if i % 2 == 0 else -4.5)
		# Rock on one side of the channel, a pair of buoys marking the gap on the other.
		var rock_at := mid + wiggle
		Props.place(self, "pirate/rocks-a" if i % 2 == 0 else "pirate/rocks-b", Vector3(rock_at.x, -1.6, rock_at.y), _rng.randf() * TAU, 1.3, "")
		rowboat.blockers.append([rock_at, 3.0])
		for side_off: float in [-3.0, 3.0]:
			var b := mid - wiggle * 0.3 + across * side_off
			var buoy := Props.model("water/buoy-flag" if side_off > 0 else "water/buoy")
			buoy.scale = Vector3.ONE * 1.6
			buoy.position = Vector3(b.x, -1.2, b.y)
			add_child(buoy)
			rowboat.blockers.append([b, 0.8])
		var star_at := mid - wiggle * 0.3
		_star(Vector3(star_at.x, -0.4, star_at.y))


## A white ship anchored far out at sea - no buoys, no signs, properly secret.
## Row alongside and hop onto its deck to find the sweet.
func _build_white_ship(q: Dictionary) -> void:
	var ship_root := Node3D.new()
	add_child(ship_root)
	ship_root.position = WHITE_SHIP
	ship_root.rotation.y = 0.7
	var model := Props.model("pirate/ship-small")
	model.scale = Vector3.ONE * 1.6
	ship_root.add_child(model)
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	ship_root.add_child(body)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if not mi.name.begins_with("ship"):
			continue
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		cs.transform = ship_root.global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform
		body.add_child(cs)
	_add_sweet(q, "food/chocolate-wrapper", ship_root.to_global(Vector3(0.9, 3.36, 2.4)), WHITE_SHIP, 5.0)
	var deck: Vector3 = ship_root.to_global(Vector3(0, 3.7, 1.4))
	if rowboat:
		rowboat.shores.append([Vector3(WHITE_SHIP.x, deck.y, WHITE_SHIP.z), 4.0, deck])
		rowboat.blockers.append([Vector2(WHITE_SHIP.x, WHITE_SHIP.z), 4.2])


## La rutina diaria: a hut whose door opens when the routine pads are stepped on in order.
func _build_routine(q: Dictionary) -> void:
	var hut := Node3D.new()
	hut.set_script(preload("res://scripts/sweet_shop.gd"))
	add_child(hut)
	hut.position = ROUTINE_HUT
	var to_centre := -ROUTINE_HUT.normalized()
	hut.rotation.y = atan2(to_centre.x, to_centre.z)
	hut.setup("La rutina", false, Color(0.55, 0.75, 1.0), Color(0.3, 0.45, 0.9))
	_add_sweet(q, "food/cupcake", ROUTINE_HUT + Vector3(0, 0.1, 0), ROUTINE_HUT)
	routine = Node3D.new()
	routine.set_script(preload("res://scripts/routine_pads.gd"))
	hut.add_child(routine)
	routine.position = Vector3(0, 0, 5.0)
	routine.setup()
	routine.hut = hut
	_keep(ROUTINE_HUT, 6.0)
	for k in range(4, 13, 2):
		_keep(ROUTINE_HUT + to_centre * k, 5.5)


## The speedboat trip: a jetty on the east shore, a fast boat, rocks to dodge, and La Torre -
## a tall pirate tower on a far island with planks spiralling up to a lookout on top.
func _build_tower_trip(q: Dictionary) -> void:
	var d := SPEED_DIR
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 7.0))
	for k in range(int(MAIN_R) - 6, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	var sign := Props.place(self, "sign", d * (MAIN_R - 3.5) + side * 2.4, atan2(d.x, d.z) + PI, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "¡A la torre!"
	sl.font_size = 36
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.3, 0.6)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)

	# La Torre on its island.
	_island(TOWER_ISLE, TOWER_ISLE_R)
	var tower := Props.place(self, "pirate/tower-complete-large", TOWER_ISLE, 0.3, TOWER_SCALE, "cyl")
	tower.add_to_group("solid_ground")
	var wood := Props.mat(Color(0.72, 0.5, 0.33))
	var steps := 11
	var r := 3.8
	var y0 := 1.1
	var dy := (TOWER_TOP - 1.2 - y0) / (steps - 1)
	for i in steps:
		var a := i * deg_to_rad(40)
		var p := TOWER_ISLE + Vector3(cos(a) * r, y0 + i * dy, sin(a) * r)
		var b := StaticBody3D.new()
		b.add_to_group("solid_ground")
		add_child(b)
		b.position = p
		b.rotation.y = -a
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 0.2, 1.5)
		box.material = wood
		var mi := MeshInstance3D.new()
		mi.mesh = box
		b.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = box.size
		cs.shape = sh
		b.add_child(cs)
		if i % 3 == 1:
			_star(p + Vector3(0, 0.8, 0))
	# Lookout platform on top.
	var top := StaticBody3D.new()
	top.add_to_group("solid_ground")
	add_child(top)
	top.position = TOWER_ISLE + Vector3(0, TOWER_TOP, 0)
	var disc := CylinderMesh.new()
	disc.top_radius = 3.1
	disc.bottom_radius = 2.6
	disc.height = 0.4
	disc.material = wood
	var dmi := MeshInstance3D.new()
	dmi.mesh = disc
	dmi.position.y = -0.2
	top.add_child(dmi)
	var dcs := CollisionShape3D.new()
	var dsh := CylinderShape3D.new()
	dsh.radius = 3.1
	dsh.height = 0.4
	dcs.shape = dsh
	dcs.position.y = -0.2
	top.add_child(dcs)
	var flag := Props.model("pirate/flag-pirate-high")
	flag.scale = Vector3.ONE * 1.4
	flag.position = Vector3(-1.4, 0, -1.4)
	top.add_child(flag)
	_add_sweet(q, "food/donut-sprinkles", TOWER_ISLE + Vector3(0.6, TOWER_TOP, 0.6), TOWER_ISLE, 5.0)
	var lbl := Label3D.new()
	lbl.text = "La Torre"
	lbl.font = preload("res://scripts/ui.gd").ui_font(700)
	lbl.font_size = 96
	lbl.pixel_size = 0.01
	lbl.outline_size = 20
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.outline_modulate = Color(0.25, 0.3, 0.6)
	lbl.position = TOWER_ISLE + Vector3(0, TOWER_TOP + 4.5, 0)
	add_child(lbl)
	for j in 3:
		var a2 := 1.4 + j * 1.9
		Props.place(self, "pirate/palm-detailed-bend", TOWER_ISLE + Vector3(cos(a2), 0, sin(a2)) * 5.2, _rng.randf() * TAU, 1.2, "trunk")

	# The speedboat: fast, with spray.
	speedboat = Node3D.new()
	speedboat.set_script(preload("res://scripts/rowboat.gd"))
	add_child(speedboat)
	speedboat.global_position = d * (MAIN_R + 9.5) + side * 0.4
	speedboat.rotation.y = atan2(-d.x, -d.z)
	speedboat.boat_name = "speedboat"
	speedboat.seat_offset = Vector3(0, 0.75, 0.9)
	speedboat.current_mul = 2.0
	speedboat.DRAG = 6.0       # lets go of the throttle = quick stop, so you can hop out
	speedboat.setup("water/boat-speed-a", 2.2, PI, 14.0, 7.0)
	speedboat.add_wake()
	speedboat.shores = [[Vector3.ZERO, MAIN_R], [TOWER_ISLE, TOWER_ISLE_R], [EAST_ISLAND, 5.0], [WEST_ISLAND, 5.0], [PRIZE_CENTER, 6.0]]
	for s in speedboat.shores:
		speedboat.blockers.append([Vector2(s[0].x, s[0].z), s[1] + 2.2])
	# Rocks scattered across the route - no buoys this time.
	var start := Vector2(speedboat.global_position.x, speedboat.global_position.z)
	var goal := Vector2(TOWER_ISLE.x, TOWER_ISLE.z)
	var path := goal - start
	var across := Vector2(-path.y, path.x).normalized()
	for i in 6:
		var t := (i + 1) / 7.0
		var at := start + path * t + across * (5.5 if i % 2 == 0 else -3.5) * (1.0 if i % 3 != 2 else -1.0)
		Props.place(self, "pirate/rocks-a" if i % 2 == 0 else "pirate/rocks-b", Vector3(at.x, -1.6, at.y), _rng.randf() * TAU, 1.2, "")
		speedboat.blockers.append([at, 2.8])


## Retos (IGCSE challenges) sit around the outer ring of the island: [angle in degrees,
## fraction of the island radius]. Postcards use the P slots in order; one notice board
## and one detective set-piece get their own spots.
const RETO_SLOTS := {
	"postcard": [[37.0, 0.84], [124.0, 0.86], [-45.0, 0.85], [160.0, 0.55], [-135.0, 0.55]],
	"notice": [[195.0, 0.85]],
	"detective": [[75.0, 0.84]],
	"chat": [[240.0, 0.6]],
}


func _slot(kind: String, i: int) -> Vector3:
	var list: Array = RETO_SLOTS[kind]
	var s: Array = list[mini(i, list.size() - 1)]
	var a := deg_to_rad(s[0])
	return Vector3(cos(a), 0, sin(a)) * MAIN_R * float(s[1])


## [angle in degrees, fraction of the island radius] -> a spot on the island.
func _at(a: Array) -> Vector3:
	var ang := deg_to_rad(float(a[0]))
	return Vector3(cos(ang), 0, sin(ang)) * MAIN_R * float(a[1])


func _build_retos(list: Array) -> void:
	var used := {"postcard": 0, "notice": 0, "detective": 0, "chat": 0}
	for r in list:
		var kind := str(r.get("kind", "postcard"))
		if not used.has(kind):
			continue
		var pos := _slot(kind, used[kind])
		used[kind] += 1
		if r.has("at"):      # a lesson can place a reto itself: [angle in degrees, fraction of radius]
			pos = _at(r.at)
		var face := atan2(-pos.x, -pos.z)        # face the middle of the island
		var node: Node3D
		if kind == "detective":
			node = Node3D.new()
			node.set_script(preload("res://scripts/detective.gd"))
			add_child(node)
			node.position = pos
			node.rotation.y = face
			node.setup(r)
			node.reviewer_touched.connect(func(i): reto_touched.emit(node, i))
			node.desk_touched.connect(func(): reto_touched.emit(node, -1))
			_keep(pos, 8.0)
		else:
			node = Node3D.new()
			node.set_script(preload("res://scripts/reto_spot.gd"))
			add_child(node)
			node.position = pos
			node.rotation.y = face
			node.setup(r)
			node.touched.connect(func(spot): reto_touched.emit(spot, 0))
			_keep(pos, 3.0)
		retos.append(node)
	Game.total_retos = retos.size()


## El horario: ring the bell, read the timetable, run to the right classroom in time.
## [angle, fraction] can be set in the lesson with "at"; faces the middle of the island.
func _build_timetable(q: Dictionary) -> void:
	var pos := _at(q.get("at", [240.0, 0.72]))
	timetable = Node3D.new()
	timetable.set_script(preload("res://scripts/timetable.gd"))
	add_child(timetable)
	timetable.position = pos
	timetable.rotation.y = atan2(-pos.x, -pos.z)
	timetable.setup(q)
	for x in range(-12, 13, 3):
		for z in [-5.0, -1.0, 3.0, 7.0, 11.0]:
			_keep(timetable.to_global(Vector3(x, 0, z)), 2.6)
	var s := _add_sweet(q, "food/cupcake", timetable.sweet_spot(), pos, 3.2)
	s.visible = false
	s.gate = func() -> bool: return timetable.done
	timetable.sweet = s


## La directora: a hedge corridor running along the coast, with the sweet in her office
## at the far end. Its middle sits at [angle, fraction] ("at" in the lesson).
func _build_headteacher(q: Dictionary) -> void:
	var mid := _at(q.get("at", [85.0, 0.8]))
	var along := Vector3(-mid.z, 0, mid.x).normalized() * -1.0     # along the coast
	headteacher = Node3D.new()
	headteacher.set_script(preload("res://scripts/headteacher.gd"))
	add_child(headteacher)
	headteacher.rotation.y = atan2(-along.x, -along.z)          # local -Z runs along the coast
	headteacher.position = mid - along * 11.0
	headteacher.setup()
	for z in range(3, -26, -2):
		for x in [-3.5, 0.0, 3.5]:
			_keep(headteacher.to_global(Vector3(x, 0, z)), 2.4)
	var s := _add_sweet(q, "food/donut-chocolate", headteacher.sweet_spot(), mid, 4.0)
	headteacher.sweet = s


## Sin señal: three antenna towers to climb; the sweet appears by the big phone in the plaza.
const TOWER_SPOTS := [Vector3(-24, 0, -16), Vector3(26, 0, 20), Vector3(8, 0, -34)]
const TOWER_HUB := Vector3(-18, 0, 16)


func _build_towers(q: Dictionary) -> void:
	towers = Node3D.new()
	towers.set_script(preload("res://scripts/signal_towers.gd"))
	add_child(towers)
	towers.setup(TOWER_SPOTS, TOWER_HUB)
	for p in TOWER_SPOTS:
		_keep(p, 4.2)
	_keep(TOWER_HUB, 4.0)
	_keep(TOWER_HUB + (-TOWER_HUB.normalized()) * 3.5, 2.5)
	var s := _add_sweet(q, "food/candy-bar", towers.sweet_spot(TOWER_HUB), TOWER_HUB, 4.0)
	s.visible = false
	s.gate = func() -> bool: return towers.done
	towers.sweet = s


## El ferry: a big ferry moored alongside a jetty that runs out from the shore at "at" degrees.
func _build_ferry(q: Dictionary) -> void:
	var ang := deg_to_rad(float(q.get("at", [80.0])[0]))
	var d := Vector3(cos(ang), 0, sin(ang))
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 26.0))
	for k in range(int(MAIN_R) - 8, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	ferry = Node3D.new()
	ferry.set_script(preload("res://scripts/ferry.gd"))
	ferry.position = d * (MAIN_R + 17.0) + side * 7.4
	ferry.rotation.y = atan2(d.x, d.z)          # bow (-Z) towards the island, bridge out to sea
	add_child(ferry)
	ferry.setup(str(q.get("model", "water/ship-cargo-a")))
	# The gangway: a ramp from the jetty up onto the deck.
	var land: Vector3 = ferry.to_global(ferry.gangway_spot())
	var from := Vector3(land.x, 0, land.z) - side * 1.9
	var to := land + Vector3(0, 0.6, 0) + side * 0.1       # just over the deck rail
	var ramp := StaticBody3D.new()
	ramp.add_to_group("solid_ground")
	add_child(ramp)
	var len := from.distance_to(to)
	ramp.position = (from + to) / 2.0
	ramp.look_at_from_position(ramp.position, to, Vector3.UP)
	var rm := BoxMesh.new()
	rm.size = Vector3(1.6, 0.15, len)
	rm.material = Props.mat(Color(0.3, 0.35, 0.45))
	var rmi := MeshInstance3D.new()
	rmi.mesh = rm
	ramp.add_child(rmi)
	var rcs := CollisionShape3D.new()
	var rsh := BoxShape3D.new()
	rsh.size = rm.size
	rcs.shape = rsh
	ramp.add_child(rcs)
	_add_sweet(q, "food/candy-bar", ferry.sweet_spot(), ferry.position, 4.0)
	for p in ferry.container_tops():
		_star(p)
	# Its blue sister ship, anchored further along the coast (just for looks).
	var blue := Props.model("water/ship-cargo-b")
	blue.scale = Vector3.ONE * 2.4
	add_child(blue)
	blue.position = d.rotated(Vector3.UP, 0.5) * (MAIN_R + 30.0) + Vector3(0, -2.0, 0)
	blue.rotation.y = atan2(d.x, d.z) + 1.2


## ¿Dónde está?: a little town in the outer ring. Its main street runs along the coast;
## "a la derecha" (local +X) is towards the sea.
func _build_town(q: Dictionary) -> void:
	var pos := _at(q.get("at", [125.0, 0.8]))
	var u := pos.normalized()
	town = Node3D.new()
	town.set_script(preload("res://scripts/town.gd"))
	town.position = pos
	town.rotation.y = atan2(-u.z, u.x)
	add_child(town)
	town.setup(q)
	town.read = func(t: String, m: String): read_panel.emit(t, m)
	for x in range(-7, 8, 2):
		for z in range(-15, 17, 2):
			_keep(town.to_global(Vector3(x, 0, z)), 1.6)
	var s := _add_sweet(q, "food/cookie", town.sweet_spot(), pos, 4.0)
	s.visible = false
	s.gate = func() -> bool: return town.done
	town.sweet = s


## El mercado: stalls, a shopping list and a till. Faces the middle of the island.
func _build_market(q: Dictionary) -> void:
	var pos := _at(q.get("at", [45.0, 0.8]))
	market = Node3D.new()
	market.set_script(preload("res://scripts/market.gd"))
	market.position = pos
	market.rotation.y = atan2(-pos.x, -pos.z)
	add_child(market)
	market.setup(q)
	for x in range(-9, 10, 2):
		for z in range(-6, 8, 2):
			_keep(market.to_global(Vector3(x, 0, z)), 1.6)
	var s := _add_sweet(q, "food/cupcake", market.sweet_spot(), pos, 3.2)
	s.visible = false
	s.gate = func() -> bool: return market.done
	market.sweet = s


## El restaurante: customers order in Spanish; one wants fish, which you catch from a rowboat
## at a fishing spot out at sea ("fishing_at": [angle of the jetty]).
func _build_restaurant(q: Dictionary) -> void:
	var pos := _at(q.get("at", [60.0, 0.76]))
	restaurant = Node3D.new()
	restaurant.set_script(preload("res://scripts/restaurant.gd"))
	restaurant.position = pos
	restaurant.rotation.y = atan2(-pos.x, -pos.z)
	add_child(restaurant)
	restaurant.setup(q)
	for x in range(-9, 10, 2):
		for z in range(-7, 8, 2):
			_keep(restaurant.to_global(Vector3(x, 0, z)), 1.6)
	var s := _add_sweet(q, "food/cake", restaurant.sweet_spot(), pos, 2.0)
	s.visible = false
	s.gate = func() -> bool: return restaurant.done
	restaurant.sweet = s
	if restaurant.needs_fish():
		_build_fishing(float(q.get("fishing_at", [100.0])[0]))


func _build_fishing(angle_deg: float) -> void:
	var a := deg_to_rad(angle_deg)
	var d := Vector3(cos(a), 0, sin(a))
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 7.0))
	for k in range(int(MAIN_R) - 6, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	var sign := Props.place(self, "sign", d * (MAIN_R - 3.5) + side * 2.4, atan2(d.x, d.z) + PI, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "¡A pescar!"
	sl.font_size = 40
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.3, 0.6)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)
	rowboat = Node3D.new()
	rowboat.set_script(preload("res://scripts/rowboat.gd"))
	add_child(rowboat)
	rowboat.global_position = d * (MAIN_R + 9.0) + side * 0.5
	rowboat.rotation.y = atan2(-d.x, -d.z)
	rowboat.setup()
	rowboat.shores = [[Vector3.ZERO, MAIN_R], [EAST_ISLAND, 5.0], [WEST_ISLAND, 5.0], [PRIZE_CENTER, 6.0]]
	for sh in rowboat.shores:
		rowboat.blockers.append([Vector2(sh[0].x, sh[0].z), sh[1] + 2.2])
	fishing = Node3D.new()
	fishing.set_script(preload("res://scripts/fishing_spot.gd"))
	add_child(fishing)
	fishing.position = d.rotated(Vector3.UP, -0.25) * (MAIN_R + 36.0)
	fishing.setup()
	fishing.rowboat = rowboat
	fishing.on_catch = func(): restaurant.carry("fish", "food/fish", 2.6)
	fishing.active = func() -> bool: return not restaurant.done and restaurant.carrying != "fish" and not restaurant.fish_served()
	# A few rocks on the way, and stars to row through.
	for i in 2:
		var t := 0.3 + i * 0.25
		var mid: Vector3 = rowboat.global_position.lerp(fishing.position, t)
		var off := side * (8.5 if i % 2 == 0 else -8.5)
		Props.place(self, "pirate/rocks-a" if i % 2 == 0 else "pirate/rocks-b", mid + off + Vector3(0, -1.6, 0), _rng.randf() * TAU, 1.3, "")
		rowboat.blockers.append([Vector2(mid.x + off.x, mid.z + off.z), 2.6])
		_star(mid - off * 0.3 + Vector3(0, 0.6, 0))


## La Tomatina: a walled street running along the coast; the sweet is in the plaza at the end.
func _build_tomatina(q: Dictionary) -> void:
	var mid := _at(q.get("at", [215.0, 0.8]))
	var along := Vector3(-mid.z, 0, mid.x).normalized() * -1.0
	tomatina = Node3D.new()
	tomatina.set_script(preload("res://scripts/tomatina.gd"))
	tomatina.rotation.y = atan2(-along.x, -along.z)          # local -Z runs along the coast
	tomatina.position = mid - along * 16.0
	add_child(tomatina)
	tomatina.setup()
	for z in range(3, -36, -2):
		for x in [-5.5, -2.5, 0.0, 2.5, 5.5]:
			_keep(tomatina.to_global(Vector3(x, 0, z)), 1.8)
	var s := _add_sweet(q, "food/watermelon", tomatina.sweet_spot(), mid, 2.2)
	tomatina.sweet = s


## La piñata: jump on it three times.
func _build_pinata(q: Dictionary) -> void:
	var pos := _at(q.get("at", [300.0, 0.66]))
	pinata = Node3D.new()
	pinata.set_script(preload("res://scripts/pinata.gd"))
	pinata.position = pos
	pinata.rotation.y = atan2(-pos.x, -pos.z)
	add_child(pinata)
	pinata.setup()
	_keep(pos, 8.0)
	var s := _add_sweet(q, "food/lollypop", pinata.sweet_spot(), pos, 4.0)
	s.visible = false
	s.gate = func() -> bool: return pinata.done
	pinata.sweet = s


## La cinta transportadora: send each thing to the right job.
func _build_sorter(q: Dictionary) -> void:
	var pos := _at(q.get("at", [60.0, 0.76]))
	sorter = Node3D.new()
	sorter.set_script(preload("res://scripts/sorter.gd"))
	sorter.position = pos
	sorter.rotation.y = atan2(-pos.x, -pos.z)
	add_child(sorter)
	sorter.setup(q)
	for x in range(-10, 11, 2):
		for z in range(-4, 9, 2):
			_keep(sorter.to_global(Vector3(x, 0, z)), 1.6)
	var s := _add_sweet(q, "food/donut-chocolate", sorter.sweet_spot(), pos, 4.0)
	s.visible = false
	s.gate = func() -> bool: return sorter.done
	sorter.sweet = s


## La grúa: ride a container up to the top of a stack. Side-on to the middle of the island.
func _build_crane(q: Dictionary) -> void:
	var pos := _at(q.get("at", [215.0, 0.78]))
	crane = Node3D.new()
	crane.set_script(preload("res://scripts/crane.gd"))
	crane.position = pos
	crane.rotation.y = atan2(-pos.x, -pos.z)
	add_child(crane)
	crane.setup()
	for x in range(-6, 7, 2):
		for z in range(-5, 6, 2):
			_keep(crane.to_global(Vector3(x, 0, z)), 1.6)
	_add_sweet(q, "food/cupcake", crane.sweet_spot(), pos, 3.2)
	# Stars up the ride.
	for y in [4.0, 7.0]:
		_star(crane.to_global(Vector3(0, y + 1.2, 0)))


## El volcán: cools as you finish retos; climb to the crater for the sweet.
func _build_volcano(q: Dictionary) -> void:
	var pos := _at(q.get("at", [150.0, 0.72]))
	volcano = Node3D.new()
	volcano.set_script(preload("res://scripts/volcano.gd"))
	volcano.position = pos
	add_child(volcano)
	volcano.setup(int(q.get("need", 3)))
	_keep(pos, 14.0)
	_nostar.append([Vector2(pos.x, pos.z), 13.5])
	_add_sweet(q, "food/popsicle", volcano.sweet_spot(), pos, 4.5)


## Reforestación: plant young trees from the nursery in a burnt patch.
func _build_reforest(q: Dictionary) -> void:
	var pos := _at(q.get("at", [300.0, 0.7]))
	reforest = Node3D.new()
	reforest.set_script(preload("res://scripts/reforest.gd"))
	reforest.position = pos
	reforest.rotation.y = atan2(-pos.x, -pos.z)
	add_child(reforest)
	reforest.setup()
	_keep(pos, 8.0)
	_keep(pos + (-pos.normalized()) * 5.5, 3.0)
	_nostar.append([Vector2(pos.x, pos.z), 7.0])
	var s := _add_sweet(q, "food/watermelon", reforest.sweet_spot(), pos, 2.2)
	s.visible = false
	s.gate = func() -> bool: return reforest.done
	reforest.sweet = s


## El crucero: an ocean liner anchored far out at sea. A little solar boat at a jetty takes you
## to a pontoon beside it; a gangway leads up to its decks, and the sweet is on the top deck.
func _build_liner(q: Dictionary) -> void:
	var a := deg_to_rad(float(q.get("at", [60.0])[0]))
	var d := Vector3(cos(a), 0, sin(a))
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 7.0))
	for k in range(int(MAIN_R) - 6, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	var sign := Props.place(self, "sign", d * (MAIN_R - 3.5) + side * 2.4, atan2(d.x, d.z) + PI, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "Al crucero"
	sl.font_size = 38
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.3, 0.6)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)
	# The liner: side-on to the island, its local +X towards the island.
	liner = Node3D.new()
	add_child(liner)
	liner.position = d * (MAIN_R + 40.0)
	liner.rotation.y = atan2(d.z, -d.x)
	var m := Props.model("water/ship-ocean-liner")
	m.scale = Vector3.ONE * 2.0
	m.position.y = -3.0
	liner.add_child(m)
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	liner.add_child(body)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var cs := CollisionShape3D.new()
		cs.shape = (mi as MeshInstance3D).mesh.create_trimesh_shape()
		cs.transform = m.transform * (mi as MeshInstance3D).transform
		body.add_child(cs)
	# A floating pontoon beside it and a gangway along the hull up to the promenade deck.
	var wood := Props.mat(Color(0.7, 0.5, 0.32))
	var pont_c := Vector3(13.2, -0.1, -2.0)
	_liner_box(body, Vector3(4.6, 0.4, 5.0), pont_c, wood)
	var from := Vector3(10.9, 0.05, -2.0)
	var to := Vector3(4.1, 4.75, -2.0)         # square-on to the hull, onto the promenade deck
	var ramp := StaticBody3D.new()
	ramp.add_to_group("solid_ground")
	liner.add_child(ramp)
	ramp.position = (from + to) / 2.0
	ramp.basis = Basis.looking_at(to - from, Vector3.UP)     # (local to the liner)
	var rm := BoxMesh.new()
	rm.size = Vector3(2.0, 0.15, from.distance_to(to) + 0.4)
	rm.material = Props.mat(Color(0.3, 0.35, 0.45))
	var rmi := MeshInstance3D.new()
	rmi.mesh = rm
	ramp.add_child(rmi)
	var rcs := CollisionShape3D.new()
	var rsh := BoxShape3D.new()
	rsh.size = rm.size
	rcs.shape = rsh
	ramp.add_child(rcs)
	var tag := Label3D.new()
	tag.text = "El Crucero Verde"
	tag.font = preload("res://scripts/ui.gd").ui_font(700)
	tag.font_size = 130
	tag.pixel_size = 0.01
	tag.outline_size = 20
	tag.modulate = Color(0.6, 1.0, 0.6)
	tag.outline_modulate = Color(0.1, 0.25, 0.2)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 16.0, 0)
	liner.add_child(tag)
	# A landing at the top of the gangway, joined to the promenade.
	_liner_box(body, Vector3(1.4, 0.2, 2.6), Vector3(4.1, 4.62, -2.0), Props.mat(Color(0.3, 0.35, 0.45)))
	_add_sweet(q, "food/cake", liner.to_global(Vector3(1.5, 9.4, 0.0)), liner.position, 1.8)
	# The solar boat.
	liner_boat = Node3D.new()
	liner_boat.set_script(preload("res://scripts/rowboat.gd"))
	add_child(liner_boat)
	liner_boat.global_position = d * (MAIN_R + 9.5) + side * 0.4
	liner_boat.rotation.y = atan2(-d.x, -d.z)
	liner_boat.boat_name = "speedboat"
	liner_boat.seat_offset = Vector3(0, 0.75, 0.9)
	liner_boat.DRAG = 5.0
	liner_boat.setup("water/boat-speed-c", 2.2, PI, 11.0, 6.0)
	liner_boat.add_wake()
	var pont := liner.to_global(pont_c)
	liner_boat.shores = [[Vector3.ZERO, MAIN_R], [EAST_ISLAND, 5.0], [WEST_ISLAND, 5.0], [PRIZE_CENTER, 6.0],
		[Vector3(pont.x, 0.0, pont.z), 2.5, pont + Vector3(0, 0.5, 0)]]
	for i in 4:
		var sh = liner_boat.shores[i]
		liner_boat.blockers.append([Vector2(sh[0].x, sh[0].z), sh[1] + 2.2])
	liner_boat.rects = _jetty_rects.duplicate()
	liner_boat.rects.append([Vector2(liner.position.x, liner.position.z), Vector2(4.8, 21.3), liner.rotation.y])
	liner_boat.rects.append([Vector2(pont.x, pont.z), Vector2(2.3, 2.5), liner.rotation.y])


func _liner_box(body: StaticBody3D, size: Vector3, pos: Vector3, m: Material) -> void:
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


## El remolcador: a tug at a jetty, a container ship waiting far out at sea, and a berth by a
## quay behind the crane ("berth_at": [angle]). Tow the ship in for the sweet.
func _build_tug(q: Dictionary) -> void:
	var ja := deg_to_rad(float(q.get("at", [232.0])[0]))
	var d := Vector3(cos(ja), 0, sin(ja))
	var side := Vector3(-d.z, 0, d.x)
	_jetty(d * (MAIN_R - 2.0), d * (MAIN_R + 7.0))
	for k in range(int(MAIN_R) - 6, int(MAIN_R) + 1, 2):
		_keep(d * k, 2.6)
	var sign := Props.place(self, "sign", d * (MAIN_R - 3.5) + side * 2.4, atan2(d.x, d.z) + PI, 2.5, "box")
	var sl := Label3D.new()
	sl.text = "El remolcador"
	sl.font_size = 34
	sl.pixel_size = 0.005
	sl.modulate = Color(0.2, 0.4, 0.3)
	sl.position = Vector3(0, 1.1, 0.22)
	sign.add_child(sl)
	tug = Node3D.new()
	tug.set_script(preload("res://scripts/rowboat.gd"))
	add_child(tug)
	tug.global_position = d * (MAIN_R + 9.5) + side * 0.4
	tug.rotation.y = atan2(-d.x, -d.z)
	tug.boat_name = "tug"
	tug.seat_offset = Vector3(0, 1.0, 1.6)
	tug.DRAG = 3.0
	tug.setup("water/boat-tug-b", 2.4, PI, 9.0, 4.0)
	tug.add_wake()
	tug.shores = [[Vector3.ZERO, MAIN_R], [EAST_ISLAND, 5.0], [WEST_ISLAND, 5.0], [PRIZE_CENTER, 6.0]]
	for sh in tug.shores:
		tug.blockers.append([Vector2(sh[0].x, sh[0].z), sh[1] + 2.2])
	# The quay and the berth behind the crane.
	var ba := deg_to_rad(float(q.get("berth_at", [212.0])[0]))
	var bd := Vector3(cos(ba), 0, sin(ba))
	var bside := Vector3(-bd.z, 0, bd.x)
	_jetty(bd * (MAIN_R - 2.0) - bside * 11.0, bd * (MAIN_R + 12.0) - bside * 11.0)
	var berth := bd * (MAIN_R + 10.0)
	# The ship, far out to sea.
	var sa := deg_to_rad(float(q.get("ship_at", [246.0])[0]))
	var ship_pos := Vector3(cos(sa), 0, sin(sa)) * (MAIN_R + 42.0)
	towing = Node3D.new()
	towing.set_script(preload("res://scripts/tow.gd"))
	add_child(towing)
	towing.setup(ship_pos, sa + PI / 2, berth, MAIN_R)
	towing.tug = tug
	# The tug bumps into the jetties and the ship (but sails through the buoys).
	tug.rects = _jetty_rects.duplicate()
	tug.dynamic_rects = func() -> Array: return [towing.ship_rect()]
	towing.quay = _jetty_rects[_jetty_rects.size() - 1]
	var s := _add_sweet(q, "food/candy-bar", bd * (MAIN_R + 11.0) - bside * 11.0 + Vector3(0, 0.6, 0), berth, 4.0)
	s.visible = false
	s.gate = func() -> bool: return towing.done
	towing.sweet = s


## La entrevista: the boss's office, with the sweet on the desk. The interview itself is a run
## of sentence-builder questions (see main._on_sweet).
func _build_office(q: Dictionary) -> void:
	var pos := _at(q.get("at", [300.0, 0.7]))
	var face := atan2(-pos.x, -pos.z)
	office = Node3D.new()
	office.set_script(preload("res://scripts/quest_stall.gd"))
	office.position = pos
	office.rotation.y = face
	add_child(office)
	office.setup({"sign": str(q.get("sign", "Oficina de empleo")), "character": str(q.get("character", "character-female-f")), "hat": "",
		"speaker": "La jefa", "greeting": "Buenos días. ¿Buscas trabajo?\n¡Ven a la entrevista!", "thanks": "", "awning": Color(0.3, 0.45, 0.75),
		"counter": [["furniture/books", 8.0, -1.6]], "items": [], "passive": true})
	_keep(pos, 5.0)
	_keep(pos + Vector3(-pos.x, 0, -pos.z).normalized() * 4.0, 2.5)
	# The cookie stays hidden until you get the job (a cookie on the desk makes it look like a
	# bakery); walking up to the desk starts the interview.
	var s := _add_sweet(q, "food/cookie", office.to_global(Vector3(0.0, 0.75, 1.55)), pos, 4.0)
	s.visible = false


## A sweet tucked away somewhere quiet ("at": [angle, fraction]) - e.g. a message in a bottle
## on a far beach, under a parasol. No mechanics: the fun is in finding it.
func _build_hidden(q: Dictionary) -> void:
	var pos := _at(q.get("at", [250.0, 0.92]))
	var face := atan2(-pos.x, -pos.z)
	var towel := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.2, 0.04, 2.0)
	tm.material = Props.mat(Color(1.0, 0.55, 0.3))
	towel.mesh = tm
	add_child(towel)
	towel.position = pos + Vector3(0, 0.02, 0)
	towel.rotation.y = face
	Props.place(self, "city/detail-parasol-a", pos + Vector3(0.9, 0, -0.6).rotated(Vector3.UP, face), face, 6.0, "cyl")
	var bottle := Props.model("survival/bottle")
	bottle.scale = Vector3.ONE * 5.0
	add_child(bottle)
	bottle.position = pos + Vector3(-0.8, 0.12, 0.6).rotated(Vector3.UP, face)
	bottle.rotation = Vector3(0, face, PI / 2)
	_keep(pos, 3.0)
	_add_sweet(q, str(q.get("model", "food/popsicle")), pos + Vector3(0, 0.9, 0), pos, float(q.get("scale", 4.5)))


## El escenario: the festival stage with dance pads. Faces the middle of the island.
func _build_stage(q: Dictionary) -> void:
	var pos := _at(q.get("at", [90.0, 0.8]))
	stage = Node3D.new()
	stage.set_script(preload("res://scripts/rhythm_stage.gd"))
	add_child(stage)
	stage.position = pos
	stage.rotation.y = atan2(-pos.x, -pos.z)
	stage.setup(q)
	for x in range(-8, 9, 2):
		for z in [-6.0, -3.0, 0.0, 3.0, 6.0, 9.0, 12.0]:
			_keep(stage.to_global(Vector3(x, 0, z)), 1.8)
	var s := _add_sweet(q, "food/lollypop", stage.sweet_spot(), pos, 4.0)
	s.visible = false
	s.gate = func() -> bool: return stage.done
	stage.sweet = s


## La noria: a Ferris wheel side-on to the middle of the island; the sweet is on the lookout.
func _build_noria(q: Dictionary) -> void:
	var pos := _at(q.get("at", [225.0, 0.73]))
	noria = Node3D.new()
	noria.set_script(preload("res://scripts/ferris_wheel.gd"))
	add_child(noria)
	noria.position = pos
	# The wheel turns in its local XY plane; local +Z (the side you get on) faces the middle.
	noria.rotation.y = atan2(-pos.x, -pos.z)
	noria.setup()
	for x in range(-10, 11, 2):
		for z in [-5.0, -2.5, 0.0, 2.5]:
			_keep(noria.to_global(Vector3(x, 0, z)), 1.8)
	_add_sweet(q, "food/cupcake", noria.sweet_spot(), pos, 3.2)


## El circuito: a timed obstacle course running out over the sea from the far shore.
func _build_circuit(q: Dictionary) -> void:
	circuit = Node3D.new()
	circuit.set_script(preload("res://scripts/circuit.gd"))
	add_child(circuit)
	circuit.position = CIRCUIT_DIR * (MAIN_R - 4.0)
	circuit.rotation.y = atan2(-CIRCUIT_DIR.z, CIRCUIT_DIR.x)    # local +X points along CIRCUIT_DIR
	circuit.setup()
	for k in range(0, 8):
		_keep(CIRCUIT_DIR * (MAIN_R - 4.0 + k), 3.5)
	var s := _add_sweet(q, "food/lollypop", circuit.sweet_spot(), circuit.position, 4.0)
	s.visible = false
	s.gate = func() -> bool: return circuit.done
	circuit.sweet = s
	# A few stars along the course for the brave.
	for x in [9.0, 17.0, 26.0, 32.8]:
		_star(circuit.to_global(Vector3(x, 1.4 if x < 30 else 3.2, 0)))


func _jetty(from: Vector3, to: Vector3) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	var length := from.distance_to(to)
	body.position = (from + to) / 2.0
	body.rotation.y = atan2(to.x - from.x, to.z - from.z)
	_jetty_rects.append([Vector2(body.position.x, body.position.z), Vector2(1.5, length / 2.0), body.rotation.y])
	var deck := BoxMesh.new()
	deck.size = Vector3(3.0, 0.3, length)
	deck.material = Props.mat(Color(0.7, 0.48, 0.32))
	var dmi := MeshInstance3D.new()
	dmi.mesh = deck
	dmi.position.y = -0.15
	body.add_child(dmi)
	var dcs := CollisionShape3D.new()
	var dsh := BoxShape3D.new()
	dsh.size = deck.size
	dcs.shape = dsh
	dcs.position.y = -0.15
	body.add_child(dcs)
	var post_mat := Props.mat(Color(0.5, 0.33, 0.22))
	for i in int(length / 3.0) + 1:
		for sx in [-1.5, 1.5]:
			var post := CylinderMesh.new()
			post.top_radius = 0.16
			post.bottom_radius = 0.16
			post.height = 2.6
			post.material = post_mat
			var pm := MeshInstance3D.new()
			pm.mesh = post
			pm.position = Vector3(sx, -0.9, -length / 2.0 + i * 3.0)
			body.add_child(pm)


## A character's market stall; their three lost things are hidden around the island.
func _build_quest(q: Dictionary, quest: Dictionary) -> void:
	cafe = Node3D.new()
	cafe.set_script(preload("res://scripts/quest_stall.gd"))
	add_child(cafe)
	cafe.position = CAFE
	var to_centre := -CAFE.normalized()
	cafe.rotation.y = atan2(to_centre.x, to_centre.z)
	cafe.setup(quest)
	_keep(CAFE, 5.0)
	_keep(CAFE + to_centre * 4.0, 2.5)
	# The reward sits at the front corner of the counter (so it doesn't hide the character).
	var s := _add_sweet(q, quest.reward, cafe.to_global(quest.get("reward_pos", Vector3(1.3, 0.75, 1.55))), CAFE, float(quest.get("reward_scale", 3.2)))
	if quest.get("reward_hidden", false):
		s.visible = false     # appears on the counter once everything has been brought back
	if quest.has("floor_props"):
		for fp in quest.floor_props:     # [model, scale, local position, y rotation]
			if fp[0] == "skate/skateboard":
				skateboard = AnimatableBody3D.new()
				skateboard.set_script(preload("res://scripts/skateboard.gd"))
				# Place it before it enters the tree: an AnimatableBody3D (sync_to_physics) ignores
				# a global_position set straight after add_child, and would sit at the origin.
				skateboard.position = to_local(cafe.to_global(fp[2]))
				skateboard.rotation.y = cafe.rotation.y + fp[3]
				add_child(skateboard)
				skateboard.setup(fp[1])
				skateboard.park_here()
				skateboard.island_r = MAIN_R - 1.5
				continue
			var d := Props.model(fp[0])
			d.scale = Vector3.ONE * fp[1]
			cafe.add_child(d)
			d.position = fp[2]
			d.rotation.y = fp[3]
	s.gate = cafe.has_everything
	cafe.sweet = s
	for item in quest.items:
		var ing := Area3D.new()
		ing.set_script(preload("res://scripts/ingredient.gd"))
		add_child(ing)
		ing.position = ex(item[3])
		ing.setup(item[0], item[1], item[2])
		_keep(ing.position, 1.2)
	Game.ingredients_total = quest.items.size()


## "Comida sana": collect healthy food in a fenced field while dodging bouncing junk food.
func _build_healthy_field(q: Dictionary) -> void:
	var field := Node3D.new()
	healthy_field = field
	field.set_script(preload("res://scripts/healthy_field.gd"))
	add_child(field)
	field.position = HEALTHY_FIELD
	var s := _add_sweet(q, "food/watermelon", HEALTHY_FIELD + Vector3(0, 1.2, 0), HEALTHY_FIELD, 2.2)
	field.setup(s)
	_pillar(HEALTHY_FIELD, 1.0, 1.2)
	_keep(HEALTHY_FIELD, field.RADIUS + 1.5)


# ---------------------------------------------------------------- building blocks

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = theme.sky
	sm.sky_horizon_color = theme.horizon
	sm.ground_horizon_color = theme.horizon
	sm.ground_bottom_color = Color(0.4, 0.7, 0.95)
	sm.sun_angle_max = 20
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.fog_enabled = true
	env.fog_light_color = theme.horizon
	env.fog_density = 0.002
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-52), deg_to_rad(35), 0)
	sun.light_color = theme.get("sun", Color(1.0, 0.96, 0.88))     # a theme can have an evening glow
	sun.light_energy = float(theme.get("sun_energy", 1.0))
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 600)
	plane.subdivide_width = 96
	plane.subdivide_depth = 96
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/sea.gdshader")
	m.set_shader_parameter("deep", theme.deep)
	m.set_shader_parameter("shallow", theme.shallow)
	plane.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position.y = -1.3
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Round grassy island with cliffs, a sandy beach and a foam ring.
func _island(center: Vector3, r: float, seg := 48) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	body.position = center
	_cyl(body, r + 0.25, r + 0.25, 0.6, -0.3, _grass, seg)
	_cyl(body, r, r * 0.85, 6.0, -3.4, _dirt, seg)
	_cyl(body, r + 1.6, r + 2.2, 0.8, -1.55, _sand, seg, false)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r + 0.25
	shape.height = 8.0
	cs.shape = shape
	cs.position.y = -4.0
	body.add_child(cs)
	# Beach is walkable too (in case you fall off the edge you can jump back up).
	var bcs := CollisionShape3D.new()
	var bshape := CylinderShape3D.new()
	bshape.radius = r + 2.0
	bshape.height = 1.0
	bcs.shape = bshape
	bcs.position.y = -1.65
	body.add_child(bcs)
	_foam_ring(center, r + 2.3, seg)


## A round grassy pillar/hill rising from the ground (or the sea).
func _pillar(pos: Vector3, r: float, top: float, depth := 1.0) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	body.position = Vector3(pos.x, 0, pos.z)
	var h := top + depth
	_cyl(body, r + 0.15, r + 0.15, 0.4, top - 0.2, _grass, 32)
	_cyl(body, r, r * 0.95, h - 0.3, top - 0.3 - (h - 0.3) / 2.0, _dirt, 32)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r + 0.15
	shape.height = h
	cs.shape = shape
	cs.position.y = top - h / 2.0
	body.add_child(cs)
	if depth > 2.0:
		_foam_ring(Vector3(pos.x, 0, pos.z), r + 0.4)


## A little floating island (grass top, rounded dirt underside). `top` is the walkable height.
func _floating_islet(top: Vector3, r: float) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("solid_ground")
	add_child(body)
	body.position = top
	_cyl(body, r + 0.15, r + 0.15, 0.35, -0.175, _grass, 24)
	_cyl(body, r, 0.25, 1.2, -0.95, _dirt, 24)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r + 0.15
	shape.height = 0.6
	cs.shape = shape
	cs.position.y = -0.3
	body.add_child(cs)


func _cyl(parent: Node3D, top_r: float, bottom_r: float, h: float, y: float, m: Material, seg := 32, shadow := true) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	c.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position.y = y
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _foam_ring(center: Vector3, r: float, seg := 48) -> void:
	var t := TorusMesh.new()
	t.inner_radius = r
	t.outer_radius = r + 0.5
	t.rings = seg
	t.ring_segments = 6
	t.material = _foam
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.position = center + Vector3(0, -1.28, 0)
	mi.scale.y = 0.1
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _keep(p: Vector3, r: float) -> void:
	_keepout.append([Vector2(p.x, p.z), r])


func _is_free(p: Vector2, r: float) -> bool:
	for k in _keepout:
		if p.distance_to(k[0]) < k[1] + r:
			return false
	return true


func _star(p: Vector3) -> void:
	var s := Area3D.new()
	s.set_script(preload("res://scripts/star_pickup.gd"))
	s.position = p
	add_child(s)
	Game.total_stars += 1


func _stars() -> void:
	var pts := [
		# Trail from the start
		Vector3(-2, 0.5, 9), Vector3(-4.5, 0.5, 7), Vector3(-7.5, 0.5, 5), Vector3(-10.5, 0.5, 3.5),
		# Up the plateau steps
		Vector3(-17.5, 1.1, 1.6), Vector3(-16.2, 1.7, 0.3), Vector3(-17.5, 2.3, -5.5), Vector3(-14.5, 2.3, -5),
		# Above the spring - grab them on the way up!
		Vector3(12.8, 2.6, -5.2), Vector3(12.8, 4.4, -5.2), Vector3(16, 5.6, -6.4),
		# Floating islet path
		Vector3(14, 2.1, 15), Vector3(17.2, 3.2, 16), Vector3(20.5, 4.3, 12.4), Vector3(20, 5.0, 8),
		# Stepping stones and east island
		Vector3(30.8, 0.8, 8), Vector3(32.9, 0.8, 8), Vector3(42.5, 0.5, 6), Vector3(38.5, 0.5, 11),
		# Moving platform and west island
		Vector3(-30, 1.4, 14), Vector3(-33, 1.4, 14), Vector3(-41, 0.5, 16.5),
		# Behind the whiteboard and the mounds
		Vector3(0, 0.5, -6.5), Vector3(-2, 0.5, -7.5), Vector3(2, 0.5, -7.5), Vector3(6, 1.2, -12),
		Vector3(24, 1.1, -4), Vector3(-24, 1.4, -9), Vector3(-8, 1.1, 22),
		# Little hill
		Vector3(-10, 1.6, -19.8), Vector3(-12, 0.5, -15),
		# Near the sweet shop and the ghost garden (brave players only!)
		Vector3(10, 0.5, -17), Vector3(12, 0.5, -24), Vector3(-12, 0.5, 18), Vector3(-15, 0.5, 11),
		# Around the island
		Vector3(0, 0.5, 26), Vector3(14, 0.5, 22), Vector3(26, 0.5, 12), Vector3(27, 0.5, -10),
		Vector3(-27, 0.5, 8), Vector3(-26, 0.5, -14), Vector3(-4, 0.5, -26), Vector3(4, 0.5, -26),
	]
	for p in pts:
		var e := ex(p)
		var blocked := false
		for z in _nostar:
			if Vector2(e.x, e.z).distance_to(z[0]) < z[1]:
				blocked = true
		if not blocked:
			_star(e)
	# Star Island bonus
	_star(Vector3(-3.2, 0.5, PRIZE_CENTER.z + 2))
	_star(Vector3(3.2, 0.5, PRIZE_CENTER.z + 2))
	# A bigger island gets a ring of extra stars in the new outer land.
	if D > 0:
		for i in 12:
			var a := TAU * (i + 0.5) / 12.0
			var sp := Vector3(cos(a), 0, sin(a)) * (MAIN_R - D * 0.45)
			if _is_free(Vector2(sp.x, sp.z), 0.6):
				_star(sp + Vector3(0, 0.5, 0))


func _decorate() -> void:
	# More land = more trees and flowers (area grows with the square of the size).
	var dens := clampf(pow(MAIN_R / BASE_R, 2.0) * 0.7, 1.0, 1.8)
	var tscale := float(theme.get("tree_scale", 1.0))
	# Keep the camera's view clear at the start (it sits behind the player, towards +Z) -
	# a big tree there fills the screen with green and looks like the game is broken.
	_keep(SPAWN + Vector3(0, 0, 4.5), 3.0 + 1.5 * tscale)
	# Trees, thickest towards the edge of the island
	for i in int(120 * dens):
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(8.0, MAIN_R - 1.2) if i % 3 == 0 else _rng.randf_range(20.0, MAIN_R - 1.2)
		var p := Vector2(cos(a), sin(a)) * d
		if not _is_free(p, 1.3):
			continue
		_keep(Vector3(p.x, 0, p.y), 1.3)
		var kind: String = theme.trees[_rng.randi() % theme.trees.size()]
		Props.place(self, kind, Vector3(p.x, 0, p.y), _rng.randf() * TAU, _rng.randf_range(1.8, 2.6) * tscale, "trunk")
	# Small islands get a few trees each
	for c in [EAST_ISLAND, WEST_ISLAND, PRIZE_CENTER]:
		for j in 4:
			var a := _rng.randf() * TAU
			var p := Vector3(c.x + cos(a) * 3.8, 0, c.z + sin(a) * 3.8)
			if _is_free(Vector2(p.x, p.z), 1.2):
				_keep(p, 1.2)
				Props.place(self, theme.trees[0], p, _rng.randf() * TAU, 1.8 * tscale, "trunk")
	# Flowers, mushrooms, rocks, grass tufts everywhere
	var smalls := ["flowers", "flowers-tall", "flowers", "mushrooms", "grass", "grass", "plant", "rocks", "stones"]
	for i in int(320 * dens):
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * (MAIN_R - 0.8)
		var p := Vector2(cos(a), sin(a)) * d
		if not _is_free(p, 0.4):
			continue
		var kind: String = smalls[_rng.randi() % smalls.size()]
		var col := "cyl" if kind == "rocks" else ""
		Props.place(self, kind, Vector3(p.x, 0, p.y), _rng.randf() * TAU, _rng.randf_range(1.6, 2.2), col)
	# Theme extras, e.g. beach parasols on a holiday island: [model, scale, how many, (collision)]
	for ex_prop in theme.get("props", []):
		for i in int(ex_prop[2]):
			var a := _rng.randf() * TAU
			var d := _rng.randf_range(MAIN_R * 0.35, MAIN_R - 2.0)
			var p := Vector2(cos(a), sin(a)) * d
			if not _is_free(p, 1.5):
				continue
			_keep(Vector3(p.x, 0, p.y), 1.5)
			Props.place(self, ex_prop[0], Vector3(p.x, 0, p.y), _rng.randf() * TAU, ex_prop[1], str(ex_prop[3]) if ex_prop.size() > 3 else "cyl")
	# A few props near the start to bump into
	Props.place(self, "barrel", Vector3(3.5, 0, 13), 0.3, 2.0, "cyl")
	Props.place(self, "crate", Vector3(4.6, 0, 12.2), 0.2, 2.0, "box")
	Props.place(self, "crate", Vector3(4.2, 1.0, 12.6), 0.9, 2.0, "box")


func _make_clouds() -> void:
	var m := Props.mat(Color(1, 1, 1))
	m.emission_enabled = true
	m.emission = Color(0.9, 0.93, 1.0)
	m.emission_energy_multiplier = 0.35
	for i in 20:
		var cloud := Node3D.new()
		var n := _rng.randi_range(3, 5)
		for j in n:
			var s := SphereMesh.new()
			var r := _rng.randf_range(1.6, 3.0)
			s.radius = r
			s.height = r * 1.6
			s.radial_segments = 16
			s.rings = 8
			s.material = m
			var mi := MeshInstance3D.new()
			mi.mesh = s
			mi.position = Vector3(j * 2.2 - n, _rng.randf_range(-0.4, 0.6), _rng.randf_range(-1, 1))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(mi)
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(40, 100)
		cloud.position = Vector3(cos(a) * d, _rng.randf_range(16, 30), sin(a) * d)
		add_child(cloud)
		_clouds.append(cloud)
