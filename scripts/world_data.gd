class_name WorldData
extends RefCounted
## Every location in the dream world, described as data.
## To add a new place: add a builder function and a case in build().

const CAREERS := [
	{"id": "studio", "key": "CAREER_STUDIO", "color": Color("#c98bb9")},
	{"id": "school", "key": "CAREER_SCHOOL", "color": Color("#6f9fc7")},
	{"id": "clinic", "key": "CAREER_CLINIC", "color": Color("#6fb3a2")},
	{"id": "office", "key": "CAREER_OFFICE", "color": Color("#8a93b8")},
	{"id": "shop", "key": "CAREER_SHOP", "color": Color("#e0a35c")},
	{"id": "tailor", "key": "CAREER_TAILOR", "color": Color("#d9827a")},
]

# Where you appear when you walk through a door.
const SPAWN_GARDEN_START := Vector2(5.5, 9.5)
const SPAWN_GARDEN_FROM_HOME := Vector2(5.5, 8.4)
const SPAWN_GARDEN_FROM_WORK := Vector2(12.5, 9.4)
const SPAWN_INSIDE := Vector2(4.5, 6.4)

const HOUSE_DOOR := Vector2i(5, 7)
const WORK_DOOR := Vector2i(12, 8)

const SPAWN_GARDEN_FROM_TOWN := Vector2(5.5, 14.3)
const SPAWN_TOWN_FROM_GARDEN := Vector2(5.5, 1.5)
const SPAWN_TOWN_FROM_HILLS := Vector2(16.4, 7.5)
const SPAWN_TOWN_FROM_UNI := Vector2(10.5, 6.5)
const SPAWN_TOWN_FROM_LIBRARY := Vector2(2.5, 12.4)
const SPAWN_HILLS_FROM_TOWN := Vector2(1.5, 6.5)

const PLACE_LABELS := {
	"exterior": "PLACE_GARDEN", "home": "PLACE_HOME", "town": "PLACE_TOWN",
	"university": "PLACE_UNIVERSITY", "library": "PLACE_LIBRARY", "hills": "PLACE_HILLS",
}


static func career(id: String) -> Dictionary:
	for c in CAREERS:
		if c.id == id:
			return c
	return {}


static func label_key(id: String, state: Dictionary) -> String:
	if id == "career":
		return str(career(state.career).get("key", "PLACE_GARDEN"))
	return PLACE_LABELS.get(id, "PLACE_GARDEN")


static func build(id: String, state: Dictionary) -> Dictionary:
	var d := _build(id, state)
	if Decor.editable(id):
		var items: Array = state.get("decor", {}).get(Decor.key(id, state), [])
		for i in items.size():
			var spec := Decor.to_spec(items[i], i)
			if Decor.is_decal(spec.kind):
				d.decals.append(spec)
			else:
				d.objects.append(spec)
	return d


static func _build(id: String, state: Dictionary) -> Dictionary:
	match id:
		"home": return _home(state)
		"career": return _career(state)
		"town": return _town()
		"university": return _university()
		"library": return _library()
		"hills": return _hills()
		_: return _exterior(state)


# --- the garden ---------------------------------------------------------------

