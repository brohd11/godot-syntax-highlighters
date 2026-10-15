extends SceneTree
## Multiline entry states must follow TextEdit edits, not only explicit cache clears.
## Headless: godot --headless --path . --script res://addons/_lib/syntax_highlighters/_export_ignore/test/multiline_cache_test.gd
## Editor console: `test res://addons/_lib/syntax_highlighters/_export_ignore/test`.

const IniHighlighter = preload("res://addons/_lib/syntax_highlighters/src/text/types/ini_highlighter.gd")
const MarkdownHighlighter = preload("res://addons/_lib/syntax_highlighters/src/text/types/markdown_highlighter.gd")
const Palette = preload("res://addons/_lib/syntax_highlighters/src/text/palette.gd")
static var checks := 0
static var failures := 0
static var output:Array[String] = []


# quit() lives only here so run_tests() is safe to call from the editor console.
func _initialize() -> void:
	_run_headless.call_deferred()


func _run_headless() -> void:
	var res = run_tests()
	print("\n".join(res.output))
	quit(0 if res.result == 0 else 1)


## Returns {result: failure count, output: report lines}.
static func run_tests() -> Dictionary:
	checks = 0
	failures = 0
	output = []
	_run()
	return {"result": failures, "output": output}


static func check(condition:bool, label:String) -> void:
	checks += 1
	if not condition:
		failures += 1
		output.append("FAIL: " + label)


static func color_at(logic, line:int, column:int) -> Color:
	var map:Dictionary = logic.get_line_highlighting(line)
	return map[column].color if map.has(column) else Color.TRANSPARENT


static func _run() -> void:
	var palette := Palette.new()
	var edit := TextEdit.new()

	# The reported case: Enter between "[]" in a .cfg value.
	var ini = IniHighlighter.new()
	edit.text = "my_val=[]\nfoo=1"
	ini.setup(edit, palette)
	check(color_at(ini, 1, 0) == palette.key, "ini: warm cache sees foo as a key")
	edit.insert_text("\n", 0, 8)
	check(color_at(ini, 1, 0) == palette.bracket, "ini: inserted line continues the open value")
	check(color_at(ini, 2, 0) == palette.key, "ini: line after the closing bracket is a key again")
	edit.remove_text(0, 8, 1, 0)
	check(color_at(ini, 1, 0) == palette.key, "ini: removing the line restores the key")
	edit.text = "a=[\n]"
	check(color_at(ini, 1, 0) == palette.bracket, "ini: replacing the whole text invalidates")

	# A second grammar, edited above an already cached line.
	var md = MarkdownHighlighter.new()
	edit.text = "intro\nplain"
	md.setup(edit, palette)
	check(color_at(md, 1, 0) != palette.code, "markdown: plain line before the fence opens")
	edit.set_line(0, "```")
	check(color_at(md, 1, 0) == palette.code, "markdown: opening a fence above recolors the line")

	# Rebinding must not leave the old TextEdit driving this instance.
	var other := TextEdit.new()
	other.text = "x=1\ny=2"
	ini.setup(other, palette)
	check(not edit.lines_edited_from.is_connected(ini._on_lines_edited_from), "setup disconnects the previous TextEdit")
	check(other.lines_edited_from.is_connected(ini._on_lines_edited_from), "setup connects the new TextEdit")

	other.free()
	edit.free()
	output.append("SyntaxHighlighters multiline cache: %d checks, %d failures" % [checks, failures])
