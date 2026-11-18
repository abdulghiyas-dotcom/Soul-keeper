class_name DecorPanel
extends PanelContainer
## The decorating tray at the bottom of the screen.
## Catalog mode: pictures of things to place (no words needed).
## Item mode: actions for something she already placed.

signal kind_picked(kind: String)
signal done_pressed
signal move_pressed
signal remove_pressed
signal color_picked(index: int)
signal deselect_pressed

var _hint: Label
var _body: VBoxContainer
var _footer: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_theme_stylebox_override("panel", UI.sb(Color(1, 0.98, 0.95, 0.97), 22, Color("#eadfcf"), 2, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_hint = UI.label("DECOR_HINT", 17)
	box.add_child(_hint)
	_body = VBoxContainer.new()
	box.add_child(_body)
	_footer = HBoxContainer.new()
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.add_theme_constant_override("separation", 10)
	box.add_child(_footer)


func set_hint(key: String) -> void:
	_hint.text = key


func show_catalog(kinds: Array, selected: String) -> void:
	_clear()
	set_hint("DECOR_HINT")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 86
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	scroll.add_child(row)
	for k in kinds:
		var b := ItemButton.new()
		b.kind = k
		b.selected = k == selected
		b.pressed.connect(func() -> void: kind_picked.emit(k))
		row.add_child(b)
	_footer.add_child(UI.button("DONE", func() -> void: done_pressed.emit(), 160))
	if I18n.is_rtl():  # right-to-left: start the strip at the right-hand end
		(func() -> void: scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)).call_deferred()


func show_item(kind: String, accent: int) -> void:
	_clear()
	set_hint("DECOR_SELECTED")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var b := ItemButton.new()
	b.kind = kind
	b.disabled = true
	row.add_child(b)
	row.add_child(UI.button("MOVE", func() -> void: move_pressed.emit(), 120))
	row.add_child(UI.button("REMOVE", func() -> void: remove_pressed.emit(), 120))
	_body.add_child(row)
	if kind in Decor.ACCENTABLE:
		_body.add_child(UI.swatch_row(Palette.SCARF, accent, func(i: int) -> void: color_picked.emit(i), true))
	_footer.add_child(UI.button("DONE", func() -> void: deselect_pressed.emit(), 160))


func _clear() -> void:
	for c in _body.get_children() + _footer.get_children():
		c.queue_free()


## A square button showing a small drawing of the item itself.
class ItemButton extends Button:
	var kind := ""
	var selected := false

	func _ready() -> void:
		custom_minimum_size = Vector2(78, 78)
		focus_mode = FOCUS_NONE
		clip_contents = true
		var border := Palette.INK if selected else Color("#e6d9c8")
		for state in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(state, UI.sb(Color("#f6ecdf"), 14, border, 3 if selected else 2, 0))
		var spec := Decor.to_spec({"kind": kind, "x": 0, "y": 0}, -1)
		spec.erase("user")
		var holder := Node2D.new()
		add_child(holder)
		var s: Vector2 = spec.size
		var ob := IsoObject.new().setup(spec)
		var extent := (s.x + s.y) * 32.0
		var k := clampf(52.0 / maxf(extent, 1.0), 0.3, 0.75)
		holder.scale = Vector2(k, k)
		holder.position = Vector2(39, 60 + (s.x + s.y) * 8.0 * k - 8.0 * k)
		ob.position = Vector2.ZERO
		holder.add_child(ob)
		if Decor.is_decal(kind):
			holder.add_child(RugPreview.new())


class RugPreview extends Node2D:
	func _draw() -> void:
		var c := Color("#b5523f")
		IsoDraw.diamond(self, Iso.to_screen(Vector2(1, 1)), Vector2.ZERO, Vector2(2, 2), c)
		IsoDraw.diamond(self, Iso.to_screen(Vector2(1, 1)), Vector2(0.3, 0.3), Vector2(1.4, 1.4), c.lightened(0.25))
