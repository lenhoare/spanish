extends CanvasLayer
## All 2D interface: title screen, island picker, HUD, lesson reader, question cards, results.

signal play_pressed
signal character_picked(name: String)
signal island_picked(index: int)
signal menu_pressed
signal _question_done(result: String)
signal _lesson_closed
signal _results_done(choice: String)
signal games_pressed
signal _chooser_done(id: String)
signal _panel_done(result: String)

const PINK := Color("#f0508c")
const PURPLE := Color("#7c6cf0")
const PURPLE_DARK := Color("#4b3aa8")
const GREEN := Color("#3cc47c")
const ORANGE := Color("#ff9a3c")
const CREAM := Color("#fffaf0")
const INK := Color("#2d2a4a")
const CHOICE_COLORS := [Color("#ff6f91"), Color("#4fa3ff"), Color("#ffb43c"), Color("#3cc47c")]
const ACCENT_KEYS := ["á", "é", "í", "ó", "ú", "ñ", "ü", "¿", "¡"]

var root: Control
var touch: Control
var _hud: Control
var _star_label: Label
var _coin_label: Label
var _card_label: Label
var _sweet_label: Label
var _ingredient_label: Label
var _retos_label: Label
var _key_pill: Control
var _timer_label: Label
var _toast_box: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _title_font: Font
var _bold_font: Font
var _title: Control
var _picker: Control
var _rotate_hint: ColorRect
var _asking := false          # a phone text box is open (web_ask)
var _typing := false          # the phone keyboard is typing into a question card
var _page_turn := Callable()   # set while the lesson viewer is open (arrow keys turn pages)


## DynaPuff at a given weight (a variable font: 400 regular - 700 bold).
static func ui_font(weight: int) -> Font:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/dynapuff.ttf")
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


func _process(_delta: float) -> void:
	# The game is designed for landscape; nudge phone players to rotate.
	_rotate_hint.visible = Game.is_touch() and root.size.y > root.size.x


func _unhandled_input(event: InputEvent) -> void:
	if _page_turn.is_valid() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_RIGHT, KEY_D, KEY_PAGEDOWN]:
			_page_turn.call(1)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_LEFT, KEY_A, KEY_PAGEUP]:
			_page_turn.call(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_lesson_closed.emit()
			get_viewport().set_input_as_handled()


func _ready() -> void:
	layer = 10
	add_to_group("hud")
	# DynaPuff: puffy, friendly and has every Spanish accent (Kenney's fonts don't).
	_title_font = ui_font(700)
	_bold_font = ui_font(600)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)

	touch = Control.new()
	touch.set_script(preload("res://scripts/touch_controls.gd"))
	touch.visible = false
	root.add_child(touch)
	touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_rotate_hint = ColorRect.new()
	_rotate_hint.color = Color("#6a5acd")
	_rotate_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_rotate_hint.visible = false
	var rl := Label.new()
	rl.text = "Please turn your phone sideways!"
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rl.add_theme_font_override("font", _bold_font)
	rl.add_theme_font_size_override("font_size", 90)
	rl.add_theme_color_override("font_color", Color.WHITE)
	_rotate_hint.add_child(rl)
	add_child(_rotate_hint)
	_rotate_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	Game.stars_changed.connect(_refresh)
	Game.coins_changed.connect(_refresh)
	Game.cards_changed.connect(_refresh)
	Game.sweets_changed.connect(_refresh)
	Game.key_changed.connect(_refresh)
	Game.ingredients_changed.connect(_refresh)
	Game.retos_changed.connect(_refresh)
	Game.toast.connect(show_toast)


# ------------------------------------------------------------------ title screen

func show_title() -> void:
	var cfg := Game.config
	var panel := _panel(CREAM, PURPLE, 26)
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 30
	panel.offset_top = 30
	panel.offset_bottom = -30
	panel.offset_right = 30 + 540
	root.add_child(panel)
	_title = panel

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	if Game.games.size() > 1 and not Game.game_locked:
		var back := _button("< Juegos", Color("#9a94b8"))
		back.add_theme_font_size_override("font_size", 20)
		back.custom_minimum_size.y = 44
		back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back.pressed.connect(func():
			Game.sfx("click")
			games_pressed.emit())
		v.add_child(back)

	var t := Label.new()
	t.text = str(cfg.game_title)
	t.add_theme_font_override("font", _title_font)
	t.add_theme_font_size_override("font_size", 52 if t.text.length() <= 14 else maxi(30, int(52.0 * 14 / t.text.length())))
	t.add_theme_color_override("font_color", PINK)
	t.add_theme_color_override("font_outline_color", Color.WHITE)
	t.add_theme_constant_override("outline_size", 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	if str(cfg.get("tagline", "")) != "":
		var sub := Label.new()
		sub.text = str(cfg.tagline)
		sub.add_theme_font_override("font", _bold_font)
		sub.add_theme_font_size_override("font_size", 30)
		sub.add_theme_color_override("font_color", PURPLE_DARK)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)

	var intro := Label.new()
	intro.text = str(cfg.get("intro", "Explore the islands and collect the stars! Answer the question cards to rebuild each bridge and win the prize. Stuck? Jump at the whiteboard to learn."))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_override("font", ui_font(400))
	intro.add_theme_font_size_override("font_size", 23)
	intro.add_theme_color_override("font_color", INK)
	intro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(intro)

	var choose := Label.new()
	choose.text = "Choose your hero"
	choose.add_theme_font_override("font", _bold_font)
	choose.add_theme_font_size_override("font_size", 26)
	choose.add_theme_color_override("font_color", PURPLE)
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(choose)

	# One button per hero (named in config.json); < > cycle that hero's outfits.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var prev := _button("<", PURPLE)
	row.add_child(prev)
	var hero_buttons: Array[Button] = []
	for i in Game.heroes().size():
		var h: Dictionary = Game.heroes()[i]
		var b := _button(str(h.name), Color(str(h.get("color", "#7c6cf0"))))
		b.add_theme_font_size_override("font_size", 24)
		row.add_child(b)
		hero_buttons.append(b)
	var next := _button(">", PURPLE)
	row.add_child(next)
	for b in [prev, next]:
		b.add_theme_font_size_override("font_size", 24)

	var play := _button("Play!", GREEN)
	play.add_theme_font_size_override("font_size", 40)
	play.custom_minimum_size.y = 84
	v.add_child(play)

	var update := func():
		for i in hero_buttons.size():
			hero_buttons[i].modulate.a = 1.0 if i == Game.hero_index else 0.5
		var hero: Dictionary = Game.heroes()[Game.hero_index]
		var models: Array = hero.models
		Game.outfit_index = posmod(Game.outfit_index, models.size())
		Game.hero_name = str(hero.name)
		character_picked.emit(str(models[Game.outfit_index]))
	for i in hero_buttons.size():
		hero_buttons[i].pressed.connect(func():
			if Game.hero_index != i:
				Game.outfit_index = 0
			Game.hero_index = i
			Game.sfx("click")
			update.call())
	prev.pressed.connect(func():
		Game.outfit_index -= 1
		Game.sfx("click")
		update.call())
	next.pressed.connect(func():
		Game.outfit_index += 1
		Game.sfx("click")
		update.call())
	play.pressed.connect(func():
		Game.sfx("open")
		play_pressed.emit())
	update.call()


# ------------------------------------------------------------------ island picker

func show_island_picker() -> void:
	if _title:
		_title.visible = false
	if _picker:
		_picker.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.06, 0.25, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker = dim

	var panel := _panel(CREAM, PURPLE, 26)
	dim.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		panel.set("offset_" + side, 40 if side in ["left", "top"] else -40)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var back := _button("<", PURPLE)
	top.add_child(back)
	var t := Label.new()
	t.text = "%s, choose an island!" % Game.hero_name
	t.add_theme_font_override("font", _bold_font)
	t.add_theme_font_size_override("font_size", 36)
	t.add_theme_color_override("font_color", PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)

	var grid := GridContainer.new()
	var course: Array = Game.config.course
	grid.columns = 3 if course.size() > 4 else 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	var themes: Dictionary = preload("res://scripts/world.gd").THEMES
	for i in course.size():
		var entry: Dictionary = course[i]
		var th: Dictionary = themes.get(str(entry.get("theme", "meadow")), themes.meadow)
		var b := _button("", th.grass.darkened(0.15))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(200, 120)
		grid.add_child(b)
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		b.add_child(inner)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var num := Label.new()
		num.text = "Isla %d" % (i + 1)
		num.add_theme_font_override("font", _bold_font)
		num.add_theme_font_size_override("font_size", 22)
		num.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(num)
		var name_l := Label.new()
		name_l.text = str(entry.get("title", "Island %d" % (i + 1)))
		name_l.add_theme_font_override("font", _bold_font)
		name_l.add_theme_font_size_override("font_size", 28)
		name_l.add_theme_color_override("font_color", Color.WHITE)
		name_l.add_theme_color_override("font_outline_color", th.dirt.darkened(0.4))
		name_l.add_theme_constant_override("outline_size", 8)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(name_l)
		var stars_row := HBoxContainer.new()
		stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(stars_row)
		var best := Game.best_rating(str(entry.file))
		for s in 3:
			var ic := Icon.new()
			ic.kind = "star"
			ic.color = Color("#ffd23f") if s < best else Color(1, 1, 1, 0.35)
			ic.custom_minimum_size = Vector2(28, 28)
			stars_row.add_child(ic)
		var sweets_best := Game.best_sweets(str(entry.file))
		if sweets_best > 0:
			var sw := HBoxContainer.new()
			sw.alignment = BoxContainer.ALIGNMENT_CENTER
			sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(sw)
			for s in sweets_best:
				var si := Icon.new()
				si.kind = "sweet"
				si.color = Color("#ff6fb5")
				si.custom_minimum_size = Vector2(30, 24)
				sw.add_child(si)
		for c in [num, stars_row]:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.pressed.connect(func():
			Game.sfx("open")
			island_picked.emit(i))

	back.pressed.connect(func():
		Game.sfx("click")
		_picker.queue_free()
		_picker = null
		if _title:
			_title.visible = true)
	_pop_in(panel)


# ------------------------------------------------------------------ HUD