static func _exterior(state: Dictionary) -> Dictionary:
	var paths: Array[Vector2i] = []
	for y in range(7, 16):
		paths.append(Vector2i(5, y))
	for x in range(6, 13):
		paths.append(Vector2i(x, 11))
	for y in range(8, 11):
		paths.append(Vector2i(12, y))

	var objs: Array = [
		{"kind": "house", "pos": Vector2(3, 3), "size": Vector2(5, 4), "door": HOUSE_DOOR,
			"wall": Palette.pick(Palette.WALL, state.home.wall),
			"roof": Palette.pick(Palette.ROOF, state.home.roof)},
		{"kind": "bench", "pos": Vector2(14.6, 9.25)},
		{"kind": "lamp", "pos": Vector2(4, 10)},
		{"kind": "flowers", "pos": Vector2(6.1, 8.1), "size": Vector2(0.8, 1.8)},
		{"kind": "flowers", "pos": Vector2(3.1, 8.1), "size": Vector2(1.8, 0.8)},
		{"kind": "flowers", "pos": Vector2(8.1, 12.1), "size": Vector2(2.8, 0.8)},
		{"kind": "flowers", "pos": Vector2(12.1, 14.1), "size": Vector2(1.8, 0.8)},
	]
	for t in [Vector2(1, 1), Vector2(9, 2), Vector2(13, 1), Vector2(16, 3), Vector2(1, 8),
			Vector2(2, 13), Vector2(16, 8), Vector2(9, 14), Vector2(16, 15), Vector2(0, 11)]:
		objs.append({"kind": "tree", "pos": t, "size": Vector2.ONE})
	for t in [Vector2(2, 3), Vector2(8, 4), Vector2(2, 6), Vector2(7, 14)]:
		objs.append({"kind": "bush", "pos": t, "size": Vector2.ONE})
	for x in 18:
		objs.append({"kind": "hedge", "pos": Vector2(x, 0)})
	for y in range(1, 16):
		if y != 11:
			objs.append({"kind": "hedge", "pos": Vector2(0, y), "size": Vector2(0.5, 1)})

	objs.append({"kind": "arch", "pos": Vector2(4.85, 15.75), "size": Vector2(1.3, 0.2), "solid": false})
	var doors := {
		HOUSE_DOOR: {"action": "goto", "to": "home", "spawn": SPAWN_INSIDE},
		Vector2i(5, 15): {"action": "goto", "to": "town", "spawn": SPAWN_TOWN_FROM_GARDEN},
	}
	var decals: Array = [{"kind": "pond", "pos": Vector2(14, 11), "size": Vector2(3, 3)}]
	var blocked: Array[Vector2i] = []
	for x in range(14, 17):
		for y in range(11, 14):
			blocked.append(Vector2i(x, y))

	var plot_pos := Vector2(11, 4)
	var plot_size := Vector2(4, 4)
	var c := career(state.career)
	var d := {}
	if c.is_empty():
		# An empty plot waiting for her to decide what to build.
		decals.append({"kind": "plot", "pos": plot_pos, "size": plot_size})
		objs.append({"kind": "sign", "pos": Vector2(12.1, 7.1), "size": Vector2(0.8, 0.8), "solid": false})
		for x in range(11, 15):
			for y in range(4, 8):
				blocked.append(Vector2i(x, y))
		d["blocked_door"] = WORK_DOOR
		doors[WORK_DOOR] = {"action": "pick_career"}
	else:
		objs.append({"kind": "building", "pos": plot_pos, "size": plot_size, "door": WORK_DOOR,
			"color": c.color, "career": c.id})
		doors[WORK_DOOR] = {"action": "goto", "to": "career", "spawn": SPAWN_INSIDE}

	d.merge({
		"id": "exterior", "size": Vector2i(18, 16), "outdoor": true, "sky": Palette.SKY_OUTSIDE,
		"paths": paths, "decals": decals, "objects": objs, "blocked": blocked,
		"doors": doors, "spawn": SPAWN_GARDEN_START,
		"keep_clear": [SPAWN_GARDEN_START, SPAWN_GARDEN_FROM_HOME, SPAWN_GARDEN_FROM_WORK, SPAWN_GARDEN_FROM_TOWN],
	})
	return d


# --- inside her home ------------------------------------------------------------

