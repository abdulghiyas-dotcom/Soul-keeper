extends SceneTree
## Regenerates res://assets/theme.tres from UI.make_theme().
## Run: godot --headless --script res://tools/build_theme.gd

func _init() -> void:
	var ui = load("res://scripts/ui.gd")
	if ui == null or not ui.can_instantiate():
		push_error("build_theme: scripts/ui.gd failed to load")
		quit(1)
		return
	var err := ResourceSaver.save(ui.make_theme(), "res://assets/theme.tres")
	print("theme saved: ", error_string(err))
	quit(0 if err == OK else 1)
