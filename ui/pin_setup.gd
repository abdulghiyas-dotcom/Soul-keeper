class_name PinSetup
extends VBoxContainer
## Set, change or remove the PIN. Changing or removing asks for the current PIN first.
## Emits finished with a message key ("" when cancelled).

signal finished(message_key: String)

enum Mode { SET, REMOVE }

var mode := Mode.SET
var _pad: PinPad
var _step := ""
var _first := ""


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_pad = PinPad.new()
	add_child(_pad)
	var cancel := UI.button("CANCEL", func() -> void: finished.emit(""), 200)
	cancel.size_flags_horizontal = SIZE_SHRINK_CENTER
	add_child(cancel)
	_pad.entered.connect(_on_entered)
	if Privacy.has_pin():
		_go("current", "ENTER_PIN")
	else:
		_go("new", "NEW_PIN")


func _go(step: String, title: String) -> void:
	_step = step
	_pad.set_title(title)


func _on_entered(pin: String) -> void:
	match _step:
		"current":
			if not Privacy.check_pin(pin):
				_pad.show_message("PIN_WRONG")
			elif mode == Mode.REMOVE:
				Privacy.clear_pin()
				finished.emit("PIN_REMOVED")
			else:
				_go("new", "NEW_PIN")
		"new":
			_first = pin
			_go("confirm", "CONFIRM_PIN")
		"confirm":
			if pin == _first:
				Privacy.set_pin(pin)
				finished.emit("PIN_SET")
			else:
				_pad.show_message("PIN_MISMATCH")
				_go("new", "NEW_PIN")