static func _home(state: Dictionary) -> Dictionary:
	var wall := Palette.pick(Palette.WALL, state.home.wall)
	var scarf_i := int(state.avatar.get("scarf", 0))
	var accent := Palette.pick(Palette.SCARF, scarf_i if scarf_i >= 0 else 0)
	return {
		"id": "home", "size": Vector2i(8, 8), "outdoor": false, "sky": Palette.SKY_INSIDE,
		"walls": {"color": wall, "decor": [
			{"kind": "window", "wall": "y", "a": 3.4, "b": 5.6, "za": 44, "zb": 86},
			{"kind": "window", "wall": "x", "a": 2.4, "b": 3.8, "za": 44, "zb": 86},
			{"kind": "painting", "wall": "x", "a": 6.2, "b": 7.4, "za": 50, "zb": 80, "accent": "#e0b65c"},
			{"kind": "painting", "wall": "y", "a": 6.3, "b": 7.3, "za": 56, "zb": 84, "accent": "#86b38a"},
		]},
		"decals": [
			{"kind": "rug", "pos": Vector2(3, 2), "size": Vector2(3, 3), "accent": "#b5523f"},
			{"kind": "mat", "pos": Vector2(4.1, 7.2), "size": Vector2(0.8, 0.7)},
		],
		"objects": [
			{"kind": "bed", "pos": Vector2(0, 0), "accent": accent},
			{"kind": "toshak", "pos": Vector2(3, 0.05)},
			{"kind": "low_table", "pos": Vector2(3.7, 3)},
			{"kind": "bookshelf", "pos": Vector2(0, 4)},
			{"kind": "plant", "pos": Vector2(7, 0), "size": Vector2.ONE},
			{"kind": "plant", "pos": Vector2(0, 6.3), "size": Vector2(0.7, 0.7)},
			{"kind": "kitchen", "pos": Vector2(7, 2.6)},
		],
		"doors": {Vector2i(4, 7): {"action": "goto", "to": "exterior", "spawn": SPAWN_GARDEN_FROM_HOME}},
		"spawn": SPAWN_INSIDE, "keep_clear": [SPAWN_INSIDE],
	}


# --- her workplace --------------------------------------------------------------

static func _career(state: Dictionary) -> Dictionary:
	var c := career(state.career)
	var col: Color = c.get("color", Color("#c98bb9"))
	var decor: Array = [{"kind": "window", "wall": "x", "a": 1.2, "b": 3.0, "za": 44, "zb": 90}]
	var objs: Array = [{"kind": "plant", "pos": Vector2(7, 0), "size": Vector2.ONE}]
	var decals: Array = [{"kind": "mat", "pos": Vector2(4.1, 7.2), "size": Vector2(0.8, 0.7)}]
	match str(c.get("id", "")):
		"studio":
			decor.append({"kind": "painting", "wall": "y", "a": 1, "b": 2.4, "za": 50, "zb": 86, "accent": "#a9d2e0"})
			decor.append({"kind": "painting", "wall": "y", "a": 3, "b": 4, "za": 56, "zb": 80, "accent": "#f2a7b8"})
			decor.append({"kind": "painting", "wall": "x", "a": 4, "b": 5.6, "za": 50, "zb": 84, "accent": "#e0b65c"})
			objs += [{"kind": "easel", "pos": Vector2(2, 3), "size": Vector2.ONE},
				{"kind": "easel", "pos": Vector2(5, 3.5), "size": Vector2.ONE},
				{"kind": "paint_table", "pos": Vector2(4.5, 0.1)},
				{"kind": "canvases", "pos": Vector2(0.05, 4.5)}]
			decals.append({"kind": "rug", "pos": Vector2(1.5, 2.5), "size": Vector2(5, 2.5), "accent": "#c98bb9"})
		"school":
			decor.append({"kind": "blackboard", "wall": "y", "a": 2, "b": 6, "za": 36, "zb": 88})
			objs += [{"kind": "teacher_desk", "pos": Vector2(3, 1.2)},
				{"kind": "bookshelf", "pos": Vector2(0, 4.5)}]
			for p in [Vector2(1.2, 3.4), Vector2(3.4, 3.4), Vector2(5.6, 3.4), Vector2(1.2, 5.2), Vector2(5.6, 5.2)]:
				objs.append({"kind": "school_desk", "pos": p, "accent": "#d9a441"})
		"clinic":
			decor.append({"kind": "cross", "wall": "y", "a": 3, "b": 4, "za": 56, "zb": 88})
			objs += [{"kind": "exam_bed", "pos": Vector2(0.3, 0.3)},
				{"kind": "cabinet", "pos": Vector2(0, 4)},
				{"kind": "desk_pc", "pos": Vector2(4.5, 1)},
				{"kind": "chair", "pos": Vector2(5.2, 2.2)},
				{"kind": "plant", "pos": Vector2(7, 5), "size": Vector2.ONE}]
		"office":
			decor.append({"kind": "painting", "wall": "y", "a": 3, "b": 4.6, "za": 52, "zb": 84, "accent": "#86b38a"})
			objs += [{"kind": "desk_pc", "pos": Vector2(1.2, 1)}, {"kind": "desk_pc", "pos": Vector2(4.6, 1)},
				{"kind": "desk_pc", "pos": Vector2(1.2, 4)}, {"kind": "chair", "pos": Vector2(1.9, 2.2)},
				{"kind": "chair", "pos": Vector2(5.3, 2.2)}, {"kind": "bookshelf", "pos": Vector2(0, 5)}]
		"shop":
			objs += [{"kind": "shelf_goods", "pos": Vector2(0.4, 0.05)},
				{"kind": "shelf_goods", "pos": Vector2(3.2, 0.05)},
				{"kind": "counter", "pos": Vector2(5, 4)}]
			decals.append({"kind": "rug", "pos": Vector2(1, 2.5), "size": Vector2(3, 2), "accent": "#e0a35c"})
		"tailor":
			decor.append({"kind": "mirror", "wall": "y", "a": 1, "b": 2, "za": 30, "zb": 92})
			objs += [{"kind": "sewing_table", "pos": Vector2(3, 0.6), "accent": "#c8604a"},
				{"kind": "fabric_rolls", "pos": Vector2(0.1, 2.5)},
				{"kind": "cutting_table", "pos": Vector2(4.5, 3.5), "accent": "#8e6cb5"},
				{"kind": "mannequin", "pos": Vector2(1.5, 5), "size": Vector2(0.7, 0.7), "accent": "#5b9e7a"},
				{"kind": "mannequin", "pos": Vector2(2.6, 5.4), "size": Vector2(0.7, 0.7), "accent": "#d9a441"}]
	return {
		"id": "career", "size": Vector2i(8, 8), "outdoor": false, "sky": Palette.SKY_INSIDE,
		"walls": {"color": col.lightened(0.7), "decor": decor},
		"decals": decals, "objects": objs,
		"doors": {Vector2i(4, 7): {"action": "goto", "to": "exterior", "spawn": SPAWN_GARDEN_FROM_WORK}},
		"spawn": SPAWN_INSIDE, "keep_clear": [SPAWN_INSIDE],
	}


