class_name SoundButton
extends Button
## Round speaker button for the top bar: tap to turn sound on or off.
## Shows sound waves when on and a cross when off. Saved on the device.


func _init() -> void:
	custom_minimum_size = Vector2(52, 52)
	focus_mode = FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(state, UI.sb(UI.CARD, 26, Color("#e6d9c8"), 2, 0))


func _ready() -> void:
	pressed.connect(func() -> void:
		Sound.set_enabled(not Sound.enabled())
		queue_redraw())


func _draw() -> void:
	var c := size * 0.5 + Vector2(-5, 0)
	var ink := Palette.INK
	draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -5), c + Vector2(-3, -5), c + Vector2(5, -12),
		c + Vector2(5, 12), c + Vector2(-3, 5), c + Vector2(-9, 5)]), ink)
	if Sound.enabled():
		draw_arc(c + Vector2(6, 0), 7, -0.9, 0.9, 10, ink, 2.2, true)
		draw_arc(c + Vector2(6, 0), 12, -0.9, 0.9, 12, ink, 2.2, true)
	else:
		draw_line(c + Vector2(10, -6), c + Vector2(20, 6), Color("#b5523f"), 2.6, true)
		draw_line(c + Vector2(20, -6), c + Vector2(10, 6), Color("#b5523f"), 2.6, true)
