class_name LeafButton
extends Button
## A small round button showing only a leaf: no words, nothing revealing.


func _init() -> void:
	set_meta("silent", true)  # hiding should never make a sound
	custom_minimum_size = Vector2(52, 52)
	focus_mode = FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(state, UI.sb(UI.CARD, 26, Color("#e6d9c8"), 2, 0))


func _draw() -> void:
	var c := size * 0.5
	var leaf := Color("#7fae86")
	var pts := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		pts.append(c + Vector2(lerpf(-12, 12, t), -sin(t * PI) * 9).rotated(-0.6))
	for i in range(19, 0, -1):
		var t := float(i) / 20.0
		pts.append(c + Vector2(lerpf(-12, 12, t), sin(t * PI) * 9).rotated(-0.6))
	draw_colored_polygon(pts, leaf)
	draw_line(c + Vector2(-13, 0).rotated(-0.6), c + Vector2(12, 0).rotated(-0.6), leaf.darkened(0.3), 1.5, true)
