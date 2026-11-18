extends SceneTree
## Headless checks for the world rules. Run:
##   godot --headless --script res://tests/run_tests.gd
## Exits with code 1 if any check fails.

var _failed := 0
# Autoloads, looked up at runtime (their names aren't known when a --script compiles).
var GameState
var Privacy
var SaveManager
var Sound


func _init() -> void:
	await process_frame  # let autoloads start
	GameState = root.get_node("GameState")
	Privacy = root.get_node("Privacy")
	SaveManager = root.get_node("SaveManager")
	Sound = root.get_node("Sound")
	_test_places_build()
	_test_paths_stay_open()
	_test_decor_roundtrip()
	_test_pin()
	_test_sound_setting()
	print("\n%s" % ("ALL TESTS PASSED" if _failed == 0 else "%d TEST(S) FAILED" % _failed))
	quit(1 if _failed > 0 else 0)


func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failed += 1


func _state() -> Dictionary:
	var s: Dictionary = GameState.default_data()
	s.career = "clinic"
	return s


func _test_places_build() -> void:
	print("places build and doors are reachable")
	var s := _state()
	for id in ["exterior", "home", "career", "town", "university", "library", "hills"]:
		var m := IsoMap.new()
		m.build(WorldData.build(id, s))
		var spawn: Vector2 = m.data.spawn
		check(m.is_walkable(spawn), id + ": spawn is walkable")
		check(m.keeps_paths_open({}, {}, Iso.tile_of(spawn)), id + ": every door reachable from spawn")
		for t in m.data.get("doors", {}):
			var door: Dictionary = m.data.doors[t]
			if door.action == "goto":
				var target := IsoMap.new()
				target.build(WorldData.build(door.to, s))
				check(target.is_walkable(door.spawn), "%s -> %s: arrival spot walkable" % [id, door.to])
				target.free()
		m.free()
	for c in WorldData.CAREERS:
		s.career = c.id
		var w := IsoMap.new()
		w.build(WorldData.build("career", s))
		check(w.keeps_paths_open({}, {}, Iso.tile_of(w.data.spawn)), "workplace %s: exit reachable" % c.id)
		w.free()


func _test_paths_stay_open() -> void:
	print("decorating can't trap the avatar")
	var m := IsoMap.new()
	m.build(WorldData.build("home", _state()))
	var wall := {}
	for x in 8:
		wall[Vector2i(x, 5)] = true  # a full row of furniture across the room
	check(not m.keeps_paths_open(wall, {}, Vector2i(4, 1)), "a wall across the room is refused")
	check(m.keeps_paths_open({Vector2i(6, 6): true}, {}, Vector2i(4, 6)), "a single plant is fine")
	m.free()


func _test_decor_roundtrip() -> void:
	print("placed items appear in the world and survive JSON")
	var s := _state()
	s.decor = {"exterior": [{"kind": "fruit_tree", "x": 7, "y": 9, "accent": -1}],
		"home": [{"kind": "rug", "x": 1, "y": 4, "accent": 2}]}
	s = JSON.parse_string(JSON.stringify(s))  # same path as save/load (numbers become floats)
	var m := IsoMap.new()
	m.build(WorldData.build("exterior", s))
	check(m.user_at.get(Vector2i(7, 9), -1) == 0, "tree is placed and selectable")
	check(m.solid.has(Vector2i(7, 9)), "tree blocks walking")
	m.free()
	m = IsoMap.new()
	m.build(WorldData.build("home", s))
	check(m.user_at.get(Vector2i(2, 5), -1) == 0, "rug covers 2x2 tiles")
	check(not m.solid.has(Vector2i(2, 5)), "rug can be walked on")
	m.free()
	check(Decor.key("career", s) == "career_clinic", "each workplace keeps its own decorations")


func _test_pin() -> void:
	print("PIN")
	Privacy.set_pin("1234")
	check(Privacy.has_pin(), "PIN is set")
	check(Privacy.check_pin("1234"), "right PIN accepted")
	check(not Privacy.check_pin("4321"), "wrong PIN refused")
	check(str(GameState.data.security.pin_hash).find("1234") < 0, "PIN is not stored in plain text")
	Privacy.clear_pin()
	check(not Privacy.has_pin(), "PIN removed")
	SaveManager.delete_world()


func _test_sound_setting() -> void:
	print("sound on/off")
	check(Sound.enabled(), "sound is on by default")
	Sound.set_enabled(false)
	check(not Sound.enabled() and AudioServer.is_bus_mute(0), "turning sound off mutes everything")
	GameState.reset()
	check(not Sound.enabled(), "starting over keeps her sound choice")
	Sound.set_enabled(true)
	check(not AudioServer.is_bus_mute(0), "turning sound on unmutes")
	SaveManager.delete_world()
