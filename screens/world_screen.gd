class_name WorldScreen
extends Node
## The explorable dream world: loads a location, the avatar, the camera,
## and the small on-screen interface (menu, place name, hints).

signal exit_requested
signal hide_requested

const AUTOSAVE_SECONDS := 8.0

var map: IsoMap
var player: Player
var location := "exterior"
var _hud: CanvasLayer
var _hud_root: Control
var _overlay_layer: CanvasLayer
var _place_label: Label
var _toast: Label
var _fade: ColorRect
var _busy := false
var _current_overlay: Control = null
var _menu_btn: Button
var _decorate_btn: Button

# Decorate mode
var _editing := false
var _edit_cam: Camera2D
var _decor_panel: DecorPanel
var _pick_kind := ""
var _selected := -1
var _moving := false
var _press_pos := Vector2.ZERO
var _drag_dist := 0.0
var _autosave_t := 0.0


func _ready() -> void:
	_build_hud()
	var loc: Dictionary = GameState.data.location
	var spawn := Vector2(loc.x, loc.y)
	_load_location(str(loc.scene), spawn if spawn.x >= 0.0 else Vector2(-1, -1))
	if not GameState.data.get("seen_hint", false):
		_show_toast("HINT_MOVE", 6.0)
		GameState.data.seen_hint = true


func _process(delta: float) -> void:
	_autosave_t += delta
	if _autosave_t >= AUTOSAVE_SECONDS:
		_autosave_t = 0.0
		_save()


# --- locations ------------------------------------------------------------------

func _load_location(id: String, spawn: Vector2) -> void:
	if id == "career" and str(GameState.data.career) == "":
		id = "exterior"
		spawn = Vector2(-1, -1)
	if map:
		map.queue_free()
	location = id
	var d := WorldData.build(id, GameState.data)
	RenderingServer.set_default_clear_color(d.sky)
	map = IsoMap.new()
	map.build(d)
	add_child(map)
	move_child(map, 0)

	player = Player.new()
	player.map = map
	player.look = GameState.look()
	map.objects.add_child(player)
	var at: Vector2 = spawn if spawn.x >= 0.0 and map.is_walkable(spawn) else d.spawn
	player.place(at)
	player.entered_tile.connect(_on_tile)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.offset = Vector2(0, -30)
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()

	_place_label.text = WorldData.label_key(id, GameState.data)
	Sound.set_ambience({"exterior": "birds", "town": "birds", "hills": "stream"}.get(id, ""))
	_decorate_btn.visible = Decor.editable(id) and not _editing
	if _editing:
		player.frozen = true
		_edit_cam.make_current()
		_refresh_highlight()
	_save()


func _go(id: String, spawn: Vector2) -> void:
	if _busy:
		return
	_busy = true
	player.frozen = true
	Sound.play("door")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
	await tw.finished
	_load_location(id, spawn)
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.3)
	await tw2.finished
	_busy = false


func _on_tile(t: Vector2i) -> void:
	var door := map.door_at(t)
	match str(door.get("action", "")):
		"goto":
			_go(door.to, door.spawn)
		"pick_career":
			player.path.clear()
			# Deferred: building UI mid-movement left its buttons unclickable.
			_open_career_picker.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Esc = hide instantly
		hide_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if _editing and _current_overlay == null:
		_edit_input(event)
		return
	if _busy or player == null or player.frozen:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t := Iso.tile_of(Iso.to_grid(map.get_local_mouse_position()))
		var target := map.tap_target(t)
		if target.x >= 0 and target == Iso.tile_of(player.g) and not map.door_at(target).is_empty():
			_on_tile(target)  # already standing on this door: use it
			get_viewport().set_input_as_handled()
		elif target.x >= 0:
			player.walk_to(target)
			_tap_marker(Iso.to_screen(Iso.tile_center(target)))
			get_viewport().set_input_as_handled()


func _save() -> void:
	if player:
		GameState.data.location = {"scene": location, "x": player.g.x, "y": player.g.y}
	GameState.save()


