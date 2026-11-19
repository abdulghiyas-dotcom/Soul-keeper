class_name TitleScreen
extends Control
## First screen: continue / create, and language choice.

signal continue_pressed
signal new_pressed

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Sound.set_ambience("")
	_build_backdrop()
	_build()
	var snd := SoundButton.new()
	snd.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	snd.offset_left = -68
	snd.offset_top = 16
	snd.offset_right = -16
	add_child(snd)


var _orbit: Node3D
var _t := 0.0


## Her garden (or a fresh one), slowly turning behind the menu.
func _build_backdrop() -> void:
	var state: Dictionary = GameState.data if GameState.has_world() else GameState.default_data()
	var view := WorldView.new()
	view.build(MapGrid.new().build(WorldData.build("exterior", state)))
	add_child(view)
	_orbit = Node3D.new()
	_orbit.position = Vector3(9, 0, 8)
	view.add_child(_orbit)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.near = 0.5
	cam.far = 120.0
	_orbit.add_child(cam)
	cam.position = Vector3(0, 13, 17)
	cam.look_at(_orbit.position + Vector3(0, -1.5, 0), Vector3.UP)
	cam.make_current()


func _process(delta: float) -> void:
	if _orbit:
		_t += delta
		_orbit.rotation.y = 0.6 + sin(_t * 0.08) * 0.5
		var vp := get_viewport().get_visible_rect().size
		(_orbit.get_child(0) as Camera3D).keep_aspect = Camera3D.KEEP_WIDTH if vp.x < vp.y else Camera3D.KEEP_HEIGHT


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.sb(Color(1, 0.98, 0.95, 0.82), 28, Color(1, 1, 1, 0.6), 2, 26))
	center.add_child(card)
	_box = VBoxContainer.new()
	_box.custom_minimum_size.x = 340
	_box.add_theme_constant_override("separation", 14)
	card.add_child(_box)

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
