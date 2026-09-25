class_name Marking
## The sentence builder's marker. It doesn't try to understand Spanish - it looks for the
## features an IGCSE examiner rewards, using word lists (lessons/igcse/marking_es.json):
##   tense      a verb in the tense the question asks for
##   second     a verb in a different time frame (imperfect, future, conditional, "voy a"...)
##   connective porque, sin embargo, además...
##   opinion    me encantó, lo mejor fue, creo que...
##   time       el año pasado, hace dos años, ayer...
## Plus two guards: the answer must be on topic (topic words) and long enough.

const FEATURES := ["tense", "second", "connective", "opinion", "time"]
const LABELS := {
	"tense": "Verb in the right tense",
	"second": "A second tense",
	"connective": "Connective",
	"opinion": "Opinion",
	"time": "Time phrase",
}
const TIPS := {
	"tense": "Use a verb in the %s - e.g. %s",
	"second": "Add another time frame - e.g. \"era muy bonito\" or \"el año que viene voy a volver\"",
	"connective": "Link ideas with \"porque\", \"sin embargo\" or \"además\"",
	"opinion": "Give an opinion - e.g. \"lo mejor fue...\" or \"me encantó\"",
	"time": "Say when - e.g. \"el verano pasado\" or \"hace dos años\"",
}
const TENSE_NAMES := {
	"preterite": "preterite (past)", "imperfect": "imperfect", "future": "future",
	"conditional": "conditional", "present": "present", "near_future": "near future (voy a...)",
	"perfect": "perfect (he + participle)",
}
const TENSE_EXAMPLES := {
	"preterite": "fui, visité, comí", "imperfect": "era, había, hacía", "future": "iré, visitaré",
	"conditional": "me gustaría, iría, sería", "present": "voy, juego, es", "near_future": "voy a viajar",
	"perfect": "he visitado",
}
const COLORS := {"tense": "#2e86de", "second": "#8e44ad", "connective": "#e67e22", "opinion": "#e84393", "time": "#16a085"}
const MIN_WORDS := 8

static var data := {}
static var _stripped := {}   # accent-free form -> [tenses]


static func load_data(d: Dictionary) -> void:
	data = d
	_stripped.clear()
	for tense in data.get("tenses", {}):
		for form in data.tenses[tense]:
			var s := _strip(str(form))
			if not _stripped.has(s):
				_stripped[s] = []
			if not tense in _stripped[s]:
				_stripped[s].append(tense)


## Marks `text` against a challenge {tense, topic_words, ...}.
## Returns {stars, found: {feature: [token indexes]}, tokens, missing: [features], notes: [strings], ok}
static func mark(text: String, challenge: Dictionary) -> Dictionary:
	var target := str(challenge.get("tense", "preterite"))
	var raw := _tokens(text)                  # original words (for display)
	var norm: Array[String] = []              # lower-case, accents kept
	var flat: Array[String] = []              # lower-case, accents removed
	for w in raw:
		var n := _clean(w)
		norm.append(n)
		flat.append(_strip(n))
	var found := {}
	var notes: Array[String] = []
	for f in FEATURES:
		found[f] = []

	# Verbs: tag each word with the tense(s) it belongs to.
	var tense_at := {}
	for i in norm.size():
		var t := _tenses_of(norm[i], flat[i])
		if t.size() > 0:
			tense_at[i] = t
			if not _exact_known(norm[i]):
				notes.append("Watch the accents: \"%s\" should be %s" % [_clean(raw[i]), _accent_hint(flat[i])])
	# Near future (voy a + infinitive) and perfect (he + participle) are two-word patterns.
	var infs: Array = data.get("infinitives", [])
	var parts: Array = data.get("participles", [])
	for i in norm.size() - 2:
		if (norm[i] + " " + norm[i + 1]) in data.get("near_future_aux", []) and _base_verb(flat[i + 2]) in infs:
			tense_at[i] = ["near_future"]
			tense_at[i + 2] = ["near_future"]
	for i in norm.size() - 1:
		if norm[i] in data.get("perfect_aux", []) and flat[i + 1] in parts:
			tense_at[i] = ["perfect"]
			tense_at[i + 1] = ["perfect"]
	for i in tense_at:
		var ts: Array = tense_at[i]
		if target in ts and ts.size() == 1:
			found.tense.append(i)
		elif target in ts:
			found.tense.append(i)      # ambiguous but plausible (e.g. accents left off)
		elif not "present" in ts or ts.size() > 1:
			found.second.append(i)
	# Phrase lists.
	for f in ["connective", "opinion", "time"]:
		var key: String = {"connective": "connectives", "opinion": "opinions", "time": "time_phrases"}[f]
		for phrase in data.get(key, []):
			for idx in _find_phrase(flat, _strip(str(phrase).to_lower())):
				found[f].append_array(idx)
	# "hace dos años" style.
	for i in flat.size() - 2:
		if flat[i] == "hace" and flat[i + 2].trim_suffix("s") in ["dia", "semana", "mes", "mese", "ano", "hora", "minuto"]:
			found.time.append_array([i, i + 1, i + 2])

	# Guards: on topic, long enough.
	var topic_hit := false
	for tw in challenge.get("topic_words", []):
		var stem := _strip(str(tw).to_lower())
		for w in flat:
			if w.begins_with(stem):
				topic_hit = true
	if challenge.get("topic_words", []).is_empty():
		topic_hit = true
	var words := raw.size()
	var stars := 0
	var missing: Array[String] = []
	for f in FEATURES:
		if not (found[f] as Array).is_empty():
			stars += 1
		else:
			missing.append(f)
	var ok := topic_hit and words >= MIN_WORDS
	if not topic_hit:
		notes.push_front("Is that about the question? Try to answer it directly.")
	if words < MIN_WORDS:
		notes.push_front("A bit short - write at least %d words." % MIN_WORDS)
	if not topic_hit:
		stars = 0
	elif words < MIN_WORDS:
		stars = mini(stars, 1)
	return {"stars": stars, "found": found, "tokens": raw, "missing": missing, "notes": notes, "ok": ok, "target": target}


