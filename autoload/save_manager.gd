extends Node
## Local-only storage. Nothing ever leaves the device.
##
## Godot's user:// folder maps to the browser's IndexedDB in web builds, which
## works offline and suits a future PWA. On Android/iOS it maps to app storage.
## A backup copy of the previous save is kept in case a write is interrupted.

const SAVE_PATH := "user://world.json"
const BACKUP_PATH := "user://world.backup.json"


func _ready() -> void:
	if OS.has_feature("web"):
		# Ask the browser not to evict our data when storage runs low.
		JavaScriptBridge.eval(
			"if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); }", true)


func has_save() -> bool:
	return not load_world().is_empty()


func save_world(data: Dictionary) -> bool:
	var text := JSON.stringify(data, "\t")
	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.get_file_as_string(SAVE_PATH)
		if JSON.parse_string(old) is Dictionary:
			_write(BACKUP_PATH, old)
	return _write(SAVE_PATH, text)


func load_world() -> Dictionary:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				return parsed
	return {}


func delete_world() -> void:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s (%s)" % [path, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.close()
	return true
