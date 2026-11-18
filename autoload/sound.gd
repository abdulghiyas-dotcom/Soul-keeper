extends Node
## Gentle sound: calm music, birdsong or a stream outdoors, soft taps and steps.
## Players pause together with the game, so hide/lock silence everything instantly.
## The on/off choice is saved on the device (Menu, and the title screen).

const DIR := "res://assets/audio/"
const LOOPS := ["music", "birds", "stream"]
const EFFECTS := ["tap", "step", "door", "place", "remove", "chime"]
const MUSIC_DB := -13.0
const AMBIENCE_DB := -15.0
const SFX_DB := -6.0

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _streams := {}
var _ambience_name := ""
var _fade: Tween


func _ready() -> void:
	# Headless runs (build tools, tests) have no speakers: skip loading audio.
	if DisplayServer.get_name() != "headless":
		for n in LOOPS + EFFECTS:
			_streams[n] = load(DIR + n + ".ogg")
		for n in LOOPS:
			(_streams[n] as AudioStreamOggVorbis).loop = true
	_music = _player(MUSIC_DB)
	_ambience = _player(AMBIENCE_DB)
	for i in 6:
		_sfx.append(_player(SFX_DB))
	get_tree().node_added.connect(_on_node_added)
	apply_setting()


func enabled() -> bool:
	return bool(GameState.data.get("settings", {}).get("sound", true))


func set_enabled(on: bool) -> void:
	GameState.data.settings.sound = on
	GameState.save()
	apply_setting()


func apply_setting() -> void:
	AudioServer.set_bus_mute(0, not enabled())
	if enabled() and not _music.playing and _streams.has("music"):
		_music.stream = _streams.music
		_music.play()
	elif not enabled():
		_music.stop()
		_ambience.stop()
		_ambience_name = ""


## One-off sound. `jitter` varies the pitch a little so repeats feel natural.
func play(name: String, volume_db := 0.0, jitter := 0.0) -> void:
	if not enabled() or not _streams.has(name):
		return
	for p in _sfx:
		if not p.playing:
			p.stream = _streams[name]
			p.volume_db = SFX_DB + volume_db
			p.pitch_scale = 1.0 + randf_range(-jitter, jitter)
			p.play()
			return


## Background sound for a place: "birds", "stream" or "" for none.
func set_ambience(name: String) -> void:
	if name == _ambience_name or not enabled() or (name != "" and not _streams.has(name)):
		return
	_ambience_name = name
	if _fade:
		_fade.kill()
	_fade = create_tween()
	if name == "":
		_fade.tween_property(_ambience, "volume_db", -60.0, 0.8)
		_fade.tween_callback(_ambience.stop)
	else:
		_ambience.stream = _streams[name]
		_ambience.volume_db = -60.0
		_ambience.play()
		_fade.tween_property(_ambience, "volume_db", AMBIENCE_DB, 1.2)


func _player(db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = db
	add_child(p)
	return p


func _on_node_added(n: Node) -> void:
	# Every button gives a soft tap, except ones marked silent (e.g. quick-hide).
	if n is Button and not n.has_meta("silent"):
		(n as Button).pressed.connect(func() -> void: play("tap", -5.0, 0.05))
