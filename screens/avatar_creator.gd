class_name AvatarCreator
extends Control
## "Create yourself": skin, hair, headscarf, dress, and the colours of her home.
## Used both for a new world and later from the in-world menu.

signal done

var _preview: Preview


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#f6ebe0")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	margin.add_child(box)

	box.add_child(UI.label("AVATAR_TITLE", 34, Color("#5a4660")))
	_preview = Preview.new()
	_preview.custom_minimum_size = Vector2(200, 150)
	box.add_child(_preview)

	var a: Dictionary = GameState.data.avatar
	var h: Dictionary = GameState.data.home
	_row(box, "SKIN", Palette.SKIN, a.skin, func(i: int) -> void: a.skin = i)
	_row(box, "SCARF", Palette.SCARF, a.scarf, func(i: int) -> void: a.scarf = i, true)
	_row(box, "HAIR", Palette.HAIR, a.hair, func(i: int) -> void: a.hair = i)
	_row(box, "DRESS", Palette.DRESS, a.dress, func(i: int) -> void: a.dress = i)
	_row(box, "HOME_WALLS", Palette.WALL, h.wall, func(i: int) -> void: h.wall = i)
	_row(box, "HOME_ROOF", Palette.ROOF, h.roof, func(i: int) -> void: h.roof = i)

	var finish := UI.button("DONE", func() -> void:
		GameState.save()
		done.emit())
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", UI.sb(Color("#efe1d1"), 0, Color.TRANSPARENT, 0, 12))
	finish.size_flags_horizontal = SIZE_SHRINK_CENTER
	footer.add_child(finish)
	outer.add_child(footer)


func _row(box: VBoxContainer, key: String, colors: Array, selected, setter: Callable, allow_none := false) -> void:
	box.add_child(UI.label(key, 20))
	var row := UI.swatch_row(colors, int(selected), func(i: int) -> void:
		setter.call(i)
		_preview.queue_redraw(), allow_none)
	box.add_child(row)


class Preview extends Control:
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y - 14)
		IsoDraw.ellipse(self, c, 80, 22, Color("#e8d8c4"))
		Avatar.draw(self, GameState.data.avatar, c, 2.0)