func show_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hud)
	root.move_child(touch, -1)
	touch.visible = Game.is_touch()

	var bar := HBoxContainer.new()
	bar.position = Vector2(20, 16)
	bar.add_theme_constant_override("separation", 12)
	_hud.add_child(bar)
	_star_label = _counter(bar, "star", Color("#ffd23f"))
	_coin_label = _counter(bar, "coin", Color("#ffb43c"))
	_card_label = _counter(bar, "card", Color("#ffffff"))
	if Game.total_sweets > 0:
		_sweet_label = _counter(bar, "sweet", Color("#ff6fb5"))
	if Game.ingredients_total > 0:
		_ingredient_label = _counter(bar, "bag", Color("#ffb43c"))
	if Game.total_retos > 0:
		_retos_label = _counter(bar, "letter", Color("#ffd23f"))
	_key_pill = _counter(bar, "key", Color("#ffd23f")).get_parent().get_parent()
	_key_pill.visible = false

	var menu := _button("Islas", Color(0.18, 0.12, 0.35, 0.6))
	menu.add_theme_font_size_override("font_size", 24)
	_hud.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	menu.offset_left = -150
	menu.offset_right = -20
	menu.offset_top = 16
	menu.offset_bottom = 76
	menu.pressed.connect(_confirm_leave)

	# Big countdown clock for timed challenges (hidden until needed).
	_timer_label = Label.new()
	_timer_label.add_theme_font_override("font", _title_font)
	_timer_label.add_theme_font_size_override("font_size", 64)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	_timer_label.add_theme_color_override("font_outline_color", Color(0.45, 0.15, 0.35))
	_timer_label.add_theme_constant_override("outline_size", 14)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.visible = false
	_hud.add_child(_timer_label)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_top = 160
	_timer_label.offset_left = -150
	_timer_label.offset_right = 150

	_toast_box = _panel(Color(0.18, 0.12, 0.35, 0.85), Color(1, 1, 1, 0.0), 18)
	_toast_box.position.y = 100
	_toast_box.modulate.a = 0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_toast_box)
	_toast_label = Label.new()
	_toast_label.add_theme_font_override("font", _bold_font)
	_toast_label.add_theme_font_size_override("font_size", 28)
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_box.add_child(_toast_label)
	_refresh()


func _confirm_leave() -> void:
	if Game.ui_open:
		return
	Game.ui_open = true
	Game.sfx("click")
	var dim := _dim()
	var p := _panel(CREAM, PURPLE, 24, 8)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	var l := Label.new()
	l.text = "Leave this island and go back to the map?"
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", INK)
	v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var stay := _button("Stay", GREEN)
	var go := _button("Back to the islands", PURPLE)
	row.add_child(stay)
	row.add_child(go)
	stay.pressed.connect(func():
		dim.queue_free()
		Game.ui_open = false)
	go.pressed.connect(func(): menu_pressed.emit())
	_pop_in(p)


## Shows the countdown for a timed challenge; a negative value hides it.
func set_timer(seconds: float) -> void:
	if not _timer_label:
		return
	_timer_label.visible = seconds >= 0
	_timer_label.text = "%.1f" % maxf(seconds, 0.0)
	_timer_label.add_theme_color_override("font_color", Color(1, 0.45, 0.45) if seconds < 5.0 else Color.WHITE)


func _counter(parent: Control, icon: String, color: Color) -> Label:
	var pill := _panel(Color(0.18, 0.12, 0.35, 0.6), Color(1, 1, 1, 0.0), 30)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	pill.add_child(h)
	var ic := Icon.new()
	ic.kind = icon
	ic.color = color
	ic.custom_minimum_size = Vector2(36, 36)
	h.add_child(ic)
	var l := Label.new()
	l.add_theme_font_override("font", _bold_font)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color.WHITE)
	h.add_child(l)
	return l


func _refresh() -> void:
	if not _star_label:
		return
	_star_label.text = "%d / %d" % [Game.stars, Game.total_stars]
	_coin_label.text = str(Game.coins)
	_card_label.text = "Bridge %d / %d" % [Game.cards_solved, Game.total_cards]
	if _sweet_label:
		_sweet_label.text = "%d / %d" % [Game.sweets, Game.total_sweets]
	if _retos_label:
		_retos_label.text = "Reto %d / %d" % [Game.retos_done, Game.total_retos]
	if _ingredient_label:
		_ingredient_label.text = "%d / %d" % [Game.ingredients.size(), Game.ingredients_total]
	_key_pill.visible = Game.has_key
	if Game.has_key:
		(_key_pill.get_child(0).get_child(1) as Label).text = "Key!"


func show_toast(text: String) -> void:
	if not _toast_box:
		return
	_toast_label.text = text
	# Shrink long messages to fit rather than wrapping (wrapped labels size badly in containers).
	var font := _toast_label.get_theme_font("font")
	var want := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var maxw := root.size.x - 100
	_toast_label.add_theme_font_size_override("font_size", 28 if want <= maxw else maxi(16, int(28 * maxw / want)))
	_toast_box.size = Vector2.ZERO
	_toast_box.reset_size()
	_toast_box.position.x = (root.size.x - _toast_box.size.x) / 2
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_box, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(clampf(text.length() * 0.06, 2.2, 5.0))
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ lesson reader

## Opens the whiteboard lesson. Long lesson pages are split across several screens
## (never scrolling); arrow keys or the buttons turn pages.
func open_lesson(pages: Array, start := 0) -> void:
	Game.ui_open = true
	Game.sfx("open")
	var sc := Game.text_scale()

	var dim := _dim()
	if _hud:
		_hud.visible = false
	if touch:
		touch.visible = false
	var board := _panel(Color.WHITE, Color("#8f73e6"), 26, 12)
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mx := maxf(22.0, root.size.x * 0.04)
	var my := maxf(16.0, root.size.y * 0.035)
	board.offset_left = mx
	board.offset_right = -mx
	board.offset_top = my
	board.offset_bottom = -my
	dim.add_child(board)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	board.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	# The page title in a coloured tab (like the question cards' "Pregunta").
	var tab := _panel(PURPLE, Color(0, 0, 0, 0), 14, 0)
	var tsb := tab.get_theme_stylebox("panel") as StyleBoxFlat
	tsb.content_margin_left = 16
	tsb.content_margin_right = 16
	tsb.content_margin_top = 3
	tsb.content_margin_bottom = 3
	top.add_child(tab)
	var head := Label.new()
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color.WHITE)
	tab.add_child(head)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var close := _button("X", Color("#9a94b8"))
	close.add_theme_font_size_override("font_size", 22)
	close.custom_minimum_size = Vector2(54, 46)
	top.add_child(close)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	v.add_child(margin)
	var text := _lesson_label(sc)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.clip_contents = true
	margin.add_child(text)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	v.add_child(nav)
	var prev := _button("< Back", PURPLE)
	var dots := Label.new()
	dots.add_theme_font_override("font", _bold_font)
	dots.add_theme_font_size_override("font_size", 22)
	dots.add_theme_color_override("font_color", PURPLE)
	dots.custom_minimum_size.x = 70
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next := _button("Next >", PURPLE)
	var done := _button("Let's play!", GREEN)
	for b in [prev, dots, next, done]:
		nav.add_child(b)

	# Wait for layout so we know how much text fits, then split into screens.
	board.modulate.a = 0
	await get_tree().process_frame
	await get_tree().process_frame
	var sheets := _paginate(pages, text.size, sc)

	var s := {"page": 0}
	var show := func(p: int):
		p = clampi(p, 0, sheets.size() - 1)
		s.page = p
		head.text = sheets[p].title
		text.text = sheets[p].bb
		# Centre the text block: equal space either side of its widest line.
		var spare := maxf(0.0, (margin.size.x - 36.0) - float(sheets[p].w) - 8.0)
		margin.add_theme_constant_override("margin_left", 18 + int(spare / 2.0))
		margin.add_theme_constant_override("margin_right", 18 + int(spare / 2.0))
		# ...and vertically, so short pages don't leave a big gap at the bottom.
		var spare_h := maxf(0.0, margin.size.y - float(sheets[p].h))
		margin.add_theme_constant_override("margin_top", int(spare_h * 0.4))
		dots.text = "%d / %d" % [p + 1, sheets.size()]
		prev.disabled = p == 0
		next.disabled = p == sheets.size() - 1
		prev.modulate.a = 0.4 if prev.disabled else 1.0
		next.modulate.a = 0.4 if next.disabled else 1.0
	# Start on the first screen of the requested lesson page.
	var first := 0
	for i in sheets.size():
		if sheets[i].page == start:
			first = i
			break
	show.call(first)
	_page_turn = func(dir: int):
		if s.page + dir >= 0 and s.page + dir < sheets.size():
			Game.sfx("click")
			show.call(s.page + dir)
	prev.pressed.connect(func(): _page_turn.call(-1))
	next.pressed.connect(func(): _page_turn.call(1))
	var finish := func(): _lesson_closed.emit()
	close.pressed.connect(finish)
	done.pressed.connect(finish)

	_pop_in(board)
	await _lesson_closed
	_page_turn = Callable()
	if _hud:
		_hud.visible = true
	if touch:
		touch.visible = true
	Game.sfx("close")
	dim.queue_free()
	Game.ui_open = false


func _lesson_label(sc: float) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	var body := int(27 * sc)
	text.add_theme_font_size_override("normal_font_size", body)
	text.add_theme_font_size_override("bold_font_size", body)
	text.add_theme_font_size_override("italics_font_size", body)
	text.add_theme_font_size_override("bold_italics_font_size", body)
	text.add_theme_font_size_override("mono_font_size", int(25 * sc))
	text.add_theme_color_override("default_color", INK)
	text.add_theme_constant_override("line_separation", int(6 * sc))
	# DynaPuff for the lesson text too: regular for body, heavy for bold, slanted for italics.
	var italic := ui_font(400) as FontVariation
	italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	var bold_italic := ui_font(700) as FontVariation
	bold_italic.variation_transform = italic.variation_transform
	text.add_theme_font_override("normal_font", ui_font(400))
	text.add_theme_font_override("bold_font", ui_font(700))
	text.add_theme_font_override("italics_font", italic)
	text.add_theme_font_override("bold_italics_font", bold_italic)
	return text


