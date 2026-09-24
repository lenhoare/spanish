class_name Markdown
## Converts a practical subset of Markdown into Godot BBCode for RichTextLabel.
## Supports: headings, bold, italic, strikethrough, inline code, code blocks,
## bullet and numbered lists, block quotes, horizontal rules, tables and links.

const H_COLORS := ["#e0457b", "#5a4fcf", "#2b8a8a"]
const H_SIZES := [40, 32, 27]
const CODE_BG := "#eef0f6"
const QUOTE_COLOR := "#6b5b95"


static func to_bbcode(md: String, scale := 1.0) -> String:
	return "\n".join(to_blocks(md, scale))


## Converts to a list of BBCode blocks (one per paragraph, list, table, heading...),
## so the lesson viewer can split long lessons into pages without cutting a block in half.
## `scale` shrinks/grows heading sizes to match the body text scale.
static func to_blocks(md: String, scale := 1.0) -> PackedStringArray:
	# Some exported notes contain broken LaTeX arrows ("$ightarrow$", "$\rightarrow$").
	md = md.replace("$\\rightarrow$", "->").replace("$ightarrow$", "->").replace("$\\to$", "->")
	var lines := md.replace("\r\n", "\n").split("\n")
	var out := PackedStringArray()
	var i := 0
	while i < lines.size():
		var line: String = lines[i]
		var s := line.strip_edges()

		# Fenced code block
		if s.begins_with("```"):
			var code := PackedStringArray()
			i += 1
			while i < lines.size() and not lines[i].strip_edges().begins_with("```"):
				code.append(_escape(lines[i]))
				i += 1
			i += 1
			out.append("[bgcolor=%s][code]%s[/code][/bgcolor]" % [CODE_BG, "\n".join(code)])
			continue

		# Table: header row followed by |---|---|
		if s.begins_with("|") and i + 1 < lines.size() and _is_table_rule(lines[i + 1]):
			var rows: Array = [_table_cells(s)]
			i += 2
			while i < lines.size() and lines[i].strip_edges().begins_with("|"):
				rows.append(_table_cells(lines[i].strip_edges()))
				i += 1
			out.append(_table(rows))
			continue

		# Lists (consecutive items grouped together)
		if _bullet_text(s) != null or _number_text(s) != null:
			var numbered := _number_text(s) != null
			var items := PackedStringArray()
			while i < lines.size():
				var t = _number_text(lines[i].strip_edges()) if numbered else _bullet_text(lines[i].strip_edges())
				if t == null:
					break
				items.append(_inline(t))
				i += 1
			var tag := "ol type=1" if numbered else "ul"
			out.append("[%s]%s[/%s]" % [tag, "\n".join(items), tag.split(" ")[0]])
			continue

		# Block quote (consecutive > lines)
		if s.begins_with(">"):
			var q := PackedStringArray()
			while i < lines.size() and lines[i].strip_edges().begins_with(">"):
				q.append(_inline(lines[i].strip_edges().substr(1).strip_edges()))
				i += 1
			out.append("[indent][color=%s][b]|[/b]  %s[/color][/indent]" % [QUOTE_COLOR, "\n[b]|[/b]  ".join(q)])
			continue

		if s == "---" or s == "***" or s == "___":
			out.append("[center][color=#c9c3dc]- - - - - - - - - - - - - - - -[/color][/center]")
			i += 1
			continue

		var h := 0
		while h < s.length() and s[h] == "#":
			h += 1
		if h > 0 and h <= 6 and s.length() > h and s[h] == " ":
			var lvl := mini(h, 3) - 1
			out.append("[font_size=%d][b][color=%s]%s[/color][/b][/font_size]" % [int(H_SIZES[lvl] * scale), H_COLORS[lvl], _inline(s.substr(h + 1))])
			i += 1
			continue

		out.append(_inline(line))
		i += 1
	return out


static func is_heading(block: String) -> bool:
	return block.begins_with("[font_size=")


## Plain text version (used on the 3D whiteboard preview).
static func to_plain(md: String) -> String:
	var bb := to_bbcode(md)
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(bb, "", true).replace("[lb]", "[")


static func _escape(s: String) -> String:
	return s.replace("[", "[lb]")


static func _inline(s: String) -> String:
	# Pull out inline code first so its contents are left alone.
	var codes := PackedStringArray()
	var re_code := RegEx.new()
	re_code.compile("`([^`]+)`")
	var m := re_code.search(s)
	while m:
		codes.append(m.get_string(1))
		s = s.substr(0, m.get_start()) + "\u0001%d\u0001" % (codes.size() - 1) + s.substr(m.get_end())
		m = re_code.search(s)

	s = _escape(s)
	s = _sub(s, "\\[lb\\]([^\\]]+)\\]\\(([^)]+)\\)", "[color=#3a7bd5][u]$1[/u][/color]")
	s = _sub(s, "\\*\\*(.+?)\\*\\*", "[b]$1[/b]")
	s = _sub(s, "__(.+?)__", "[b]$1[/b]")
	s = _sub(s, "(?<![\\w*])\\*(?!\\s)(.+?)(?<!\\s)\\*(?![\\w*])", "[i]$1[/i]")
	s = _sub(s, "(?<![\\w_])_(?!\\s)(.+?)(?<!\\s)_(?![\\w_])", "[i]$1[/i]")
	s = _sub(s, "~~(.+?)~~", "[s]$1[/s]")
	s = s.replace("->", "→").replace("<-", "←")

	for idx in codes.size():
		s = s.replace("\u0001%d\u0001" % idx, "[bgcolor=%s][code]%s[/code][/bgcolor]" % [CODE_BG, _escape(codes[idx])])
	return s


static func _sub(s: String, pattern: String, repl: String) -> String:
	var re := RegEx.new()
	re.compile(pattern)
	return re.sub(s, repl, true)


static func _bullet_text(s: String):
	if s.length() > 2 and (s.begins_with("- ") or s.begins_with("* ") or s.begins_with("+ ")):
		return s.substr(2)
	return null


static func _number_text(s: String):
	var re := RegEx.new()
	re.compile("^\\d+[.)]\\s+(.*)$")
	var m := re.search(s)
	return m.get_string(1) if m else null


static func _is_table_rule(line: String) -> bool:
	var s := line.strip_edges()
	if not s.begins_with("|"):
		return false
	for c in s:
		if not c in "|-: ":
			return false
	return s.contains("-")


static func _table_cells(s: String) -> PackedStringArray:
	var t := s.strip_edges()
	if t.begins_with("|"):
		t = t.substr(1)
	if t.ends_with("|"):
		t = t.substr(0, t.length() - 1)
	var cells := PackedStringArray()
	for c in t.split("|"):
		cells.append(c.strip_edges())
	return cells


static func _table(rows: Array) -> String:
	var cols: int = rows[0].size()
	var bb := "[table=%d]" % cols
	for r in rows.size():
		for c in cols:
			var txt: String = _inline(rows[r][c]) if c < rows[r].size() else ""
			if r == 0:
				bb += "[cell bg=#5a4fcf padding=10,6,10,6][color=white][b]%s[/b][/color][/cell]" % txt
			else:
				var bg := "#f6f3ff" if r % 2 == 1 else "#ffffff"
				bb += "[cell bg=%s padding=10,6,10,6]%s[/cell]" % [bg, txt]
	return bb + "[/table]"
