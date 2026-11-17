extends Node
## The user's dream world, held in memory as plain data (saved as JSON).
## Bump SAVE_VERSION and extend _migrate() whenever the data shape changes,
## so worlds saved by older versions keep working.

const SAVE_VERSION := 1

var data: Dictionary = {}


func _ready() -> void:
	var loaded := SaveManager.load_world()
	data = _migrate(loaded) if not loaded.is_empty() else default_data()
	if str(data.language) != "":
		I18n.set_language(data.language)
	I18n.language_changed.connect(func(code: String) -> void:
		data.language = code)


static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created": false,
		"language": "",
		"avatar": {"skin": 1, "hair": 0, "scarf": 0, "dress": 0},  # scarf -1 = none
		"home": {"wall": 0, "roof": 0},
		"career": "",  # "" until she chooses; see WorldData.CAREERS
		"location": {"scene": "exterior", "x": -1.0, "y": -1.0},
		"security": {"salt": "", "pin_hash": ""},
	}


func has_world() -> bool:
	return bool(data.get("created", false))


func reset() -> void:
	# Starting over also removes the PIN (this is the "forgot PIN" path).
	var lang = data.get("language", "")
	data = default_data()
	data.language = lang
	SaveManager.delete_world()


func save() -> bool:
	return SaveManager.save_world(data)


func look() -> Dictionary:
	return data.avatar


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_APPLICATION_PAUSED:
			if has_world():
				save()


func _migrate(d: Dictionary) -> Dictionary:
	# Fill any keys missing from older saves with defaults.
	var out := default_data()
	_merge(out, d)
	out.version = SAVE_VERSION
	return out


func _merge(into: Dictionary, src: Dictionary) -> void:
	for k in src:
		if into.has(k) and into[k] is Dictionary and src[k] is Dictionary:
			_merge(into[k], src[k])
		else:
			into[k] = src[k]
