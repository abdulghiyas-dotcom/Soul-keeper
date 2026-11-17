class_name PrivacyLayer
extends CanvasLayer
## Sits above everything. Shows the PIN lock screen or the neutral
## "garden notes" cover screen, and pauses the world underneath.

signal started_over

var _screen: Control


func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS
	Privacy.lock_requested.connect(lock)


func is_active() -> bool:
	return _screen != null


func lock() -> void:
	if not Privacy.has_pin():
		return
	var s := _new_screen()
	var box := _centered(s)
	box.add_child(UI.label("APP_TITLE", 30, Color("#5a4660")))
	var pad := PinPad.new()
	box.add_child(pad)
	pad.entered.connect(func(pin: String) -> void:
		if Privacy.check_pin(pin):
			unlock()
		else:
			pad.show_message("PIN_WRONG")
			_shake(pad))
	var forgot := UI.button("FORGOT_PIN", _confirm_forgot, 220)
	forgot.flat = true
	forgot.add_theme_font_size_override("font_size", 18)
	forgot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(forgot)


## Instantly cover the screen with neutral gardening notes.
func hide_now() -> void:
	var s := _new_screen()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	s.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var head := HBoxContainer.new()
	var leaf := LeafButton.new()
	leaf.pressed.connect(func() -> void:
		if Privacy.has_pin():
			lock()
		else:
			unlock())
	head.add_child(leaf)
	var title := UI.label("NOTES_TITLE", 28, Color("#4d6b52"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	box.add_child(head)
	for i in range(1, 6):
		var tip := PanelContainer.new()
		var l := UI.label("TIP_%d" % i, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tip.add_child(l)
		box.add_child(tip)


func unlock() -> void:
	if _screen:
		_screen.queue_free()
		_screen = null
	get_tree().paused = false


func _new_screen() -> Control:
	if _screen:
		_screen.queue_free()
	get_tree().paused = true
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_screen)
	var bg := ColorRect.new()
	bg.color = Color("#f4efe4")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(bg)
	return _screen


func _centered(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	return box


func _confirm_forgot() -> void:
	var o := Control.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(o)
	UI.dim(o)
	var box := UI.center_panel(o, 380)
	box.add_child(UI.label("FORGOT_PIN_INFO", 21))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("CANCEL", o.queue_free, 140))
	row.add_child(UI.button("START_OVER", func() -> void:
		GameState.reset()
		unlock()
		started_over.emit(), 160))
	box.add_child(row)


func _shake(n: Control) -> void:
	var x := n.position.x
	var tw := create_tween()
	for dx in [-10.0, 10.0, -6.0, 6.0, 0.0]:
		tw.tween_property(n, "position:x", x + dx, 0.05)