## Splits lesson pages into screens that fit `area` without scrolling.
## Blocks (paragraphs, lists, tables) are never cut in half, and a heading always
## moves to the next screen together with the block after it.
func _paginate(pages: Array, area: Vector2, sc: float) -> Array:
	var probe := _lesson_label(sc)
	probe.fit_content = true
	probe.position = Vector2(-10000, 0)
	probe.size = Vector2(area.x, 10)
	root.add_child(probe)
	var sheets := []
	for pi in pages.size():
		var blocks := Markdown.to_blocks(pages[pi].markdown, sc)
		var parts: Array[String] = []
		var cur := PackedStringArray()
		for bi in blocks.size():
			var b: String = blocks[bi]
			if cur.is_empty() and b.strip_edges() == "":
				continue
			var trial := cur.duplicate()
			trial.append(b)
			if Markdown.is_heading(b) and bi + 1 < blocks.size():
				trial.append(blocks[bi + 1])
			probe.text = "\n".join(trial)
			if probe.get_content_height() > area.y and not cur.is_empty():
				parts.append(_trim_blank("\n".join(cur)))
				cur = PackedStringArray()
				if b.strip_edges() == "":
					continue
			cur.append(b)
		if not cur.is_empty():
			parts.append(_trim_blank("\n".join(cur)))
		if parts.is_empty():
			parts.append("")
		for k in parts.size():
			var title: String = pages[pi].title
			if parts.size() > 1:
				title += "  (%d/%d)" % [k + 1, parts.size()]
			probe.text = parts[k]
			sheets.append({"title": title, "bb": parts[k], "page": pi, "w": probe.get_content_width(), "h": probe.get_content_height()})
	probe.queue_free()
	return sheets


func _trim_blank(s: String) -> String:
	while s.ends_with("\n"):
		s = s.substr(0, s.length() - 1)
	return s


# ------------------------------------------------------------------ questions

## Shows a question. Returns "correct", "locked" (wrong - go read the whiteboard) or "skipped".
## `kind` is "card" or "chest" (only affects the look and wording).
func ask_question(q: Dictionary, kind: String) -> String:
	Game.ui_open = true
	Game.sfx("card" if kind == "card" else "open")
	var dim := _dim()
	var accent: Color = {"card": PINK, "chest": ORANGE, "sweet": Color("#c04fd8"), "detective": Color("#2e86de")}.get(kind, PINK)
	# Phones: a typed answer opens the same card as a wide strip across the top of the screen,
	# leaving the bottom half for the phone keyboard (and hiding the scores meanwhile).
	var phone: bool = (q.choices as Array).is_empty() and phone_layout()
	if phone and str(Game.config.get("phone_keyboard", "game")) == "game":
		dim.queue_free()
		return await _ask_typed_phone(q, kind, accent)
	var card := _panel(CREAM, accent, 20 if phone else 24, 6 if phone else 8)
	if phone:
		card.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 14)
		card.offset_left = 28
		card.offset_right = -28
		card.offset_top = 14
		card.grow_vertical = Control.GROW_DIRECTION_END
		if _hud:
			_hud.visible = false
		if touch:
			touch.visible = false        # the joystick and JUMP button
	else:
		card.set_anchors_preset(Control.PRESET_CENTER)
		card.custom_minimum_size = Vector2(minf(820, root.size.x - 40), 0)
		card.grow_horizontal = Control.GROW_DIRECTION_BOTH
		card.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10 if phone else 14)
	card.add_child(v)

	var head := Label.new()
	head.text = {"card": "QUESTION CARD", "chest": "QUIZ CHEST", "sweet": "SWEET CHALLENGE  (extension)", "detective": "RETO: ¿QUIÉN LO DICE?"}.get(kind, "QUESTION")
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 20 if phone else 24)
	head.add_theme_color_override("font_color", accent)
	v.add_child(head)
	var rule := ColorRect.new()
	rule.color = Color("#f28b9b")
	rule.custom_minimum_size.y = 3
	v.add_child(rule)

	var ql := Label.new()
	ql.text = q.question.replace("\n", "  ") if phone else q.question
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("font_size", 26 if phone else 30)
	if phone:
		ql.add_theme_constant_override("line_spacing", 6)
	ql.add_theme_color_override("font_color", INK)
	v.add_child(ql)

	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 25)
	feedback.visible = false
	v.add_child(feedback)

	var answer_area := VBoxContainer.new()
	answer_area.add_theme_constant_override("separation", 10)
	v.add_child(answer_area)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bottom)
	var leave := _button("Not now", Color("#9a94b8"))
	bottom.add_child(leave)

	var state := {"tries": 0, "locked": false}
	var finish_btn := _button("", GREEN)

	var succeed := func(note: String):
		if kind not in ["sweet", "detective"]:  # bonus challenges - not part of the score
			Game.record_attempt(q.id, true)
		Game.sfx("correct")
		answer_area.visible = false
		leave.visible = false
		head.text = "¡CORRECTO!"
		head.add_theme_color_override("font_color", GREEN)
		feedback.visible = true
		feedback.add_theme_color_override("font_color", Color("#1f8a52"))
		var msg: String = q.explanation if q.explanation != "" else "¡Muy bien, %s!" % Game.hero_name
		feedback.text = msg if note == "" else msg + "\n" + note
		finish_btn.text = {"card": "Build the bridge!", "chest": "Open the chest!", "sweet": "Grab the sweet!", "detective": "¡Siguiente!"}.get(kind, "Yay!")
		finish_btn.custom_minimum_size.y = 70
		bottom.add_child(finish_btn)
		bottom.visible = true          # (hidden on phones while typing)
		finish_btn.pressed.connect(func(): _question_done.emit("correct"))
		_bounce(card)

	var fail := func(lock: bool):
		if kind not in ["sweet", "detective"]:  # bonus challenges - not part of the score
			Game.record_attempt(q.id, false)
		Game.sfx("wrong")
		feedback.visible = true
		feedback.add_theme_color_override("font_color", Color("#c2410c"))
		_shake(card)
		if lock and kind == "detective":
			answer_area.visible = false
			head.text = "¡NO!"
			feedback.text = "Not quite. %s\n\nRead the reviews again, then come back to the desk." % q.hint
			leave.text = "OK"
		elif lock and kind == "chest":
			# Chests don't lock - just send the student back to the whiteboard.
			answer_area.visible = false
			head.text = "¡OH NO!"
			feedback.text = "Not quite. %s\n\nHead back to the whiteboard to check, then try this chest again." % q.hint
			leave.text = "OK"
		elif lock:
			state.locked = true
			answer_area.visible = false
			head.text = "¡OH NO!"
			feedback.text = "Not quite. %s\n\n%s locked itself! Jump at the whiteboard to read, then come back." % [q.hint, {"card": "The card", "chest": "The chest", "sweet": "The sweet"}.get(kind, "It")]
			leave.text = "To the whiteboard!"
		else:
			feedback.text = "Not quite - try again!  Hint: %s" % q.hint

	if q.choices.size() > 0:
		# Multiple choice: shuffle so the right answer moves around.
		var order := range(q.choices.size())
		order.shuffle()
		var grid := GridContainer.new()
		grid.columns = 2 if root.size.x > 700 else 1
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		answer_area.add_child(grid)
		for n in order.size():
			var i: int = order[n]
			var b := _button(q.choices[i], CHOICE_COLORS[n % CHOICE_COLORS.size()])
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 68
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			# Kenney's display font is hard to read for sentences - use the plain font for long choices.
			if str(q.choices[i]).length() > 18:
				b.remove_theme_font_override("font")
				b.add_theme_font_size_override("font_size", 25)
			grid.add_child(b)
			b.pressed.connect(func():
				if i == q.correct:
					succeed.call("")
				else:
					fail.call(true))
	else:
		# Typed answer
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		answer_area.add_child(row)
		var line := LineEdit.new()
		line.placeholder_text = "Type your answer..."
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.custom_minimum_size.y = 64
		line.add_theme_font_size_override("font_size", 30)
		row.add_child(line)
		var check := _button("Check!", GREEN)
		check.custom_minimum_size = Vector2(160, 64)
		row.add_child(check)
		var submit := func(_t = null):
			if line.text.strip_edges() == "":
				return
			match Game.check_answer(line.text, q.answers):
				Game.RIGHT:
					succeed.call("")
				Game.RIGHT_BUT_ACCENTS:
					succeed.call("Watch the accents - it's spelled:  %s" % q.answers[0])
				_:
					state.tries += 1
					fail.call(state.tries >= 3)
					line.text = ""
		check.pressed.connect(submit)
		line.text_submitted.connect(submit)
		if phone:
			# Phones: tapping the answer field focuses an invisible browser text field (the only
			# way to bring up a phone keyboard); what's typed shows up here as it's typed.
			line.custom_minimum_size.y = 58
			line.add_theme_font_size_override("font_size", 26)
			line.add_theme_color_override("font_uneditable_color", INK)
			check.custom_minimum_size = Vector2(140, 58)
			line.editable = false
			line.placeholder_text = "Tap here to type..."
			leave.get_parent().remove_child(leave)
			row.add_child(leave)
			bottom.visible = false
			if str(Game.config.get("phone_keyboard", "game")) == "game":
				# Our own keyboard (no autocorrect, Spanish letters built in, matches the game).
				line.placeholder_text = "Type your answer..."
				var kb := game_keyboard(dim, line, submit)
				answer_area.visibility_changed.connect(func(): kb.visible = answer_area.visible)
			else:
				# The phone's own keyboard, via an invisible browser text field.
				var start_typing := func():
					if OS.has_feature("web"):
						JavaScriptBridge.eval("window.liTypeStart && window.liTypeStart(%s)" % JSON.stringify(line.text))
					_type_into(line, answer_area, submit)
				line.gui_input.connect(func(e: InputEvent):
					if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
						start_typing.call())
				# Once answered, the result and its button go back in the card's own bottom row.
				finish_btn.tree_entered.connect(func(): bottom.visible = true)
		else:
			# Accent buttons: English keyboards can't easily type á, ñ, ¿ ...
			var keys := HBoxContainer.new()
			keys.add_theme_constant_override("separation", 6)
			answer_area.add_child(keys)
			for ch in ACCENT_KEYS:
				var kb := _button(ch, Color("#b3a8e8"))
				kb.remove_theme_font_override("font")
				kb.add_theme_font_size_override("font_size", 24)
				kb.custom_minimum_size = Vector2(52, 48)
				keys.add_child(kb)
				kb.pressed.connect(func():
					line.insert_text_at_caret(ch)
					line.grab_focus())
			line.call_deferred("grab_focus")

	leave.pressed.connect(func(): _question_done.emit("locked" if state.locked else "skipped"))
	_pop_in(card)
	var result: String = await _question_done
	Game.sfx("click" if result == "correct" else "close")
	if phone:
		_typing = false
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.liTypeStop && window.liTypeStop()")
		if _hud:
			_hud.visible = true
		if touch:
			touch.visible = true
	dim.queue_free()
	Game.ui_open = false
	return result