# --- the town: university, library, market, fountain ----------------------------

static func _town() -> Dictionary:
	var paths: Array[Vector2i] = []
	for y in 14:
		paths.append(Vector2i(5, y))
	for x in range(1, 18):
		paths.append(Vector2i(x, 7))
	for t in [Vector2i(10, 5), Vector2i(10, 6), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11),
			Vector2i(2, 12)]:
		paths.append(t)
	for x in range(12, 18):
		for y in range(8, 12):
			paths.append(Vector2i(x, y))
	var objs: Array = [
		{"kind": "building", "pos": Vector2(8, 1), "size": Vector2(6, 4), "door": Vector2i(10, 5),
			"color": Color("#7b8fb5"), "height": 96.0, "columns": true},
		{"kind": "building", "pos": Vector2(1, 8), "size": Vector2(3, 3), "door": Vector2i(2, 11),
			"color": Color("#b5895a"), "emblem": "book"},
		{"kind": "stall", "pos": Vector2(6.6, 8.3), "size": Vector2(1.6, 1), "accent": "#c8604a"},
		{"kind": "stall", "pos": Vector2(8.6, 8.3), "size": Vector2(1.6, 1), "accent": "#6f9fc7"},
		{"kind": "stall", "pos": Vector2(10.6, 8.3), "size": Vector2(1.2, 1), "accent": "#e0a35c"},
		{"kind": "fountain", "pos": Vector2(14, 9), "size": Vector2(2, 2)},
		{"kind": "bench", "pos": Vector2(13.2, 12.2)},
		{"kind": "arch", "pos": Vector2(4.85, 0.05), "size": Vector2(1.3, 0.2), "solid": false},
		{"kind": "arch", "pos": Vector2(17.8, 6.85), "size": Vector2(0.2, 1.3), "axis": "x", "solid": false},
	]
	for t in [Vector2(0, 1), Vector2(2, 2), Vector2(15, 1), Vector2(17, 3), Vector2(0, 13), Vector2(7, 12),
			Vector2(11, 12), Vector2(16, 13), Vector2(3, 4), Vector2(9, 11)]:
		objs.append({"kind": "tree", "pos": t, "size": Vector2.ONE})
	for t in [Vector2(4, 6), Vector2(6, 6), Vector2(9, 6), Vector2(12, 6), Vector2(4, 12)]:
		objs.append({"kind": "lamp", "pos": t, "size": Vector2.ONE})
	objs.append({"kind": "flowers", "pos": Vector2(6.1, 2.1), "size": Vector2(0.8, 2.8)})
	objs.append({"kind": "flowers", "pos": Vector2(14.1, 5.1), "size": Vector2(2.8, 0.8)})
	for x in 18:
		if x != 5:
			objs.append({"kind": "hedge", "pos": Vector2(x, 0)})
	for y in range(2, 13):
		objs.append({"kind": "hedge", "pos": Vector2(0, y), "size": Vector2(0.5, 1)})
	return {
		"id": "town", "size": Vector2i(18, 14), "outdoor": true, "sky": Palette.SKY_OUTSIDE,
		"paths": paths, "objects": objs, "decals": [],
		"doors": {
			Vector2i(5, 0): {"action": "goto", "to": "exterior", "spawn": SPAWN_GARDEN_FROM_TOWN},
			Vector2i(17, 7): {"action": "goto", "to": "hills", "spawn": SPAWN_HILLS_FROM_TOWN},
			Vector2i(10, 5): {"action": "goto", "to": "university", "spawn": SPAWN_INSIDE},
			Vector2i(2, 11): {"action": "goto", "to": "library", "spawn": SPAWN_INSIDE},
		},
		"spawn": SPAWN_TOWN_FROM_GARDEN,
	}


