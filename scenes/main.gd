extends Node
## Switches between the three screens: title, avatar creator, world.

var _current: Node
var _privacy: PrivacyLayer


func _ready() -> void:
	_privacy = PrivacyLayer.new()
	add_child(_privacy)
	_privacy.started_over.connect(_new_world)
	_show_title()
	if Privacy.has_pin() and GameState.has_world():
		_privacy.lock()


func _switch(n: Node) -> void:
	if _current:
		_current.queue_free()
	_current = n
	add_child(n)


func _show_title() -> void:
	var t := TitleScreen.new()
	t.continue_pressed.connect(_show_world)
	t.new_pressed.connect(_new_world)
	_switch(t)


func _new_world() -> void:
	GameState.reset()
	var a := AvatarCreator.new()
	a.done.connect(func() -> void:
		GameState.data.created = true
		GameState.save()
		_show_world())
	_switch(a)


func _show_world() -> void:
	var w := WorldScreen.new()
	w.exit_requested.connect(_show_title)
	w.hide_requested.connect(_privacy.hide_now)
	_switch(w)