## Typed questions on a phone: one floating panel over the (still visible) game world, with
## the question on top - the answer typed straight into its blank - and our own keyboard
## below. Same results as ask_question: "correct", "skipped" or "locked".
func _ask_typed_phone(q: Dictionary, kind: String, accent: Color) -> String:
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.06, 0.25, 0.25)       # lighter than desktop: the world stays bright
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.move_child(touch, -1)
	if _hud:
		_hud.visible = false
	if touch:
		touch.visible = false
	var W := root.size.x
	var H := root.size.y
	var panel := _panel(CREAM, accent, 26, 6)
	var psb := panel.get_theme_stylebox("panel") as StyleBoxFlat
	psb.content_margin_left = 18
	psb.content_margin_right = 18
	psb.content_margin_top = 12
	psb.content_margin_bottom = 14
	var pw := minf(W * 0.9, 1100.0)
	panel.custom_minimum_size.x = pw
	dim.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -pw / 2.0
	panel.offset_right = pw / 2.0
	panel.offset_bottom = -maxf(12.0, H * 0.03)
	panel.offset_top = panel.offset_bottom
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# Top row: a little coloured tab saying what this is, any hint in brackets, and a close ✕.
	var lines := PackedStringArray(str(q.question).split("\n"))
	var blank := RegEx.create_from_string("_{2,}")
	var main_i := -1
	for i in lines.size():
		if blank.search(lines[i]):
			main_i = i
			break
	var sentence := ""
	var extra := ""
	if main_i >= 0:
		sentence = lines[main_i]
		var rest := PackedStringArray()
		for i in lines.size():
			if i != main_i and lines[i].strip_edges() != "":
				rest.append(lines[i].strip_edges())
		extra = "  ".join(rest)
	else:
		sentence = "  ".join(lines)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var tab := _panel(accent, Color(0, 0, 0, 0), 12, 0)
	var tsb := tab.get_theme_stylebox("panel") as StyleBoxFlat
	tsb.content_margin_left = 12
	tsb.content_margin_right = 12
	tsb.content_margin_top = 2
	tsb.content_margin_bottom = 2
	top.add_child(tab)
	var tab_l := Label.new()
	tab_l.text = {"card": "Pregunta", "chest": "Cofre", "sweet": "Dulce", "detective": "Reto"}.get(kind, "Pregunta")
	tab_l.add_theme_font_override("font", _bold_font)
	tab_l.add_theme_font_size_override("font_size", 18)
	tab_l.add_theme_color_override("font_color", Color.WHITE)
	tab.add_child(tab_l)
	var hint_l := Label.new()
	hint_l.text = extra
	hint_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_l.add_theme_font_size_override("font_size", 20)
	hint_l.add_theme_color_override("font_color", Color("#7a6fb0"))
	hint_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(hint_l)
	var close := _button("X", Color("#9a94b8"))
	close.add_theme_font_size_override("font_size", 20)
	close.custom_minimum_size = Vector2(52, 42)
	for st in ["normal", "hover", "pressed"]:
		var s := (close.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
		s.content_margin_left = 4
		s.content_margin_right = 4
		s.content_margin_top = 0
		close.add_theme_stylebox_override(st, s)
	top.add_child(close)

	# The question, with the answer typed into its blank (or on its own line below it).
	var qfont := int(clampf(H * 0.05, 22.0, 30.0))
	var ql := RichTextLabel.new()
	ql.bbcode_enabled = true
	ql.fit_content = true
	ql.scroll_active = false
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("normal_font_size", qfont)
	ql.add_theme_font_size_override("bold_font_size", int(qfont * 1.15))
	ql.add_theme_font_override("bold_font", _bold_font)
	ql.add_theme_color_override("default_color", INK)
	v.add_child(ql)
	var answer_l: RichTextLabel = null
	if main_i < 0:
		answer_l = RichTextLabel.new()
		answer_l.bbcode_enabled = true
		answer_l.fit_content = true
		answer_l.scroll_active = false
		answer_l.add_theme_font_size_override("bold_font_size", int(qfont * 1.3))
		answer_l.add_theme_font_override("bold_font", _bold_font)
		v.add_child(answer_l)
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 20)
	feedback.visible = false
	v.add_child(feedback)

	var st := {"ans": "", "pos": 0, "tries": 0, "locked": false, "col": "#4b3aa8", "cursor": true, "done": false}
	var redraw := func():
		# The cursor is always there (so nothing moves); it blinks by turning invisible.
		# A block cursor: the letter at the cursor is highlighted (so it takes no extra room);
		# at the end it highlights a blank that is always there. It blinks by colour only.
		var full: String = str(st.ans)
		var p: int = clampi(int(st.pos), 0, full.length())
		var on: bool = st.cursor and not st.done
		var bg: String = "#b3a8e8" if on else "#00000000"
		var at := full.substr(p, 1) if p < full.length() else " "
		var left := full.left(p).replace("[", "[lb]")
		var right := full.substr(p + 1).replace("[", "[lb]") if p < full.length() else ""
		var tail := "" if st.done and p >= full.length() else "[bgcolor=%s]%s[/bgcolor]" % [bg, at.replace("[", "[lb]")]
		var shown := ""
		if full == "":
			# Empty: the cursor sits on the first dash of the blank (so it starts on the left).
			shown = "[color=#b3a8e8][bgcolor=%s]_[/bgcolor]_____[/color]" % bg
		else:
			shown = "[u][b][color=%s]%s%s%s[/color][/b][/u]" % [st.col, left, tail, right]
		var esc := sentence.replace("[", "[lb]")
		if main_i >= 0:
			var m := blank.search(esc)
			ql.text = "[center]%s %s %s[/center]" % [esc.substr(0, m.get_start()), shown, esc.substr(m.get_end())]
		else:
			ql.text = "[center]%s[/center]" % esc
			answer_l.text = "[center]%s[/center]" % shown
	redraw.call()

	# The keyboard, part of the same panel.
	var kb := VBoxContainer.new()
	kb.add_theme_constant_override("separation", 5)
	v.add_child(kb)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.visible = false
	v.add_child(bottom)

	var finish := func(res: String): _question_done.emit(res)
	var shrink := func():
		# Keyboard gone: let the panel shrink back to fit what's left (it grows upwards).
		await get_tree().process_frame
		panel.offset_top = panel.offset_bottom
		panel.reset_size()
	var submit := func():
		if st.done or str(st.ans).strip_edges() == "":
			return
		var verdict: int = Game.check_answer(st.ans, q.answers)
		if verdict == Game.RIGHT or verdict == Game.RIGHT_BUT_ACCENTS:
			st.done = true
			if kind not in ["sweet", "detective"]:
				Game.record_attempt(q.id, true)
			Game.sfx("correct")
			st.col = "#1f8a52"
			redraw.call()
			kb.visible = false
			close.visible = false
			tab_l.text = "¡Correcto!"
			(tab.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = GREEN
			feedback.visible = true
			feedback.add_theme_color_override("font_color", Color("#1f8a52"))
			var msg: String = q.explanation if q.explanation != "" else "¡Muy bien, %s!" % Game.hero_name
			if verdict == Game.RIGHT_BUT_ACCENTS:
				msg += "\nWatch the accents - it's spelled:  %s" % q.answers[0]
			feedback.text = msg
			var go := _button({"card": "¡A construir el puente!", "chest": "¡Abre el cofre!", "sweet": "¡Toma el dulce!", "detective": "¡Siguiente!"}.get(kind, "¡Genial!"), GREEN)
			go.custom_minimum_size.y = 62
			bottom.add_child(go)
			bottom.visible = true
			go.pressed.connect(finish.bind("correct"))
			shrink.call()
			_bounce(panel)
			return
		# Wrong.
		st.tries += 1
		if kind not in ["sweet", "detective"]:
			Game.record_attempt(q.id, false)
		Game.sfx("wrong")
		_shake(panel)
		st.col = "#c2410c"
		redraw.call()
		feedback.visible = true
		feedback.add_theme_color_override("font_color", Color("#c2410c"))
		if st.tries >= 3 and kind != "chest":
			st.locked = true
			st.done = true
			kb.visible = false
			feedback.text = "Not quite. %s\n%s locked itself! Jump at the whiteboard to read, then come back." % [q.hint, {"card": "The card", "sweet": "The sweet"}.get(kind, "It")]
			var back := _button("¡A la pizarra!", ORANGE)
			back.custom_minimum_size.y = 58
			bottom.add_child(back)
			bottom.visible = true
			back.pressed.connect(finish.bind("locked"))
			shrink.call()
			return
		feedback.text = "Not quite - try again!  Hint: %s" % q.hint
		await get_tree().create_timer(0.6).timeout
		st.ans = ""
		st.pos = 0
		st.col = "#4b3aa8"
		redraw.call()

	var key_h := clampf(H * 0.085, 34.0, 56.0)
	_kb_rows(kb, pw - 36.0, key_h,
		func(t: String):
			if st.done:
				return
			var a: String = str(st.ans)
			st.ans = a.left(st.pos) + t + a.substr(st.pos)
			st.pos += t.length()
			st.col = "#4b3aa8"
			st.cursor = true
			redraw.call()
			Game.sfx("click", 1.6, -12),
		func():
			if st.done or int(st.pos) == 0:
				return
			var a: String = str(st.ans)
			st.ans = a.left(st.pos - 1) + a.substr(st.pos)
			st.pos -= 1
			st.cursor = true
			redraw.call()
			Game.sfx("click", 1.2, -12),
		submit, "¡Comprobar!",
		func(step: int):
			if st.done:
				return
			st.pos = clampi(int(st.pos) + step, 0, str(st.ans).length())
			st.cursor = true
			redraw.call()
			Game.sfx("click", 1.4, -14))
	close.pressed.connect(func(): finish.call("locked" if st.locked else "skipped"))

	# A blinking cursor while typing.
	var blink := Timer.new()
	blink.wait_time = 0.5
	blink.autostart = true
	panel.add_child(blink)
	blink.timeout.connect(func():
		st.cursor = not st.cursor
		redraw.call())

	_pop_in(panel)
	var result: String = await _question_done
	Game.sfx("click" if result == "correct" else "close")
	if _hud:
		_hud.visible = true
	if touch:
		touch.visible = true
	dim.queue_free()
	Game.ui_open = false
	return result


## The rows of our keyboard: Spanish letters, lowercase letters, "borrar", space and a submit
## key (`ok_label`), sized to `width`.
func _kb_rows(box: VBoxContainer, width: float, key_h: float, on_key: Callable, on_del: Callable, on_ok: Callable, ok_label: String, on_move := Callable()) -> void:
	var gap := 5.0
	var key_w := floorf((width - gap * 9.0) / 10.0)
	var font_px := int(key_h * 0.55)
	var make_key := func(label: String, col: Color, w: float) -> Button:
		var b := _button(label, col)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var s := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
			s.content_margin_left = 2
			s.content_margin_right = 2
			s.content_margin_top = 0
			s.set_corner_radius_all(12)
			b.add_theme_stylebox_override(st, s)
		b.add_theme_font_size_override("font_size", font_px)
		b.add_theme_constant_override("outline_size", 4)
		b.custom_minimum_size = Vector2(w, key_h)
		return b
	var add_row := func() -> HBoxContainer:
		var r := HBoxContainer.new()
		r.alignment = BoxContainer.ALIGNMENT_CENTER
		r.add_theme_constant_override("separation", int(gap))
		box.add_child(r)
		return r
	for spec in [[["á", "é", "í", "ó", "ú", "ñ", "ü"], PINK], [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], PURPLE],
			[["a", "s", "d", "f", "g", "h", "j", "k", "l"], PURPLE], [["z", "x", "c", "v", "b", "n", "m"], PURPLE]]:
		var r: HBoxContainer = add_row.call()
		var accents: bool = spec[0][0] == "á"
		if accents and on_move.is_valid():
			# Cursor arrows at the far ends of the accent row (above q and p).
			r.alignment = BoxContainer.ALIGNMENT_BEGIN
			var lb: Button = make_key.call("<", Color("#9a94b8"), key_w)
			lb.pressed.connect(on_move.bind(-1))
			r.add_child(lb)
			var sp1 := Control.new()
			sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(sp1)
		for k in spec[0]:
			var b: Button = make_key.call(str(k), spec[1], key_w)
			b.pressed.connect(on_key.bind(str(k)))
			r.add_child(b)
		if accents and on_move.is_valid():
			var sp2 := Control.new()
			sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(sp2)
			var rb: Button = make_key.call(">", Color("#9a94b8"), key_w)
			rb.pressed.connect(on_move.bind(1))
			r.add_child(rb)
		if spec[0][0] == "z":
			var del: Button = make_key.call("borrar", ORANGE, key_w * 2.0 + gap)
			del.pressed.connect(on_del)
			r.add_child(del)
	var r4: HBoxContainer = add_row.call()
	var space: Button = make_key.call("espacio", Color("#9a94b8"), key_w * 5.5)
	space.pressed.connect(on_key.bind(" "))
	r4.add_child(space)
	var ok: Button = make_key.call(ok_label, GREEN, key_w * 3.0 + gap * 2.0)
	ok.pressed.connect(on_ok)
	r4.add_child(ok)


