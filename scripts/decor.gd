class_name Decor
extends RefCounted
## Things she can place herself, and where. Only her own spaces (garden, home,
## workplace) can be decorated. The town, university, library and hills stay public.
## Each saved item is {"kind", "x", "y", "accent"} where x/y is a tile and
## accent is an index into Palette.SCARF (-1 = the item's own colours).

const MAX_ITEMS := 60

const OUTDOOR := ["tree", "fruit_tree", "bush", "flowers", "plant", "bench", "lamp", "rock", "fountain"]
const INDOOR := ["plant", "rug", "bookshelf", "bookshelf_y", "bed", "toshak", "low_table", "table",
	"armchair", "chair", "reading_table", "desk_pc", "kitchen", "globe", "easel", "canvases",
	"sewing_table", "mannequin"]

## Footprints for items that are not Furniture presets.
const SIZES := {
	"tree": Vector2.ONE, "fruit_tree": Vector2.ONE, "bush": Vector2.ONE, "flowers": Vector2(0.8, 0.8),
	"plant": Vector2(0.8, 0.8), "lamp": Vector2.ONE, "rock": Vector2.ONE, "fountain": Vector2(2, 2),
	"easel": Vector2.ONE, "globe": Vector2(0.8, 0.8), "mannequin": Vector2(0.7, 0.7), "rug": Vector2(2, 2),
}

const ACCENTABLE := ["bed", "toshak", "armchair", "rug", "mannequin", "sewing_table"]
const DECALS := ["rug"]


static func editable(location: String) -> bool:
	return location in ["exterior", "home", "career"]


static func catalog(location: String) -> Array:
	return OUTDOOR if location == "exterior" else INDOOR


## Save key: each workplace type keeps its own decorations.
static func key(location: String, state: Dictionary) -> String:
	return "career_" + str(state.career) if location == "career" else location


static func size_of(kind: String) -> Vector2:
	return SIZES.get(kind, Furniture.size_of(kind))


static func is_decal(kind: String) -> bool:
	return kind in DECALS


static func footprint(tile: Vector2i, kind: String) -> Array[Vector2i]:
	var s := size_of(kind)
	var tiles: Array[Vector2i] = []
	for x in ceili(s.x):
		for y in ceili(s.y):
			tiles.append(tile + Vector2i(x, y))
	return tiles


## Turns a saved entry into a world object/decal spec.
static func to_spec(entry: Dictionary, index: int) -> Dictionary:
	var kind := str(entry.kind)
	var s := size_of(kind)
	var tile := Vector2(int(entry.x), int(entry.y))
	var spec := {
		"kind": kind, "size": s, "user": index,
		"pos": tile + (Vector2(ceilf(s.x), ceilf(s.y)) - s) * 0.5,  # centred in its tiles
	}
	var a := int(entry.get("accent", -1))
	if a >= 0:
		var c := Palette.pick(Palette.SCARF, a)
		spec.accent = c
		spec.accent2 = c.lightened(0.3)
	return spec
