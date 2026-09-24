extends CanvasLayer
## All 2D interface: title screen, island picker, HUD, lesson reader, question cards, results.

signal play_pressed
signal character_picked(name: String)
signal island_picked(index: int)
signal menu_pressed
signal _question_done(result: String)
signal _lesson_closed
signal _results_done(choice: String)

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
	var board := _panel(Color.WHITE, Color("#8f73e6"), 26, 14)
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		board.set("offset_" + side, 22 if side in ["left", "top"] else -22)
	dim.add_child(board)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	board.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var head := Label.new()
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", PURPLE)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(head)
	var close := _button("X", PINK)
	close.custom_minimum_size = Vector2(60, 52)
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
	dots.add_theme_font_size_override("font_size", 24)
	dots.add_theme_color_override("font_color", PURPLE)
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
			sheets.append({"title": title, "bb": parts[k], "page": pi})
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
	var accent: Color = {"card": PINK, "chest": ORANGE, "sweet": Color("#c04fd8")}.get(kind, PINK)
	var card := _panel(CREAM, accent, 24, 8)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(minf(820, root.size.x - 40), 0)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	dim.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)

	var head := Label.new()
	head.text = {"card": "QUESTION CARD", "chest": "QUIZ CHEST", "sweet": "SWEET CHALLENGE  (extension)"}.get(kind, "QUESTION")
	head.add_theme_font_override("font", _bold_font)
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", accent)
	v.add_child(head)
	var rule := ColorRect.new()
	rule.color = Color("#f28b9b")
	rule.custom_minimum_size.y = 3
	v.add_child(rule)

	var ql := Label.new()
	ql.text = q.question
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("font_size", 30)
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
		if kind != "sweet":  # sweets are bonus - not part of the score
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
		finish_btn.text = {"card": "Build the bridge!", "chest": "Open the chest!", "sweet": "Grab the sweet!"}.get(kind, "Yay!")
		finish_btn.custom_minimum_size.y = 70
		bottom.add_child(finish_btn)
		finish_btn.pressed.connect(func(): _question_done.emit("correct"))
		_bounce(card)

	var fail := func(lock: bool):
		if kind != "sweet":  # sweets are bonus - not part of the score
			Game.record_attempt(q.id, false)
		Game.sfx("wrong")
		feedback.visible = true
		feedback.add_theme_color_override("font_color", Color("#c2410c"))
		_shake(card)
		if lock and kind == "chest":
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
		if OS.has_feature("web") and Game.is_touch():
			# Mobile browsers: use the native text prompt - it always brings up the keyboard
			# (and phone keyboards can type accents).
			line.editable = false
			line.placeholder_text = "Tap here to type..."
			line.gui_input.connect(func(e: InputEvent):
				if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
					var r = JavaScriptBridge.eval("window.prompt(%s, '') || ''" % JSON.stringify(q.question))
					line.text = str(r)
					if line.text.strip_edges() != "":
						submit.call())
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
	dim.queue_free()
	Game.ui_open = false
	return result


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