## Our own on-screen keyboard for phones, along the bottom of the screen: a row of Spanish
## letters, lowercase letters, space, "borrar" and OK (which submits). Types into `line`.
func game_keyboard(parent: Control, line: LineEdit, submit: Callable) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#4b3aa8", 0.92)
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.set_content_margin_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var w := root.size.x - 28.0
	var gap := 6.0
	var key_w := floorf((w - gap * 9.0) / 10.0)
	var key_h := clampf((root.size.y * 0.5 - 16.0 - gap * 4.0) / 5.0, 36.0, 62.0)
	var font_px := int(key_h * 0.55)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(gap))
	panel.add_child(rows)
	var make_key := func(label: String, col: Color, width: float) -> Button:
		var b := _button(label, col)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var s := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
			s.content_margin_left = 2
			s.content_margin_right = 2
			s.content_margin_top = 0
			s.set_corner_radius_all(12)
			b.add_theme_stylebox_override(st, s)
		b.add_theme_font_size_override("font_size", font_px)
		b.add_theme_constant_override("outline_size", 4)
		b.custom_minimum_size = Vector2(width, key_h)
		return b
	var type_text := func(t: String):
		line.text += t
		line.caret_column = line.text.length()
		Game.sfx("click", 1.6, -12)
	var add_row := func(keys: Array, col: Color) -> HBoxContainer:
		var r := HBoxContainer.new()
		r.alignment = BoxContainer.ALIGNMENT_CENTER
		r.add_theme_constant_override("separation", int(gap))
		rows.add_child(r)
		for k in keys:
			var b: Button = make_key.call(str(k), col, key_w)
			b.pressed.connect(type_text.bind(str(k)))
			r.add_child(b)
		return r
	add_row.call(["á", "é", "í", "ó", "ú", "ñ", "ü"], PINK)
	add_row.call(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], PURPLE)
	add_row.call(["a", "s", "d", "f", "g", "h", "j", "k", "l"], PURPLE)
	var r3: HBoxContainer = add_row.call(["z", "x", "c", "v", "b", "n", "m"], PURPLE)
	var del: Button = make_key.call("borrar", ORANGE, key_w * 2.0 + gap)
	del.pressed.connect(func():
		if line.text.length() > 0:
			line.text = line.text.left(line.text.length() - 1)
			line.caret_column = line.text.length()
			Game.sfx("click", 1.2, -12))
	r3.add_child(del)
	var r4 := HBoxContainer.new()
	r4.alignment = BoxContainer.ALIGNMENT_CENTER
	r4.add_theme_constant_override("separation", int(gap))
	rows.add_child(r4)
	var space: Button = make_key.call("espacio", Color("#9a94b8"), key_w * 6.0 + gap * 5.0)
	space.pressed.connect(type_text.bind(" "))
	r4.add_child(space)
	var ok: Button = make_key.call("OK", GREEN, key_w * 2.0 + gap)
	ok.pressed.connect(func(): submit.call())
	r4.add_child(ok)
	return panel


## Phone layout for typed answers: on the web on a touch screen (or forced for testing with
## the --phone-card command line option).
func phone_layout() -> bool:
	return (OS.has_feature("web") and Game.is_touch()) or "--phone-card" in OS.get_cmdline_user_args()


## While the phone keyboard is up: copy what's typed in the invisible browser field into the
## card's answer field, and Enter submits. Stops when the answer area goes (answered/closed).
func _type_into(line: LineEdit, area: Control, submit: Callable) -> void:
	if _typing:
		return
	_typing = true
	var shown := line.text
	while _typing and is_instance_valid(line) and area.visible:
		await get_tree().process_frame
		if not OS.has_feature("web"):
			continue
		if line.text != shown:
			# The game changed it (e.g. cleared after a wrong answer): tell the browser field.
			JavaScriptBridge.eval("window.liTypeSet && window.liTypeSet(%s)" % JSON.stringify(line.text))
			shown = line.text
		var typed := str(JavaScriptBridge.eval("window.liTypeValue || ''"))
		if typed != line.text:
			line.text = typed
			line.caret_column = typed.length()
			shown = typed
		if str(JavaScriptBridge.eval("window.liTypeEnter ? '1' : ''")) == "1":
			JavaScriptBridge.eval("window.liTypeEnter = false")
			submit.call()
			shown = line.text
	_typing = false
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.liTypeStop && window.liTypeStop()")


# ------------------------------------------------------------------ game chooser

## "Which game?" - one big card per game in games.json. Returns the chosen game's id.
func show_game_chooser(games: Array) -> String:
	var bg := ColorRect.new()
	bg.color = Color("#6a5acd")
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	bg.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var t := Label.new()
	t.text = "¿A qué isla vas?"
	t.add_theme_font_override("font", _title_font)
	t.add_theme_font_size_override("font_size", 56)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.add_theme_color_override("font_outline_color", PURPLE_DARK)
	t.add_theme_constant_override("outline_size", 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var row := VBoxContainer.new()      # games stacked one above the other
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(row)
	for g in games:
		var col := Color(str(g.get("color", "#f0508c")))
		var b := _button("", col)
		b.custom_minimum_size = Vector2(minf(560, root.size.x - 60), minf(150, root.size.y * 0.24))
		row.add_child(b)
		var inner := VBoxContainer.new()
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for line in [[str(g.get("title", g.id)), 44, _title_font]]:
			var l := Label.new()
			l.text = line[0]
			l.add_theme_font_override("font", line[2])
			l.add_theme_font_size_override("font_size", line[1])
			l.add_theme_color_override("font_color", Color.WHITE)
			l.add_theme_color_override("font_outline_color", col.darkened(0.45))
			l.add_theme_constant_override("outline_size", 8)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(l)
		var id := str(g.get("id", ""))
		b.pressed.connect(func():
			Game.sfx("open")
			_chooser_done.emit(id))
	# A small, out-of-the-way button for the teacher (bottom right): opens the page set as
	# "teacher_games" in games.json, or says "Coming soon!" until there is one.
	var teacher := _button("Teacher Games", Color("#9a94b8"))
	teacher.add_theme_font_size_override("font_size", 16)
	teacher.add_theme_constant_override("outline_size", 4)
	teacher.custom_minimum_size = Vector2(0, 36)
	for st in ["normal", "hover", "pressed"]:
		var sb := teacher.get_theme_stylebox(st) as StyleBoxFlat
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
	bg.add_child(teacher)
	teacher.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	teacher.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	teacher.grow_vertical = Control.GROW_DIRECTION_BEGIN
	teacher.modulate.a = 0.85
	teacher.pressed.connect(func():
		Game.sfx("click")
		var url := Game.teacher_games_url
		if url == "":
			teacher.text = "Coming soon!"
			get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(teacher):
					teacher.text = "Teacher Games")
		elif OS.has_feature("web"):
			JavaScriptBridge.eval("window.location.href = new URL(%s, window.location.href).href" % JSON.stringify(url))
		else:
			OS.shell_open(url))
	var chosen: String = await _chooser_done
	bg.queue_free()
	return chosen


