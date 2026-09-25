extends SceneTree
## Dev tool: checks the sentence marker against example answers.
## godot --headless --path . --script res://tools/test_marking.gd

const CASES := [
	["Fui a España.", 1],
	["El año pasado fui a España con mi familia.", 2],
	["El año pasado fui a España con mi familia porque me encanta el sol.", 4],
	["El año pasado fui a España con mi familia y lo mejor fue la playa. Sin embargo el hotel era muy ruidoso.", 5],
	["Hace dos años visité Italia con mis amigos y comimos mucha pizza, pero llovió mucho.", 3],
	["El verano pasado fuimos a la playa y el año que viene voy a volver porque me encantó.", 5],
	["me gusta el fútbol porque es divertido y juego todos los dias", 0],
	["El ano pasado visite Francia y lo pase bomba porque hacia sol", 5],
]
const Q := {"tense": "preterite", "topic_words": ["vacacion", "españa", "italia", "francia", "playa", "hotel", "viaj", "fui", "fuimos", "visit"]}


func _init() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://lessons/igcse/marking_es.json"))
	Marking.load_data(d)
	var fails := 0
	for c in CASES:
		var r: Dictionary = Marking.mark(c[0], Q)
		var feats := []
		for f in Marking.FEATURES:
			if not (r.found[f] as Array).is_empty():
				feats.append(f)
		var ok: bool = r.stars == c[1]
		if not ok:
			fails += 1
		print("%s %d* (want %d) %s | %s | notes: %s" % ["OK  " if ok else "FAIL", r.stars, c[1], feats, c[0], r.notes])
	print("MARKING: %d / %d as expected" % [CASES.size() - fails, CASES.size()])
	quit()
