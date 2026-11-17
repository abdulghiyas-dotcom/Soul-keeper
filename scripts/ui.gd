class_name UI
extends RefCounted
## Shared look & feel for menus: soft, rounded, warm. Builds the global
## Theme and small helpers so screens stay short.

const FONT_PATH := "res://assets/fonts/Vazirmatn-Medium.ttf"
const CARD := Color("#fffaf3")
const ACCENT := Color("#7fae86")


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = load(FONT_PATH)
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", sb(CARD, 16, Color("#e6d9c8")))
	t.set_stylebox("hover", "Button", sb(Color("#fff3e3"), 16, Color("#d9c4a8")))
	t.set_stylebox("pressed", "Button", sb(Color("#f3e3cc"), 16, Color("#c9ae8c")))
	t.set_stylebox("focus", "Button", sb(Color(0, 0, 0, 0), 16, ACCENT, 2))
	t.set_stylebox("disabled", "Button", sb(Color("#eee8e0"), 16, Color("#e0d8cc")))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", Palette.INK)
	t.set_stylebox("panel", "PanelContainer", sb(Color(1, 0.98, 0.95, 0.97), 24, Color("#eadfcf"), 2, 22))
	t.set_color("font_color", "Label", Palette.INK)
	return t


static func sb(bg: Color, radius := 16, border := Color.TRANSPARENT, bw := 2, pad := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw if border.a > 0 else 0)
	s.content_margin_left = pad + 6
	s.content_margin_right = pad + 6
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


static func label(key: String, font_size := 22, color := Palette.INK) -> Label:
	var l := Label.new()
	l.text = key  # translated automatically, and again on language change
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(key: String, on_press: Callable, min_w := 260) -> Button:
	var b := Button.new()
	b.text = key
	b.custom_minimum_size = Vector2(min_w, 56)
	b.pressed.connect(on_press)
	return b


## A row of round colour swatches. `allow_none` adds a "none" option (index -1).
static func swatch_row(colors: Array, selected: int, on_pick: Callable, allow_none := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var buttons: Array[Button] = []
	var indices: Array[int] = []
	if allow_none:
		indices.append(-1)
	for i in colors.size():
		indices.append(i)
	for idx in indices:
		var b := Button.new()
		b.custom_minimum_size = Vector2(42, 42)
		b.focus_mode = Control.FOCUS_NONE
		if idx < 0:
			b.text = "–"
		var col: Color = CARD if idx < 0 else colors[idx]
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, sb(col, 23, Color("#e6d9c8"), 2, 0))
		b.set_meta("idx", idx)
		b.set_meta("col", col)
		buttons.append(b)
		row.add_child(b)
		b.pressed.connect(func() -> void:
			_mark(buttons, idx)
			on_pick.call(idx))
	_mark(buttons, selected)
	return row


static func _mark(buttons: Array[Button], selected: int) -> void:
	for b in buttons:
		var on: bool = b.get_meta("idx") == selected
		var col: Color = b.get_meta("col")
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, sb(col, 23, Palette.INK if on else Color("#e6d9c8"), 4 if on else 2, 0))


static func center_panel(parent: Control, min_w := 420) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_w
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box


static func dim(parent: Control) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.2, 0.17, 0.22, 0.45)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)
	return r