# --- interface ----------------------------------------------------------------

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)

	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_right = -16
	bar.offset_top = 14
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	var place := PanelContainer.new()
	place.add_theme_stylebox_override("panel", UI.sb(Color(1, 0.98, 0.95, 0.85), 20, Color.TRANSPARENT, 0, 10))
	place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_label = UI.label("PLACE_GARDEN", 20)
	_place_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	place.add_child(_place_label)
	bar.add_child(place)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	var hide_btn := LeafButton.new()
	hide_btn.pressed.connect(func() -> void: hide_requested.emit())
	bar.add_child(hide_btn)
	var gap := Control.new()
	gap.custom_minimum_size.x = 8
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(gap)
	_decorate_btn = UI.button("DECORATE", _enter_edit, 110)
	bar.add_child(_decorate_btn)
	var gap2 := Control.new()
	gap2.custom_minimum_size.x = 8
	gap2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(gap2)
	_menu_btn = UI.button("MENU", _open_menu, 110)
	bar.add_child(_menu_btn)

	_toast = UI.label("", 20)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -24
	_toast.custom_minimum_size.x = 400
	_toast.add_theme_stylebox_override("normal", UI.sb(Color(1, 0.98, 0.95, 0.9), 18, Color.TRANSPARENT, 0, 12))
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)

	_hud_root = root

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 5
	add_child(_overlay_layer)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(Palette.SKY_INSIDE, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


func _show_toast(key: String, seconds := 2.0) -> void:
	_toast.text = key
	# While decorating, the tray covers the bottom, so messages show at the top.
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP if _editing else Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_END if _editing else Control.GROW_DIRECTION_BEGIN
	if _editing:
		_toast.offset_top = 84
	else:
		_toast.offset_bottom = -24
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _tap_marker(at: Vector2) -> void:
	var m := TapMarker.new()
	m.position = at
	map.add_child(m)


func _overlay() -> Control:
	_close_overlay()
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.add_child(c)
	_current_overlay = c
	player.frozen = true
	UI.dim(c)
	return c


func _close_overlay() -> void:
	if _current_overlay:
		_current_overlay.queue_free()
		_current_overlay = null
	if player:
		player.frozen = false


func _open_menu() -> void:
	if _busy or _current_overlay:
		return
	var o := _overlay()
	var box := UI.center_panel(o, 380)
	box.add_child(UI.label("MENU", 28))
	box.add_child(UI.button("EDIT_LOOK", func() -> void:
		_close_overlay()
		_open_avatar_editor()))
	box.add_child(UI.button("CHOOSE_WORKPLACE", func() -> void:
		_close_overlay()
		_open_career_picker()))
	box.add_child(UI.button("PRIVACY", func() -> void:
		_close_overlay()
		_open_privacy()))
	box.add_child(SoundToggle.new())
	var langs := HBoxContainer.new()
	langs.alignment = BoxContainer.ALIGNMENT_CENTER
	langs.add_theme_constant_override("separation", 8)
	for lang in I18n.languages:
		var b := Button.new()
		b.text = lang.name
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(90, 46)
		var code: String = lang.code
		b.pressed.connect(func() -> void: I18n.set_language(code))
		langs.add_child(b)
	box.add_child(langs)
	box.add_child(UI.button("SAVE_EXIT", func() -> void:
		_save()
		exit_requested.emit()))
	box.add_child(UI.button("CLOSE", _close_overlay))


func _open_privacy() -> void:
	var o := _overlay()
	var box := UI.center_panel(o, 380)
	box.add_child(UI.label("PRIVACY", 28))
	box.add_child(UI.label("PIN_INFO", 19))
	var has := Privacy.has_pin()
	box.add_child(UI.button("CHANGE_PIN" if has else "SET_PIN", func() -> void:
		_open_pin_setup(PinSetup.Mode.SET)))
	if has:
		box.add_child(UI.button("REMOVE_PIN", func() -> void:
			_open_pin_setup(PinSetup.Mode.REMOVE)))
	box.add_child(UI.button("CLOSE", _close_overlay))


func _open_pin_setup(mode: PinSetup.Mode) -> void:
	var o := _overlay()
	var box := UI.center_panel(o, 360)
	var setup := PinSetup.new()
	setup.mode = mode
	box.add_child(setup)
	setup.finished.connect(func(msg: String) -> void:
		_close_overlay()
		if msg != "":
			Sound.play("chime")
			_show_toast(msg))


func _open_avatar_editor() -> void:
	var o := _overlay()
	var editor := AvatarCreator.new()
	o.add_child(editor)
	editor.done.connect(func() -> void:
		_close_overlay()
		_reload_here()
		_show_toast("SAVED"))


func _open_career_picker() -> void:
	if _current_overlay:
		return
	var o := _overlay()
	var box := UI.center_panel(o, 420)
	box.add_child(UI.label("WORKPLACE_PROMPT", 22))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for c in WorldData.CAREERS:
		var id: String = c.id
		var b := UI.button(c.key, func() -> void:
			GameState.data.career = id
			Sound.play("chime")
			_close_overlay()
			_reload_here()
			_show_toast(c.key), 180)
		var col: Color = c.color
		b.add_theme_stylebox_override("normal", UI.sb(col.lightened(0.7), 16, col, 3))
		b.add_theme_stylebox_override("hover", UI.sb(col.lightened(0.55), 16, col, 3))
		if id == str(GameState.data.career):
			b.add_theme_stylebox_override("normal", UI.sb(col.lightened(0.45), 16, Palette.INK, 3))
		grid.add_child(b)
	box.add_child(grid)
	box.add_child(UI.button("CLOSE", _close_overlay))


func _reload_here() -> void:
	_load_location(location, player.g)


# --- decorate mode ------------------------------------------------------------

func _enter_edit() -> void:
	if _busy or _current_overlay or not Decor.editable(location):
		return
	_editing = true
	_pick_kind = ""
	_selected = -1
	_moving = false
	player.frozen = true
	player.path.clear()
	_decorate_btn.visible = false
	_menu_btn.visible = false
	_edit_cam = Camera2D.new()
	_edit_cam.position = player.position + Vector2(0, 40)  # a little lower: the tray covers the bottom
	add_child(_edit_cam)
	_edit_cam.make_current()
	_decor_panel = DecorPanel.new()
	_hud_root.add_child(_decor_panel)
	_decor_panel.kind_picked.connect(func(k: String) -> void:
		_pick_kind = "" if k == _pick_kind else k
		_show_catalog())
	_decor_panel.done_pressed.connect(_exit_edit)
	_decor_panel.deselect_pressed.connect(_deselect)
	_decor_panel.move_pressed.connect(func() -> void:
		_moving = true
		_decor_panel.set_hint("MOVE_HINT"))
	_decor_panel.remove_pressed.connect(_remove_selected)
	_decor_panel.color_picked.connect(func(i: int) -> void:
		_items()[_selected].accent = i
		_reload_here())
	_show_catalog()


func _exit_edit() -> void:
	_editing = false
	_decor_panel.queue_free()
	_edit_cam.queue_free()
	_menu_btn.visible = true
	_decorate_btn.visible = true
	map.set_highlight([])
	player.frozen = false
	player.get_child(0).make_current()
	_save()


func _items() -> Array:
	return GameState.decor(Decor.key(location, GameState.data))


func _show_catalog() -> void:
	_selected = -1
	_moving = false
	_decor_panel.show_catalog(Decor.catalog(location), _pick_kind)
	_refresh_highlight()


func _deselect() -> void:
	_show_catalog()


func _refresh_highlight() -> void:
	if _selected >= 0:
		map.set_highlight(map.user_tiles(_selected), Color("#fff6c8"))
	else:
		map.set_highlight([])


func _edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
			_drag_dist = 0.0
		elif _drag_dist < 12.0:
			_edit_tap(Iso.tile_of(Iso.to_grid(map.get_local_mouse_position())))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_drag_dist += event.relative.length()
		if _drag_dist >= 12.0:
			_edit_cam.position -= event.relative / _edit_cam.zoom
			var lo := Iso.to_screen(Vector2(0, map.size.y))
			var hi := Iso.to_screen(Vector2(map.size.x, 0))
			_edit_cam.position = _edit_cam.position.clamp(Vector2(lo.x, -60), Vector2(hi.x, Iso.to_screen(Vector2(map.size)).y))
		get_viewport().set_input_as_handled()


func _edit_tap(tile: Vector2i) -> void:
	var items := _items()
	if _moving and _selected >= 0:
		var item: Dictionary = items[_selected]
		var err := _can_place(str(item.kind), tile, _selected)
		if err != "":
			_show_toast(err)
			return
		item.x = tile.x
		item.y = tile.y
		Sound.play("place", 0.0, 0.1)
		var keep := _selected
		_reload_here()
		_selected = keep
		_moving = false
		_decor_panel.show_item(str(item.kind), int(item.get("accent", -1)))
		_refresh_highlight()
	elif _pick_kind != "":
		if items.size() >= Decor.MAX_ITEMS:
			_show_toast("TOO_MANY")
			return
		var err := _can_place(_pick_kind, tile, -1)
		if err != "":
			_show_toast(err)
			return
		items.append({"kind": _pick_kind, "x": tile.x, "y": tile.y, "accent": -1})
		Sound.play("place", 0.0, 0.1)
		_reload_here()
	elif map.user_at.has(tile):
		_selected = map.user_at[tile]
		var item: Dictionary = items[_selected]
		_decor_panel.show_item(str(item.kind), int(item.get("accent", -1)))
		_refresh_highlight()


func _remove_selected() -> void:
	if _selected < 0:
		return
	_items().remove_at(_selected)
	Sound.play("remove")
	_selected = -1
	_reload_here()
	_show_catalog()


## "" if the item can go on `tile`, otherwise the message key explaining why not.
## `ignore` is the index of the item being moved (its own tiles count as free).
func _can_place(kind: String, tile: Vector2i, ignore: int) -> String:
	var freed := {}
	if ignore >= 0:
		for t in map.user_tiles(ignore):
			freed[t] = true
	var tiles := Decor.footprint(tile, kind)
	var here := Iso.tile_of(player.g)
	for t in tiles:
		if not map.in_bounds(t) or not map.door_at(t).is_empty() or map.keep_clear.has(t):
			return "BLOCKED_SPOT"
		if Decor.is_decal(kind):
			continue
		if t == here or (map.solid.has(t) and not freed.has(t)):
			return "BLOCKED_SPOT"
	if Decor.is_decal(kind):
		for t in tiles:  # one rug per spot
			if map.user_at.has(t) and map.user_at[t] != ignore and Decor.is_decal(str(_items()[map.user_at[t]].kind)):
				return "BLOCKED_SPOT"
		return ""
	var extra := {}
	for t in tiles:
		extra[t] = true
	if not map.keeps_paths_open(extra, freed, here):
		return "BLOCKS_PATH"
	return ""


class TapMarker extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t > 0.5:
			queue_free()

	func _draw() -> void:
		var k := t / 0.5
		var r := 8.0 + 14.0 * k
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1, 1, 1, 0.8 * (1.0 - k)), 2.0)
