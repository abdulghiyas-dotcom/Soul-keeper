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


static func career(id: String) -> Dictionary:
	for c in CAREERS:
		if c.id == id:
			return c
	return {}


static func label_key(id: String, state: Dictionary) -> String:
	match id:
		"home": return "PLACE_HOME"
		"career": return str(career(state.career).get("key", "PLACE_GARDEN"))
		_: return "PLACE_GARDEN"


static func build(id: String, state: Dictionary) -> Dictionary:
	match id:
		"home": return _home(state)
		"career": return _career(state)
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

	var doors := {HOUSE_DOOR: {"action": "goto", "to": "home", "spawn": SPAWN_INSIDE}}
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
		"spawn": SPAWN_INSIDE,
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
		"spawn": SPAWN_INSIDE,
	}
