extends Node
## Loads config.json and lesson files.
##
## On the web, files are fetched from the server next to index.html, so the game can be
## re-configured and new lessons added by uploading JSON files - no re-export needed:
##   https://example.com/game/                      -> config.json (+ the lessons it lists)
##   https://example.com/game/?lesson=week12.json   -> just that one lesson
## If a fetch fails (or when running on desktop) the copy bundled in the game is used.

signal config_loaded(config: Dictionary)
signal loaded(lesson: Dictionary)


func load_config() -> void:
	var data = await _fetch_json("config.json")
	var cfg: Dictionary = data if data is Dictionary else {}
	# ?lesson=... on the web: play a single lesson file instead of the configured course.
	if OS.has_feature("web"):
		var single := str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('lesson') || ''"))
		if single != "":
			cfg["course"] = [{"file": single, "title": single.get_file().get_basename(), "theme": "meadow"}]
	config_loaded.emit(cfg)


func load_lesson(path: String) -> void:
	var data = await _fetch_json(path)
	if not data is Dictionary:
		push_error("Lesson %s could not be loaded" % path)
		data = {}
	loaded.emit(normalise(data))


## Tries the web server first (web builds only), then the bundled res:// copy.
func _fetch_json(path: String):
	if OS.has_feature("web"):
		var url := str(JavaScriptBridge.eval("""(function(){
			var u = new URL(%s, window.location.href);
			u.searchParams.set('t', Date.now());
			return u.href;
		})()""" % JSON.stringify(path)))
		var http := HTTPRequest.new()
		add_child(http)
		if http.request(url) == OK:
			var res: Array = await http.request_completed
			http.queue_free()
			if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
				var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
				if parsed != null:
					return parsed
		push_warning("Could not fetch %s from the server, using the bundled copy." % path)
	var res_path := path if path.begins_with("res://") else "res://" + path
	if not FileAccess.file_exists(res_path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(res_path))


## Fills in defaults so the rest of the game can trust the shape of the data.
static func normalise(d: Dictionary) -> Dictionary:
	var out := {
		"title": str(d.get("title", "Lesson Island")),
		"subject": str(d.get("subject", "")),
		"intro": str(d.get("intro", "Find the question cards to rebuild the bridge!")),
		"theme": d.get("theme", ""),
		"pages": [],
		"cards": [],
		"chests": [],
		"sweets": [],
		"prize": {"name": "Golden Star", "message": "You did it!"},
	}
	var wb = d.get("whiteboard", {})
	if wb is Dictionary:
		for p in wb.get("pages", []):
			if p is Dictionary:
				out.pages.append({"title": str(p.get("title", "")), "markdown": str(p.get("markdown", ""))})
		if out.pages.is_empty() and wb.has("markdown"):
			out.pages.append({"title": str(wb.get("title", "Lesson")), "markdown": str(wb.markdown)})
	if out.pages.is_empty():
		out.pages.append({"title": "Lesson", "markdown": "# No lesson yet\n\nAsk your teacher to upload one!"})
	var i := 0
	for q in d.get("cards", []):
		if q is Dictionary:
			out.cards.append(_question(q, "card-%d" % i))
			i += 1
	i = 0
	for q in d.get("chests", []):
		if q is Dictionary:
			var c := _question(q, "chest-%d" % i)
			c["coins"] = int(q.get("coins", 10))
			# Chest level (1 easy, 2 medium, 3 hard). Default: pairs in file order.
			c["level"] = int(q.get("level", i / 2 + 1))
			out.chests.append(c)
			i += 1
	# Sweets: bonus challenges. "kind" says where they live: "key" (the locked sweet shop)
	# or "guarded" (the ghost garden).
	i = 0
	for q in d.get("sweets", []):
		if q is Dictionary:
			var s := _question(q, "sweet-%d" % i)
			s["kind"] = str(q.get("kind", "key" if i == 0 else "guarded"))
			out.sweets.append(s)
			i += 1
	var prize = d.get("prize", {})
	if prize is Dictionary:
		out.prize.name = str(prize.get("name", out.prize.name))
		out.prize.message = str(prize.get("message", out.prize.message))
	return out


static func _question(q: Dictionary, fallback_id: String) -> Dictionary:
	var answers: Array = []
	for a in q.get("answers", []):
		answers.append(str(a))
	if q.has("answer"):
		answers.append(str(q.answer))
	var choices: Array = []
	for c in q.get("choices", []):
		choices.append(str(c))
	return {
		"id": str(q.get("id", fallback_id)),
		"question": str(q.get("question", "?")),
		"answers": answers,
		"choices": choices,
		"correct": int(q.get("correct", 0)),
		"hint": str(q.get("hint", "The whiteboard might help!")),
		"explanation": str(q.get("explanation", "")),
	}
