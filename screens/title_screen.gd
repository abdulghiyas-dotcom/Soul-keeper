class_name TitleScreen
extends Control
## First screen: continue / create, and language choice.

signal continue_pressed
signal new_pressed

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(Color("#f3dccb"))
	Sound.set_ambience("")
	var bg := Backdrop.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	_build()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	_box = VBoxContainer.new()
	_box.custom_minimum_size.x = 360
	_box.add_theme_constant_override("separation", 14)
	center.add_child(_box)

	_box.add_child(UI.label("APP_TITLE", 52, Color("#5a4660")))
	_box.add_child(UI.label("TAGLINE", 22, Color("#7a6676")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	_box.add_child(gap)
	if GameState.has_world():
		_box.add_child(UI.button("CONTINUE", func() -> void: continue_pressed.emit()))
		_box.add_child(UI.button("START_OVER", _confirm_start_over))
	else:
		_box.add_child(UI.button("NEW_WORLD", func() -> void: new_pressed.emit()))

	var gap2 := Control.new()
	gap2.custom_minimum_size.y = 10
	_box.add_child(gap2)
	var langs := HBoxContainer.new()
	langs.alignment = BoxContainer.ALIGNMENT_CENTER
	langs.add_theme_constant_override("separation", 8)
	for lang in I18n.languages:
		var b := Button.new()
		b.text = lang.name
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # names stay in their own script
		b.custom_minimum_size = Vector2(100, 46)
		var code: String = lang.code
		b.pressed.connect(func() -> void:
			I18n.set_language(code)
			if GameState.has_world():
				GameState.save())
		langs.add_child(b)
	_box.add_child(langs)
	var snd := SoundToggle.new(180)
	snd.custom_minimum_size.y = 46
	snd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(snd)


func _confirm_start_over() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(overlay)
	UI.dim(overlay)
	var box := UI.center_panel(overlay, 380)
	box.add_child(UI.label("CONFIRM_START_OVER", 22))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("NO", overlay.queue_free, 140))
	row.add_child(UI.button("YES", func() -> void:
		GameState.reset()
		new_pressed.emit(), 140))
	box.add_child(row)


## Soft dawn sky with hills — placeholder art.
class Backdrop extends Control:
	func _draw() -> void:
		var s := size
		var top := Color("#f6d9c8")
		var bottom := Color("#d9dbef")
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
			PackedColorArray([top, top, bottom, bottom]))
		draw_circle(Vector2(s.x * 0.82, s.y * 0.12), 52, Color(1, 0.93, 0.75, 0.6), true, -1.0, true)
		draw_circle(Vector2(s.x * 0.82, s.y * 0.12), 32, Color("#fde7b0"), true, -1.0, true)
		IsoDraw.ellipse(self, Vector2(s.x * 0.2, s.y * 1.02), s.x * 0.55, s.y * 0.28, Color("#b9d3b2"), 48)
		IsoDraw.ellipse(self, Vector2(s.x * 0.85, s.y * 1.06), s.x * 0.6, s.y * 0.26, Color("#a7c9a0"), 48)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