# ------------------------------------------------------------------ retos

## The sentence builder: write an answer, see which IGCSE features it has, improve it.
## Returns the stars of the answer that was sent (0 if the student left without sending).
func ask_sentence(ch: Dictionary, title := "RETO: LA POSTAL") -> int:
	Game.ui_open = true
	Game.sfx("card")
	var needed := int(ch.get("stars_needed", 3))
	var target := str(ch.get("tense", "preterite"))
	var dim := _dim()
	var card := _panel(CREAM, Color("#e6a817"), 24, 8)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(minf(960, root.size.x - 40), 0)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	card.add_child(v)

	var head := Label.new()
	head.text = title
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color("#c98a00"))
	v.add_child(head)
	var ql := Label.new()
	ql.text = str(ch.get("question", ""))
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("font_size", 28)
	ql.add_theme_color_override("font_color", INK)
	v.add_child(ql)
	var aim := Label.new()
	aim.text = "Aim for %d stars. Stars for: %s tense · second tense · connective · opinion · time phrase" % [needed, Marking.TENSE_NAMES.get(target, target).split(" ")[0]]
	aim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aim.add_theme_font_size_override("font_size", 18)
	aim.add_theme_color_override("font_color", Color("#8a84a8"))
	v.add_child(aim)

	var box := TextEdit.new()
	box.placeholder_text = "Escribe aquí..."
	box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.custom_minimum_size.y = 84
	box.add_theme_font_size_override("font_size", 24)
	v.add_child(box)
	if OS.has_feature("web") and Game.is_touch():
		box.editable = false
		box.placeholder_text = "Tap here to write..."
		box.gui_input.connect(func(e: InputEvent):
			if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
				var r = await web_ask(ql.text, box.text, true)
				if r != null:
					box.text = str(r))
	else:
		var keys := HBoxContainer.new()
		keys.add_theme_constant_override("separation", 6)
		v.add_child(keys)
		for chr in ACCENT_KEYS:
			var kb := _button(chr, Color("#b3a8e8"))
			kb.remove_theme_font_override("font")
			kb.add_theme_font_size_override("font_size", 20)
			kb.custom_minimum_size = Vector2(40, 36)
			keys.add_child(kb)
			kb.pressed.connect(func():
				box.insert_text_at_caret(chr)
				box.grab_focus())
		box.call_deferred("grab_focus")
	if ch.has("chips"):
		# Optional scaffolding: tap a phrase to add it.
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 6)
		v.add_child(chips)
		for phrase in ch.chips:
			var cb := _button(str(phrase), Color("#7fc8a9"))
			cb.remove_theme_font_override("font")
			cb.add_theme_font_size_override("font_size", 18)
			cb.custom_minimum_size.y = 34
			chips.add_child(cb)
			cb.pressed.connect(func():
				box.text = (box.text.strip_edges() + " " + str(phrase)).strip_edges() + " ")

	var result := RichTextLabel.new()
	result.bbcode_enabled = true
	result.fit_content = true
	result.scroll_active = false
	result.add_theme_font_size_override("normal_font_size", 22)
	result.add_theme_font_size_override("bold_font_size", 22)
	result.add_theme_color_override("default_color", INK)
	result.visible = false
	v.add_child(result)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	v.add_child(bottom)
	var stars_row := HBoxContainer.new()
	stars_row.visible = false
	stars_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(stars_row)
	var leave := _button("Salir", Color("#9a94b8"))
	var check := _button("Comprobar", PURPLE)
	var send := _button("¡Enviar!", GREEN)
	send.visible = false
	for b in [leave, check, send]:
		bottom.add_child(b)

	var state := {"stars": 0}
	check.pressed.connect(func():
		if box.text.strip_edges() == "":
			return
		var r: Dictionary = Marking.mark(box.text, ch)
		state.stars = r.stars
		Game.sfx("correct" if r.stars >= needed else "click")
		# Their sentence with the good bits coloured in, then a checklist.
		var bb := Marking.highlight(r) + "\n"
		var tips := PackedStringArray()
		for f in Marking.FEATURES:
			var got: bool = not (r.found[f] as Array).is_empty()
			if got:
				bb += "[color=%s][b]✓ %s[/b][/color]    " % [Marking.COLORS[f], Marking.LABELS[f]]
			else:
				tips.append(Marking.tip(f, r.target))
		if not tips.is_empty():
			bb += "\n[color=#8a84a8]Next star: %s[/color]" % tips[0].replace("[", "[lb]")
		for n in r.notes:
			bb += "\n[color=#c2410c]%s[/color]" % str(n).replace("[", "[lb]")
		result.text = bb
		result.visible = true
		for c in stars_row.get_children():
			c.queue_free()
		for i in 5:
			var ic := Icon.new()
			ic.kind = "star"
			ic.color = Color("#ffd23f") if i < r.stars else Color(0.85, 0.83, 0.9)
			ic.custom_minimum_size = Vector2(38, 38)
			stars_row.add_child(ic)
		stars_row.visible = true
		send.visible = r.stars >= needed
		check.text = "Comprobar otra vez"
		if r.stars < needed:
			_shake(card))
	send.pressed.connect(func(): _panel_done.emit("send"))
	leave.pressed.connect(func(): _panel_done.emit("leave"))
	_pop_in(card)
	var res: String = await _panel_done
	Game.sfx("click" if res == "send" else "close")
	dim.queue_free()
	Game.ui_open = false
	return int(state.stars) if res == "send" else 0


## "El tablón roto": a paragraph with numbered gaps; write the right form of each verb.
## Returns true when every gap is right.
func ask_notice(reto: Dictionary) -> bool:
	Game.ui_open = true
	Game.sfx("card")
	var gaps: Array = reto.get("gaps", [])
	var sc := Game.text_scale()
	var dim := _dim()
	var card := _panel(CREAM, Color("#b07a45"), 24, 8)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		card.set("offset_" + side, 24 if side in ["left", "top"] else -24)
	dim.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := Label.new()
	head.text = "RETO: EL TABLÓN ROTO"
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color("#8a5a2b"))
	v.add_child(head)
	var intro := Label.new()
	intro.text = str(reto.get("intro", "Fix the notice: write each verb in the right form."))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", int(24 * sc))
	intro.add_theme_color_override("font_color", INK)
	v.add_child(intro)
	var para := RichTextLabel.new()
	para.bbcode_enabled = true
	para.fit_content = true
	para.scroll_active = false
	para.add_theme_font_size_override("normal_font_size", int(26 * sc))
	para.add_theme_font_size_override("bold_font_size", int(26 * sc))
	para.add_theme_color_override("default_color", INK)
	v.add_child(para)
	var grid := GridContainer.new()
	grid.columns = 3 if root.size.x > 800 else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var inputs: Array[LineEdit] = []
	for i in gaps.size():
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		var l := Label.new()
		l.text = "(%d) %s" % [i + 1, gaps[i].get("verb", "")]
		l.custom_minimum_size.x = 150 * sc
		l.add_theme_font_size_override("font_size", int(22 * sc))
		l.add_theme_color_override("font_color", Color("#8a5a2b"))
		cell.add_child(l)
		var le := LineEdit.new()
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.custom_minimum_size.y = 44
		le.add_theme_font_size_override("font_size", int(22 * sc))
		cell.add_child(le)
		inputs.append(le)
		if OS.has_feature("web") and Game.is_touch():
			le.editable = false
			le.gui_input.connect(func(e: InputEvent):
				if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
					var r = await web_ask("(%d) %s" % [i + 1, gaps[i].get("verb", "")], le.text)
					if r != null:
						le.text = str(r))
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 22)
	v.add_child(feedback)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	v.add_child(bottom)
	var leave := _button("Salir", Color("#9a94b8"))
	var check := _button("Comprobar", PURPLE)
	var fix := _button("¡Arreglar el tablón!", GREEN)
	fix.visible = false
	for b in [leave, check, fix]:
		bottom.add_child(b)

	var render := func(marks: Array):
		# Paragraph with {1}, {2}... replaced by the student's answers (green / red) or blanks.
		var t := str(reto.get("text", "")).replace("[", "[lb]")
		for i in gaps.size():
			var shown := "[b](%d) ______[/b]" % (i + 1)
			if marks.size() > i and inputs[i].text.strip_edges() != "":
				shown = "[b][color=%s](%d) %s[/color][/b]" % ["#1f8a52" if marks[i] else "#c2410c", i + 1, inputs[i].text.strip_edges().replace("[", "[lb]")]
			t = t.replace("{%d}" % (i + 1), shown)
		para.text = t
	render.call([])
	check.pressed.connect(func():
		var marks := []
		var right := 0
		for i in gaps.size():
			var ok: bool = Game.check_answer(inputs[i].text, gaps[i].get("answers", [])) != Game.WRONG
			marks.append(ok)
			if ok:
				right += 1
		render.call(marks)
		if right == gaps.size():
			Game.sfx("correct")
			feedback.add_theme_color_override("font_color", Color("#1f8a52"))
			feedback.text = "¡Perfecto! %d / %d - every verb is right." % [right, gaps.size()]
			fix.visible = true
			check.visible = false
			_bounce(card)
		else:
			Game.sfx("wrong")
			feedback.add_theme_color_override("font_color", Color("#c2410c"))
			feedback.text = "%d / %d correct - fix the red ones. %s" % [right, gaps.size(), reto.get("hint", "")]
			_shake(card))
	fix.pressed.connect(func(): _panel_done.emit("fixed"))
	leave.pressed.connect(func(): _panel_done.emit("leave"))
	_pop_in(card)
	var res: String = await _panel_done
	Game.sfx("click" if res == "fixed" else "close")
	dim.queue_free()
	Game.ui_open = false
	return res == "fixed"