static func _university() -> Dictionary:
	var objs: Array = [
		{"kind": "teacher_desk", "pos": Vector2(3, 1.2)},
		{"kind": "bookshelf", "pos": Vector2(0, 2.4)},
		{"kind": "bookshelf", "pos": Vector2(0, 4.6)},
		{"kind": "globe", "pos": Vector2(6.6, 1), "size": Vector2(0.8, 0.8)},
		{"kind": "plant", "pos": Vector2(7, 5.5), "size": Vector2.ONE},
	]
	for p in [Vector2(1.4, 3.3), Vector2(3.4, 3.3), Vector2(5.4, 3.3), Vector2(1.4, 5.1), Vector2(5.4, 5.1)]:
		objs.append({"kind": "school_desk", "pos": p, "accent": "#6a8caf"})
	return {
		"id": "university", "size": Vector2i(8, 8), "outdoor": false, "sky": Palette.SKY_INSIDE,
		"walls": {"color": Color("#dfe5f0"), "decor": [
			{"kind": "blackboard", "wall": "y", "a": 1.5, "b": 6.5, "za": 34, "zb": 92},
			{"kind": "window", "wall": "x", "a": 0.6, "b": 2.0, "za": 44, "zb": 90},
			{"kind": "painting", "wall": "x", "a": 6.6, "b": 7.6, "za": 50, "zb": 82, "accent": "#a9d2e0"},
		]},
		"decals": [{"kind": "mat", "pos": Vector2(4.1, 7.2), "size": Vector2(0.8, 0.7)}],
		"objects": objs,
		"doors": {Vector2i(4, 7): {"action": "goto", "to": "town", "spawn": SPAWN_TOWN_FROM_UNI}},
		"spawn": SPAWN_INSIDE,
	}


