extends Node
## Modular localization.
## Languages are listed in res://localization/languages.json, and each one has
## its own <code>.json file of KEY -> text. Adding a language never needs code.

signal language_changed(code: String)

const DIR := "res://localization/"

var languages: Array = []   # [{code, name, rtl}]
var default_code := "en"
var current := ""


func _ready() -> void:
	var manifest: Dictionary = _read_json(DIR + "languages.json")
	languages = manifest.get("languages", [])
	default_code = manifest.get("default", "en")
	for lang in languages:
		var strings: Dictionary = _read_json(DIR + str(lang.code) + ".json")
		var t := Translation.new()
		t.locale = lang.code
		for key in strings:
			t.add_message(key, str(strings[key]))
		TranslationServer.add_translation(t)
	set_language(default_code)


func set_language(code: String) -> void:
	if find(code).is_empty():
		code = default_code
	current = code
	TranslationServer.set_locale(code)
	get_tree().root.set_layout_direction(
		Window.LAYOUT_DIRECTION_RTL if is_rtl() else Window.LAYOUT_DIRECTION_LTR)
	language_changed.emit(code)


func is_rtl() -> bool:
	return bool(find(current).get("rtl", false))


func find(code: String) -> Dictionary:
	for lang in languages:
		if lang.code == code:
			return lang
	return {}


func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("I18n: cannot open " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