## "El chat": texting with a character on a phone. Each turn they send a message or two and
## you reply; the reply has to do what the turn asks (checked with simple patterns, see
## `chat_match`). Their answer can depend on what you said. Returns true when the chat is finished.
func ask_chat(reto: Dictionary) -> bool:
	Game.ui_open = true
	Game.sfx("card")
	var who := str(reto.get("name", "Sofía"))
	var accent := Color(str(reto.get("color", "#2e86de")))
	var dim := _dim()
	var phone := _panel(Color("#24213d"), Color("#24213d"), 34, 0)
	(phone.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12)
	phone.set_anchors_preset(Control.PRESET_CENTER)
	phone.custom_minimum_size = Vector2(minf(620, root.size.x - 24), root.size.y - 24)
	phone.grow_horizontal = Control.GROW_DIRECTION_BOTH
	phone.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(phone)
	var screen := _panel(Color("#f3f0fb"), Color(0, 0, 0, 0), 24, 0)
	(screen.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(0)
	phone.add_child(screen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	screen.add_child(v)

	# Contact bar: avatar, name and status.
	var bar := _panel(accent, Color(0, 0, 0, 0), 24, 0)
	var bsb := bar.get_theme_stylebox("panel") as StyleBoxFlat
	bsb.corner_radius_bottom_left = 0
	bsb.corner_radius_bottom_right = 0
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	v.add_child(bar)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 12)
	bar.add_child(bh)
	var avatar := _panel(Color.WHITE, Color(0, 0, 0, 0), 26, 0)
	(avatar.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(0)
	avatar.custom_minimum_size = Vector2(52, 52)
	bh.add_child(avatar)
	var initial := Label.new()
	initial.text = who.substr(0, 1)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_override("font", _bold_font)
	initial.add_theme_font_size_override("font_size", 30)
	initial.add_theme_color_override("font_color", accent)
	avatar.add_child(initial)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -4)
	bh.add_child(names)
	var name_l := Label.new()
	name_l.text = who
	name_l.add_theme_font_override("font", _bold_font)
	name_l.add_theme_font_size_override("font_size", 28)
	name_l.add_theme_color_override("font_color", Color.WHITE)
	names.add_child(name_l)
	var status := Label.new()
	status.text = "en línea"
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	names.add_child(status)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(spacer)
	var leave := _button("Salir", accent.darkened(0.25))
	leave.add_theme_font_size_override("font_size", 22)
	leave.custom_minimum_size.y = 46
	bh.add_child(leave)

	# The messages.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 12)
	scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	pad.add_child(list)
	var max_w := phone.custom_minimum_size.x * 0.72

	var add_bubble := func(text: String, kind: String) -> void:
		# kind: "them", "me" or "tip" (a hint from the game, not part of the chat)
		var row := HBoxContainer.new()
		row.alignment = {"them": BoxContainer.ALIGNMENT_BEGIN, "me": BoxContainer.ALIGNMENT_END}.get(kind, BoxContainer.ALIGNMENT_CENTER)
		var col: Color = {"them": Color.WHITE, "me": Color("#c9f2d9"), "tip": Color("#fff3c4")}[kind]
		var b := _panel(col, Color(0, 0, 0, 0), 18, 0)
		var sb := b.get_theme_stylebox("panel") as StyleBoxFlat
		sb.shadow_size = 3
		sb.shadow_offset = Vector2(0, 2)
		sb.shadow_color = Color(0.2, 0.1, 0.4, 0.15)
		if kind == "them":
			sb.corner_radius_bottom_left = 4
		elif kind == "me":
			sb.corner_radius_bottom_right = 4
		var l := Label.new()
		l.text = text
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var fs := 20 if kind == "tip" else 24
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_color_override("font_color", Color("#8a5a00") if kind == "tip" else INK)
		var font := l.get_theme_font("font")
		l.custom_minimum_size.x = minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 4, max_w)
		b.add_child(l)
		row.add_child(b)
		list.add_child(row)
		_pop_in(b)
		await get_tree().process_frame
		await get_tree().process_frame
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

	# What to do now (outside the chat, in English - it's the game talking).
	var task := Label.new()
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task.add_theme_font_size_override("font_size", 18)
	task.add_theme_color_override("font_color", Color("#6a5fb0"))
	var task_pad := MarginContainer.new()
	for side in ["left", "right"]:
		task_pad.add_theme_constant_override("margin_" + side, 14)
	task_pad.add_child(task)
	v.add_child(task_pad)
	var input_box := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		input_box.add_theme_constant_override("margin_" + side, 10)
	v.add_child(input_box)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	input_box.add_child(iv)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	iv.add_child(row)
	var line := LineEdit.new()
	line.placeholder_text = "Mensaje..."
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.custom_minimum_size.y = 56
	line.add_theme_font_size_override("font_size", 24)
	row.add_child(line)
	var send := _button("Enviar", accent)
	send.add_theme_font_size_override("font_size", 24)
	send.custom_minimum_size = Vector2(120, 56)
	row.add_child(send)
	var can_send := [false]
	var submit := func(_t = null):
		if can_send[0] and line.text.strip_edges() != "":
			_panel_done.emit("send")
	send.pressed.connect(submit)
	line.text_submitted.connect(submit)
	leave.pressed.connect(func(): _panel_done.emit("leave"))
	if OS.has_feature("web") and Game.is_touch():
		line.editable = false
		line.placeholder_text = "Tap here to reply..."
		line.gui_input.connect(func(e: InputEvent):
			if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
				var r = await web_ask(task.text, line.text)
				if r != null:
					line.text = str(r)
					submit.call())
	else:
		var keys := HBoxContainer.new()
		keys.add_theme_constant_override("separation", 5)
		iv.add_child(keys)
		for chr in ACCENT_KEYS:
			var kb := _button(chr, Color("#b3a8e8"))
			kb.remove_theme_font_override("font")
			kb.add_theme_font_size_override("font_size", 18)
			kb.custom_minimum_size = Vector2(38, 34)
			keys.add_child(kb)
			kb.pressed.connect(func():
				line.insert_text_at_caret(chr)
				line.grab_focus())
	_pop_in(phone)

	# They type (with a little "escribiendo..." pause), one message at a time.
	var closed := [false]
	var say := func(msgs: Array) -> void:
		for m in msgs:
			if closed[0]:
				return
			status.text = "escribiendo..."
			await get_tree().create_timer(clampf(0.35 + str(m).length() * 0.02, 0.5, 1.3)).timeout
			if closed[0]:
				return
			status.text = "en línea"
			Game.sfx("click", 1.4, -6)
			await add_bubble.call(str(m), "them")
	leave.pressed.connect(func(): closed[0] = true)

	var finished := false
	for turn in reto.get("turns", []):
		var touch_prompt := OS.has_feature("web") and Game.is_touch()   # phones type in a native prompt
		if not touch_prompt:
			line.editable = false
		can_send[0] = false
		task.text = ""
		await say.call(turn.get("them", []))
		if closed[0]:
			break
		if not turn.has("need"):
			continue
		task.text = str(turn.get("task", "Reply in Spanish."))
		can_send[0] = true
		if not touch_prompt:
			line.editable = true
			line.grab_focus()
		var tries := 0
		while true:
			var res: String = await _panel_done
			if res != "send":
				closed[0] = true
				break
			var text := line.text.strip_edges()
			line.text = ""
			can_send[0] = false
			if not touch_prompt:
				line.editable = false
			await add_bubble.call(text, "me")
			var opt := chat_match(text, turn.need)
			if opt.is_empty():
				tries += 1
				Game.sfx("wrong", 1.1, -6)
				await say.call([turn.get("confused", ["¿Cómo? No entiendo...", "¿Qué dices?", "Mmm... ¿perdona?"][tries % 3])])
				await add_bubble.call("Hint: " + str(turn.get("hint", "Read the message again.")), "tip")
				can_send[0] = true
				if not touch_prompt:
					line.editable = true
					line.grab_focus()
				continue
			Game.sfx("correct", 1.2, -4)
			await say.call(opt.get("reply", []))
			break
		if closed[0]:
			break
	if not closed[0]:
		finished = true
		task.text = ""
		line.editable = false
		can_send[0] = false
		await add_bubble.call("¡Chat completado! You kept the conversation going in Spanish.", "tip")
		send.text = "¡Genial!"
		send.pressed.disconnect(submit)
		send.pressed.connect(func(): _panel_done.emit("done"))
		await _panel_done
	Game.sfx("close")
	dim.queue_free()
	Game.ui_open = false
	return finished


## Which of a chat turn's accepted answers `text` matches: each option has "all" (every
## pattern must match) and optionally "none" (no pattern may match). Patterns are regular
## expressions tested on the lower-case reply with accents removed. {} when nothing fits.
static func chat_match(text: String, options: Array) -> Dictionary:
	var t := " " + Game.strip_accents(text.to_lower()) + " "
	for opt in options:
		var ok := true
		for pat in opt.get("all", []):
			var re := RegEx.create_from_string(str(pat))
			if re == null or re.search(t) == null:
				ok = false
				break
		for pat in opt.get("none", []):
			var re := RegEx.create_from_string(str(pat))
			if re and re.search(t) != null:
				ok = false
		if ok:
			return opt
	return {}


## Phones: typing happens in a game-styled HTML box at the top of the screen (above the phone
## keyboard), defined in the web page's head (see export_presets.cfg). Returns the text, or
## null if the student cancelled.
func web_ask(question: String, value: String, multiline := false) -> Variant:
	if not OS.has_feature("web"):
		return null
	if _asking:
		return null
	if str(JavaScriptBridge.eval("typeof window.liAsk")) != "function":
		# An old cached page without the text box: fall back to the browser's own prompt.
		var r = JavaScriptBridge.eval("window.prompt(%s, %s)" % [JSON.stringify(question), JSON.stringify(value)])
		return null if r == null else str(r)
	_asking = true
	JavaScriptBridge.eval("window.liAsk(%s, %s, %s)" % [JSON.stringify(question), JSON.stringify(value), "true" if multiline else "false"])
	var result: Variant = null
	while true:
		await get_tree().process_frame
		var st := str(JavaScriptBridge.eval("window.liState || ''"))
		if st == "ok":
			result = str(JavaScriptBridge.eval("window.liValue || ''"))
			break
		if st == "cancel":
			break
	_asking = false
	return result


## A text to read (e.g. a hotel review), in Markdown. Waits until closed.
func show_reading(title: String, markdown: String) -> void:
	Game.ui_open = true
	Game.sfx("open")
	var dim := _dim()
	var card := _panel(Color.WHITE, Color("#2e86de"), 24, 8)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(minf(900, root.size.x - 40), 0)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var head := Label.new()
	head.text = title
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", Color("#2e86de"))
	v.add_child(head)
	# Texts that start with their own big heading don't need the small title as well.
	head.visible = not markdown.strip_edges().begins_with("#")
	var text := _lesson_label(Game.text_scale())
	text.fit_content = true
	text.text = Markdown.to_bbcode(markdown, Game.text_scale())
	v.add_child(text)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bottom)
	var ok := _button("Entendido", GREEN)
	bottom.add_child(ok)
	ok.pressed.connect(func(): _panel_done.emit("ok"))
	_pop_in(card)
	await _panel_done
	Game.sfx("close")
	dim.queue_free()
	Game.ui_open = false


