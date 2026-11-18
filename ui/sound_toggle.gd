class_name SoundToggle
extends Button
## "Sound: on/off" button that flips the saved setting.


func _init(min_w := 260) -> void:
	custom_minimum_size = Vector2(min_w, 56)


func _ready() -> void:
	_refresh()
	pressed.connect(func() -> void:
		Sound.set_enabled(not Sound.enabled())
		_refresh())


func _refresh() -> void:
	text = "SOUND_ON" if Sound.enabled() else "SOUND_OFF"
