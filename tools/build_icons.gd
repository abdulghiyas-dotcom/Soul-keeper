extends SceneTree
## Renders icon.svg to the PNG sizes needed for "Add to Home Screen" (PWA).
## Run: godot --headless --script res://tools/build_icons.gd

func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	for px in [144, 180, 192, 512]:
		var img := Image.new()
		img.load_svg_from_string(svg, px / 128.0)
		img.save_png("res://assets/icons/icon_%d.png" % px)
		print("icon ", px, ": ", img.get_size())
	quit()
