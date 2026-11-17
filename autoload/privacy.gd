extends Node
## Phase 3 privacy: optional PIN, and auto-lock when the app goes to the background.
## The PIN is stored only as a salted SHA-256 hash inside the local save.
## It keeps out someone casually picking up the phone; it is not encryption.

signal lock_requested

const PIN_LENGTH := 4

var _js_callback  # keep a reference or the browser drops it


func _ready() -> void:
	if OS.has_feature("web"):
		_js_callback = JavaScriptBridge.create_callback(_on_visibility_change)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _js_callback)


func has_pin() -> bool:
	return str(_sec().get("pin_hash", "")) != ""


func set_pin(pin: String) -> void:
	var salt := str(randi()) + str(Time.get_ticks_usec())
	GameState.data.security = {"salt": salt, "pin_hash": (salt + pin).sha256_text()}
	GameState.save()


func clear_pin() -> void:
	GameState.data.security = {"salt": "", "pin_hash": ""}
	GameState.save()


func check_pin(pin: String) -> bool:
	var s := _sec()
	return has_pin() and (str(s.salt) + pin).sha256_text() == str(s.pin_hash)


func _sec() -> Dictionary:
	return GameState.data.get("security", {})


func _on_visibility_change(_args) -> void:
	if JavaScriptBridge.get_interface("document").hidden:
		_request_lock()


func _notification(what: int) -> void:
	# Phones (native builds): app sent to background.
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_request_lock()


func _request_lock() -> void:
	if has_pin() and GameState.has_world():
		lock_requested.emit()
