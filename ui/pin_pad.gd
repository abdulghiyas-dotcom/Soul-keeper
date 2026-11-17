class_name PinPad
extends VBoxContainer
## A phone-style number pad for entering a 4-digit PIN.
## Shows Persian digits when the language is Dari or Pashto.

signal entered(pin: String)

const PERSIAN := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

var _title: Label
var _dots: Dots
var _msg: Label
var _pin := ""


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	alignment = ALIGNMENT_CENTER
	_title = UI.label("ENTER_PIN", 24)
	add_child(_title)
	_dots = Dots.new()
	_dots.custom_minimum_size = Vector2(160, 28)
	_dots.size_flags_horizontal = SIZE_SHRINK_CENTER
	add_child(_dots)
	_msg = UI.label("", 18, Color("#b5523f"))
	add_child(_msg)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.layout_direction = LAYOUT_DIRECTION_LTR  # keypads read left-to-right everywhere
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	for d in [1, 2, 3, 4, 5, 6, 7, 8, 9, -1, 0, -2]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(76, 60)
		b.focus_mode = FOCUS_NONE
		if d == -1:
			b.disabled = true
			b.modulate.a = 0.0
		elif d == -2:
			b.text = "DELETE"
			b.add_theme_font_size_override("font_size", 17)
			b.pressed.connect(_backspace)
		else:
			b.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
			b.text = _digit(d)
			b.add_theme_font_size_override("font_size", 28)
			b.pressed.connect(_press.bind(d))
		grid.add_child(b)
	add_child(grid)
	I18n.language_changed.connect(func(_c: String) -> void: _relabel(grid))
	_refresh()


func set_title(key: String) -> void:
	_title.text = key


func show_message(key: String) -> void:
	_msg.text = key


func clear() -> void:
	_pin = ""
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.pressed:
		return
	var k: int = event.physical_keycode
	if k >= KEY_0 and k <= KEY_9:
		_press(k - KEY_0)
	elif k >= KEY_KP_0 and k <= KEY_KP_9:
		_press(k - KEY_KP_0)
	elif k == KEY_BACKSPACE:
		_backspace()
	else:
		return
	get_viewport().set_input_as_handled()


func _press(d: int) -> void:
	if _pin.length() >= Privacy.PIN_LENGTH:
		return
	_pin += str(d)
	_msg.text = ""
	_refresh()
	if _pin.length() == Privacy.PIN_LENGTH:
		var done := _pin
		await get_tree().create_timer(0.15, true).timeout
		_pin = ""
		_refresh()
		entered.emit(done)


func _backspace() -> void:
	_pin = _pin.left(-1) if _pin.length() > 0 else ""
	_refresh()


func _refresh() -> void:
	_dots.filled = _pin.length()
	_dots.queue_redraw()


func _digit(d: int) -> String:
	return PERSIAN[d] if I18n.is_rtl() else str(d)


func _relabel(grid: GridContainer) -> void:
	var digits := [1, 2, 3, 4, 5, 6, 7, 8, 9, -1, 0, -2]
	for i in grid.get_child_count():
		if digits[i] >= 0:
			(grid.get_child(i) as Button).text = _digit(digits[i])


class Dots extends Control:
	var filled := 0

	func _draw() -> void:
		var n := Privacy.PIN_LENGTH
		var gap := 34.0
		var x0 := size.x * 0.5 - gap * (n - 1) * 0.5
		for i in n:
			var c := Vector2(x0 + i * gap, size.y * 0.5)
			if i < filled:
				draw_circle(c, 9, Palette.INK, true, -1.0, true)
			else:
				draw_circle(c, 9, Palette.INK, false, 2.0, true)