# ------------------------------------------------------------------ results

## Shows the end-of-island results. Returns "again", "islands" or "stay".
func show_results(prize: Dictionary, rating: int) -> String:
	Game.ui_open = true
	var dim := _dim()
	var p := _panel(CREAM, Color("#ffc83c"), 26, 10)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(minf(760, root.size.x - 40), 0)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)

	var t := Label.new()
	t.text = "¡Enhorabuena, %s!" % Game.hero_name
	t.add_theme_font_override("font", _title_font)
	t.add_theme_font_size_override("font_size", 38)
	t.add_theme_color_override("font_color", PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)

	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stars_row)
	for i in 3:
		var ic := Icon.new()
		ic.kind = "star"
		ic.color = Color("#ffd23f") if i < rating else Color(0.8, 0.78, 0.85)
		ic.custom_minimum_size = Vector2(80, 80)
		stars_row.add_child(ic)

	var msg := Label.new()
	msg.text = "You got the %s!  %s" % [prize.name, prize.message]
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 26)
	msg.add_theme_color_override("font_color", INK)
	v.add_child(msg)

	var stats := Label.new()
	stats.text = "Stars collected:  %d / %d\nCoins:  %d\nRight first time:  %d / %d" % [Game.stars, Game.total_stars, Game.coins, Game.first_try, Game.total_cards + Game.total_chests]
	if Game.total_sweets > 0:
		stats.text += "\nSweets:  %d / %d" % [Game.sweets, Game.total_sweets]
	if Game.total_retos > 0:
		stats.text += "\nRetos:  %d / %d" % [Game.retos_done, Game.total_retos]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_override("font", _bold_font)
	stats.add_theme_font_size_override("font_size", 26)
	stats.add_theme_color_override("font_color", PURPLE_DARK)
	v.add_child(stats)

	if Game.total_sweets > 0 and Game.sweets == Game.total_sweets:
		var kudos := Label.new()
		kudos.text = "¡Increíble! Every sweet found - extension master!"
		kudos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kudos.add_theme_font_override("font", _title_font)
		kudos.add_theme_font_size_override("font_size", 26)
		kudos.add_theme_color_override("font_color", Color("#c04fd8"))
		v.add_child(kudos)

	var shot := Label.new()
	shot.text = "Take a screenshot to show your teacher!"
	shot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shot.add_theme_font_size_override("font_size", 20)
	shot.add_theme_color_override("font_color", Color("#8a84a8"))
	v.add_child(shot)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var keep := _button("Keep exploring", PURPLE)
	var again := _button("Play again", GREEN)
	var islands := _button("Islands", ORANGE)
	for b in [keep, again, islands]:
		row.add_child(b)
	keep.pressed.connect(func(): _results_done.emit("stay"))
	again.pressed.connect(func(): _results_done.emit("again"))
	islands.pressed.connect(func(): _results_done.emit("islands"))
	_pop_in(p)
	var choice: String = await _results_done
	if choice == "stay":
		dim.queue_free()
		Game.ui_open = false
	return choice


# ------------------------------------------------------------------ helpers

func _dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.06, 0.25, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.move_child(touch, -1)
	return dim


func _panel(bg: Color, border: Color, radius := 22, border_w := 6) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w if border.a > 0 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(maxf(radius * 0.8, 14))
	sb.content_margin_top = maxf(radius * 0.5, 10)
	sb.content_margin_bottom = maxf(radius * 0.5, 10)
	if bg.a > 0.95:
		sb.shadow_color = Color(0.1, 0.0, 0.25, 0.3)
		sb.shadow_size = 14
		sb.shadow_offset = Vector2(0, 6)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	var normal := _button_style(color, 7)
	var hover := _button_style(color.lightened(0.12), 7)
	var pressed := _button_style(color.darkened(0.08), 2)
	pressed.content_margin_top += 5
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", _bold_font)
	b.add_theme_font_size_override("font_size", 28)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		b.add_theme_color_override(s, Color.WHITE)
	b.add_theme_color_override("font_outline_color", color.darkened(0.45))
	b.add_theme_constant_override("outline_size", 6)
	b.custom_minimum_size.y = 60
	return b


func _button_style(color: Color, depth: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = color.darkened(0.3)
	sb.border_width_bottom = depth
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10 + depth
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	var le := StyleBoxFlat.new()
	le.bg_color = Color.WHITE
	le.border_color = PURPLE
	le.set_border_width_all(4)
	le.set_corner_radius_all(16)
	le.set_content_margin_all(14)
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = PINK
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_stylebox("read_only", "LineEdit", le)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(0.6, 0.58, 0.7))
	t.set_color("caret_color", "LineEdit", PINK)
	# The sentence builder's writing box looks like the other answer boxes.
	for s in ["normal", "focus", "read_only"]:
		t.set_stylebox(s, "TextEdit", lef if s == "focus" else le)
	t.set_color("font_color", "TextEdit", INK)
	t.set_color("font_readonly_color", "TextEdit", INK)
	t.set_color("font_placeholder_color", "TextEdit", Color(0.6, 0.58, 0.7))
	t.set_color("caret_color", "TextEdit", PINK)
	t.set_color("background_color", "TextEdit", Color.WHITE)
	return t


func _pop_in(c: Control) -> void:
	c.pivot_offset = c.size / 2
	c.scale = Vector2(0.7, 0.7)
	c.modulate.a = 0
	await get_tree().process_frame
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2
	var t := create_tween().set_parallel()
	t.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, 0.15)


func _shake(c: Control) -> void:
	var x := c.position.x
	var t := create_tween()
	for i in 6:
		t.tween_property(c, "position:x", x + (14 if i % 2 == 0 else -14), 0.04)
	t.tween_property(c, "position:x", x, 0.04)


func _bounce(c: Control) -> void:
	c.pivot_offset = c.size / 2
	var t := create_tween()
	t.tween_property(c, "scale", Vector2(1.06, 1.06), 0.1)
	t.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Simple vector icons drawn in code (star, coin, card).
class Icon extends Control:
	var kind := "star"
	var color := Color.YELLOW

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 2
		var outline := Color(0.25, 0.15, 0.4)
		match kind:
			"star":
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2 + i * PI / 5
					var rr := r if i % 2 == 0 else r * 0.48
					pts.append(c + Vector2(cos(a), sin(a)) * rr)
				draw_colored_polygon(pts, color)
				pts.append(pts[0])
				draw_polyline(pts, outline, 2.5, true)
			"coin":
				draw_circle(c, r, color.darkened(0.2))
				draw_circle(c, r * 0.78, color)
				draw_arc(c, r, 0, TAU, 32, outline, 2.5, true)
				draw_rect(Rect2(c - Vector2(r * 0.12, r * 0.45), Vector2(r * 0.24, r * 0.9)), color.darkened(0.3))
			"sweet":
				# A wrapped sweet: round middle, twisted ends.
				var w := r * 0.55
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.8, 0), c + Vector2(-r, -r * 0.55), c + Vector2(-r, r * 0.55)]), color.darkened(0.15))
				draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.8, 0), c + Vector2(r, -r * 0.55), c + Vector2(r, r * 0.55)]), color.darkened(0.15))
				draw_circle(c, w, color)
				draw_arc(c, w, 0, TAU, 24, outline, 2.0, true)
				draw_circle(c + Vector2(-w * 0.3, -w * 0.3), w * 0.25, Color(1, 1, 1, 0.7))
			"bag":
				# A shopping bag: the things a character asked you to find.
				var body := Rect2(c + Vector2(-r * 0.7, -r * 0.35), Vector2(r * 1.4, r * 1.2))
				draw_rect(body, color)
				draw_rect(body, outline, false, 2.0)
				draw_arc(c + Vector2(0, -r * 0.35), r * 0.38, PI, TAU, 16, outline, 2.5, true)
			"pizza":
				# A pizza slice with pepperoni.
				var tri := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.6), c + Vector2(r * 0.8, -r * 0.6), c + Vector2(0, r * 0.9)])
				draw_colored_polygon(tri, color)
				draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.8), Vector2(r * 1.7, r * 0.25)), Color(0.8, 0.5, 0.25))
				for d in [Vector2(-0.3, -0.25), Vector2(0.3, -0.25), Vector2(0, 0.3)]:
					draw_circle(c + d * r, r * 0.14, Color(0.85, 0.2, 0.2))
				tri.append(tri[0])
				draw_polyline(tri, outline, 2.0, true)
			"letter":
				# An envelope.
				var env := Rect2(c - Vector2(r * 0.95, r * 0.62), Vector2(r * 1.9, r * 1.24))
				draw_rect(env, color)
				draw_polyline(PackedVector2Array([env.position, c + Vector2(0, r * 0.1), Vector2(env.end.x, env.position.y)]), outline, 2.0, true)
				draw_rect(env, outline, false, 2.0)
			"key":
				draw_arc(c + Vector2(-r * 0.45, 0), r * 0.38, 0, TAU, 20, color, r * 0.22, true)
				draw_rect(Rect2(c + Vector2(-r * 0.1, -r * 0.1), Vector2(r * 1.0, r * 0.2)), color)
				draw_rect(Rect2(c + Vector2(r * 0.55, 0), Vector2(r * 0.15, r * 0.35)), color)
				draw_rect(Rect2(c + Vector2(r * 0.8, 0), Vector2(r * 0.15, r * 0.25)), color)
			"card":
				var rect := Rect2(c - Vector2(r * 0.95, r * 0.7), Vector2(r * 1.9, r * 1.4))
				draw_rect(rect, Color(1, 0.99, 0.94))
				draw_line(rect.position + Vector2(3, r * 0.4), rect.position + Vector2(rect.size.x - 3, r * 0.4), Color(0.95, 0.4, 0.45), 2)
				for k in 3:
					var y := rect.position.y + r * 0.7 + k * r * 0.28
					draw_line(Vector2(rect.position.x + 3, y), Vector2(rect.end.x - 3, y), Color(0.55, 0.75, 0.95), 1.5)
				draw_rect(rect, outline, false, 2.5)