static func _library() -> Dictionary:
	return {
		"id": "library", "size": Vector2i(8, 8), "outdoor": false, "sky": Palette.SKY_INSIDE,
		"walls": {"color": Color("#efe2cf"), "decor": [
			{"kind": "window", "wall": "x", "a": 5.4, "b": 6.8, "za": 44, "zb": 90},
			{"kind": "painting", "wall": "y", "a": 6.9, "b": 7.7, "za": 52, "zb": 80, "accent": "#86b38a"},
		]},
		"decals": [
			{"kind": "rug", "pos": Vector2(2.2, 2.8), "size": Vector2(3.6, 2.6), "accent": "#8e6cb5"},
			{"kind": "mat", "pos": Vector2(4.1, 7.2), "size": Vector2(0.8, 0.7)},
		],
		"objects": [
			{"kind": "bookshelf_y", "pos": Vector2(0.4, 0.05)},
			{"kind": "bookshelf_y", "pos": Vector2(2.6, 0.05)},
			{"kind": "bookshelf_y", "pos": Vector2(4.8, 0.05)},
			{"kind": "bookshelf", "pos": Vector2(0, 1.4)},
			{"kind": "bookshelf", "pos": Vector2(0, 3.6)},
			{"kind": "reading_table", "pos": Vector2(2.9, 3.5)},
			{"kind": "armchair", "pos": Vector2(6, 3.4), "accent": "#5b9e7a", "accent2": "#86b38a"},
			{"kind": "plant", "pos": Vector2(7, 0), "size": Vector2.ONE},
			{"kind": "plant", "pos": Vector2(0, 6.2), "size": Vector2(0.7, 0.7)},
		],
		"doors": {Vector2i(4, 7): {"action": "goto", "to": "town", "spawn": SPAWN_TOWN_FROM_LIBRARY}},
		"spawn": SPAWN_INSIDE,
	}


# --- the hills: river, bridge, a quiet lookout -----------------------------------

static func _hills() -> Dictionary:
	var paths: Array[Vector2i] = []
	for x in range(0, 8):
		paths.append(Vector2i(x, 6))
	for x in range(10, 14):
		paths.append(Vector2i(x, 6))
	for y in range(3, 6):
		paths.append(Vector2i(13, y))
	var blocked: Array[Vector2i] = []
	for y in 14:
		if y != 6:
			blocked.append(Vector2i(8, y))
			blocked.append(Vector2i(9, y))
	var objs: Array = [
		{"kind": "bench", "pos": Vector2(12.4, 2.1)},
		{"kind": "flowers", "pos": Vector2(2.1, 8.1), "size": Vector2(2.8, 0.8)},
		{"kind": "flowers", "pos": Vector2(11.1, 8.1), "size": Vector2(1.8, 0.8)},
		{"kind": "flowers", "pos": Vector2(15.1, 5.1), "size": Vector2(1.8, 1.8)},
		{"kind": "flowers", "pos": Vector2(4.1, 3.1), "size": Vector2(0.8, 1.8)},
		{"kind": "arch", "pos": Vector2(0.05, 5.85), "size": Vector2(0.2, 1.3), "axis": "x", "solid": false},
	]
	for t in [Vector2(2, 1), Vector2(6, 2), Vector2(1, 10), Vector2(3, 12), Vector2(6, 9), Vector2(11, 11),
			Vector2(15, 9), Vector2(16, 12), Vector2(12, 13), Vector2(16, 1), Vector2(17, 4), Vector2(11, 0)]:
		objs.append({"kind": "tree", "pos": t, "size": Vector2.ONE})
	for t in [Vector2(5, 11), Vector2(13, 10), Vector2(15, 7), Vector2(1, 3)]:
		objs.append({"kind": "rock", "pos": t, "size": Vector2.ONE})
	for t in [Vector2(4, 8), Vector2(10, 3), Vector2(14, 12)]:
		objs.append({"kind": "bush", "pos": t, "size": Vector2.ONE})
	return {
		"id": "hills", "size": Vector2i(18, 14), "outdoor": true, "sky": Color("#cfe3ea"),
		"mountains": true, "paths": paths, "blocked": blocked, "objects": objs,
		"decals": [
			{"kind": "river", "pos": Vector2(8, 0), "size": Vector2(2, 14)},
			{"kind": "bridge", "pos": Vector2(7.85, 6.1), "size": Vector2(2.3, 0.8)},
			{"kind": "picnic", "pos": Vector2(15, 3.2), "size": Vector2(1.6, 1.3)},
		],
		"doors": {Vector2i(0, 6): {"action": "goto", "to": "town", "spawn": SPAWN_TOWN_FROM_HILLS}},
		"spawn": SPAWN_HILLS_FROM_TOWN,
	}