## The student's sentence with the scoring words coloured in, as BBCode.
static func highlight(result: Dictionary) -> String:
	var colour_of := {}
	for f in FEATURES:
		for i in result.found[f]:
			if not colour_of.has(i):
				colour_of[i] = COLORS[f]
	var out := PackedStringArray()
	var toks: Array = result.tokens
	for i in toks.size():
		var w := str(toks[i]).replace("[", "[lb]")
		out.append("[color=%s][b]%s[/b][/color]" % [colour_of[i], w] if colour_of.has(i) else w)
	return " ".join(out)


static func tip(feature: String, target: String) -> String:
	if feature == "tense":
		return TIPS.tense % [TENSE_NAMES.get(target, target), TENSE_EXAMPLES.get(target, "")]
	return TIPS[feature]


# ---------------------------------------------------------------- helpers

static func _tokens(text: String) -> Array[String]:
	var out: Array[String] = []
	for w in text.replace("\n", " ").split(" ", false):
		if _clean(w) != "":
			out.append(w)
	return out


static func _clean(w: String) -> String:
	var s := ""
	for c in w.to_lower():
		if c in ".,!?;:'\"()¿¡«»-":
			continue
		s += c
	return s


static func _tenses_of(word: String, flat_word: String) -> Array:
	var out := []
	for tense in data.get("tenses", {}):
		if word in data.tenses[tense]:
			out.append(tense)
	if out.is_empty() and _stripped.has(flat_word):
		out = (_stripped[flat_word] as Array).duplicate()
	return out


static func _exact_known(word: String) -> bool:
	for tense in data.get("tenses", {}):
		if word in data.tenses[tense]:
			return true
	return false


static func _accent_hint(flat_word: String) -> String:
	var forms := []
	for tense in data.get("tenses", {}):
		for f in data.tenses[tense]:
			if _strip(str(f)) == flat_word and str(f) != flat_word:
				forms.append(f)
	return " / ".join(forms.slice(0, 2)) if forms.size() > 0 else flat_word


## "levantarme" -> "levantar" so "voy a levantarme" counts.
static func _base_verb(w: String) -> String:
	for suffix in ["me", "te", "se", "nos", "lo", "la"]:
		if w.length() > 4 and w.ends_with(suffix) and w.trim_suffix(suffix).right(2) in ["ar", "er", "ir"]:
			return w.trim_suffix(suffix)
	return w


## Every place a multi-word phrase occurs: returns [[i, i+1, ...], ...]
static func _find_phrase(flat: Array[String], phrase: String) -> Array:
	var parts := phrase.split(" ", false)
	var hits := []
	if parts.is_empty():
		return hits
	for i in flat.size() - parts.size() + 1:
		var same := true
		for k in parts.size():
			if flat[i + k] != parts[k]:
				same = false
				break
		if same:
			hits.append(range(i, i + parts.size()))
	return hits


static func _strip(s: String) -> String:
	var from := "áéíóúüñàèìòù"
	var to := "aeiouunaeiou"
	var out := s
	for i in from.length():
		out = out.replace(from[i], to[i])
	return out