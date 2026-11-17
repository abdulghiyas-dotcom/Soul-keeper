class_name Furniture
extends RefCounted
## Furniture is pure data: a footprint size plus a list of boxes.
## Each part is [dx, dy, w, d, h, z, colour] relative to the object's corner.
## A colour of "$accent" (or any "$name") is read from the object's spec,
## so the same bed can have a different blanket in every home.
## Add a new piece of furniture by adding an entry here — no code needed.

const W := "#b08560"   # wood
const WD := "#8a6446"  # dark wood

const PRESETS := {
	"bed": {"size": Vector2(2, 3), "parts": [
		[0, 0, 2, 0.18, 40, 0, WD], [0, 0.18, 2, 2.82, 12, 0, W],
		[0.08, 0.25, 1.84, 2.67, 9, 12, "#f5efe4"], [0.3, 0.35, 1.4, 0.5, 6, 21, "#fffaf2"],
		[0.08, 1.05, 1.84, 1.87, 4, 21, "$accent"]]},
	"toshak": {"size": Vector2(3, 0.9), "parts": [
		[0, 0, 3, 0.3, 26, 0, "$accent2"], [0, 0.3, 3, 0.6, 9, 0, "$accent"]]},
	"low_table": {"size": Vector2(1.6, 1), "parts": [
		[0.1, 0.1, 1.4, 0.8, 10, 0, WD], [0, 0, 1.6, 1, 4, 10, W],
		[0.6, 0.35, 0.3, 0.3, 9, 14, "#ece5d8"], [0.2, 0.3, 0.15, 0.15, 5, 14, "#ece5d8"],
		[1.1, 0.5, 0.15, 0.15, 5, 14, "#ece5d8"]]},
	"bookshelf": {"size": Vector2(0.6, 2), "parts": [
		[0, 0, 0.6, 2, 84, 0, WD],
		[0.6, 0.15, 0.05, 0.6, 18, 8, "#c8604a"], [0.6, 0.9, 0.05, 0.8, 16, 8, "#6a8caf"],
		[0.6, 0.2, 0.05, 0.9, 16, 36, "#d9a441"], [0.6, 1.2, 0.05, 0.6, 18, 36, "#5b9e7a"],
		[0.6, 0.3, 0.05, 1.2, 15, 62, "#8e6cb5"]]},
	"table": {"size": Vector2(2, 1.2), "parts": [
		[0.05, 0.05, 0.12, 0.12, 24, 0, WD], [1.83, 0.05, 0.12, 0.12, 24, 0, WD],
		[0.05, 1.03, 0.12, 0.12, 24, 0, WD], [1.83, 1.03, 0.12, 0.12, 24, 0, WD],
		[0, 0, 2, 1.2, 5, 24, W]]},
	"desk_pc": {"size": Vector2(2, 1), "parts": [
		[0, 0, 0.2, 1, 26, 0, WD], [1.8, 0, 0.2, 1, 26, 0, WD], [0, 0, 2, 1, 4, 26, W],
		[0.95, 0.25, 0.15, 0.12, 6, 30, "#3b4650"], [0.6, 0.2, 0.85, 0.08, 26, 36, "#3b4650"],
		[0.6, 0.6, 0.6, 0.25, 2, 30, "#d8dde0"]]},
	"school_desk": {"size": Vector2(1.4, 0.8), "parts": [
		[0.1, 0.1, 1.2, 0.6, 20, 0, WD], [0, 0, 1.4, 0.8, 4, 20, W],
		[0.3, 0.2, 0.45, 0.35, 3, 24, "$accent"]]},
	"teacher_desk": {"size": Vector2(2, 1), "parts": [
		[0, 0, 2, 1, 28, 0, WD], [-0.05, -0.05, 2.1, 1.1, 4, 28, W],
		[1.3, 0.3, 0.4, 0.3, 8, 32, "#c8604a"], [0.3, 0.3, 0.2, 0.2, 14, 32, "#7fae86"]]},
	"kitchen": {"size": Vector2(1, 2.4), "parts": [
		[0, 0, 1, 2.4, 30, 0, "#e7dccb"], [0, 0, 1, 2.4, 3, 30, "#9aa7a6"],
		[0.3, 0.3, 0.4, 0.4, 10, 33, "#6a7070"], [0.3, 1.5, 0.4, 0.4, 7, 33, "#c8604a"]]},
	"exam_bed": {"size": Vector2(1, 2.2), "parts": [
		[0.1, 0.1, 0.8, 2, 20, 0, "#b9c4c9"], [0, 0, 1, 2.2, 8, 20, "#f3f6f6"],
		[0.15, 0.1, 0.7, 0.45, 5, 28, "#ffffff"]]},
	"cabinet": {"size": Vector2(0.7, 1.5), "parts": [
		[0, 0, 0.7, 1.5, 64, 0, "#f1f3f2"],
		[0.7, 0.65, 0.04, 0.2, 24, 30, "#d0544a"], [0.7, 0.5, 0.04, 0.5, 8, 38, "#d0544a"]]},
	"shelf_goods": {"size": Vector2(2.4, 0.7), "parts": [
		[0, 0, 2.4, 0.7, 70, 0, W],
		[0.15, 0.7, 0.5, 0.12, 14, 6, "#d9a441"], [0.8, 0.7, 0.6, 0.12, 12, 6, "#c8604a"],
		[1.6, 0.7, 0.6, 0.12, 14, 6, "#86b38a"], [0.2, 0.7, 0.7, 0.12, 12, 30, "#6a8caf"],
		[1.1, 0.7, 0.9, 0.12, 14, 30, "#e0b65c"], [0.4, 0.7, 1.4, 0.12, 12, 52, "#9a86c9"]]},
	"counter": {"size": Vector2(2, 1), "parts": [
		[0, 0, 2, 1, 32, 0, WD], [0, 0, 2, 1, 4, 32, W],
		[0.3, 0.3, 0.5, 0.4, 8, 36, "#d9a441"], [1.2, 0.35, 0.4, 0.3, 4, 36, "#86b38a"]]},
	"paint_table": {"size": Vector2(2, 0.9), "parts": [
		[0.1, 0.1, 1.8, 0.7, 24, 0, WD], [0, 0, 2, 0.9, 4, 24, W],
		[0.2, 0.2, 0.18, 0.18, 4, 28, "#c8604a"], [0.5, 0.25, 0.18, 0.18, 4, 28, "#6a8caf"],
		[0.8, 0.2, 0.18, 0.18, 4, 28, "#d9a441"], [1.1, 0.3, 0.18, 0.18, 4, 28, "#5b9e7a"],
		[1.4, 0.2, 0.4, 0.5, 2, 28, "#f5efe4"]]},
	"canvases": {"size": Vector2(0.5, 1.4), "parts": [
		[0, 0, 0.12, 1.3, 46, 0, "#f5efe4"], [0.14, 0.1, 0.12, 1.1, 38, 0, "#e8c9a0"],
		[0.28, 0.2, 0.12, 0.9, 30, 0, "#b9d0d9"]]},
	"sewing_table": {"size": Vector2(2, 1), "parts": [
		[0, 0, 0.2, 1, 26, 0, WD], [1.8, 0, 0.2, 1, 26, 0, WD], [0, 0, 2, 1, 4, 26, W],
		[0.6, 0.3, 0.8, 0.35, 10, 30, "#f1f1ee"], [0.6, 0.3, 0.2, 0.35, 22, 30, "#f1f1ee"],
		[0.6, 0.3, 0.8, 0.35, 5, 46, "#f1f1ee"], [1.5, 0.4, 0.3, 0.3, 6, 30, "$accent"]]},
	"fabric_rolls": {"size": Vector2(1, 2), "parts": [
		[0.1, 0.1, 0.28, 0.28, 58, 0, "#c8604a"], [0.5, 0.2, 0.28, 0.28, 50, 0, "#6a8caf"],
		[0.15, 0.6, 0.28, 0.28, 54, 0, "#d9a441"], [0.55, 0.75, 0.28, 0.28, 46, 0, "#8e6cb5"],
		[0.1, 1.2, 0.28, 0.28, 52, 0, "#5b9e7a"], [0.5, 1.4, 0.28, 0.28, 44, 0, "#d98b8b"]]},
	"cutting_table": {"size": Vector2(2, 1.2), "parts": [
		[0.1, 0.1, 1.8, 1, 26, 0, WD], [0, 0, 2, 1.2, 4, 26, W],
		[0.25, 0.2, 1.4, 0.8, 2, 30, "$accent"]]},
	"bench": {"size": Vector2(2, 0.7), "parts": [
		[0, 0, 2, 0.12, 22, 14, W], [0.1, 0.2, 0.15, 0.35, 14, 0, WD],
		[1.75, 0.2, 0.15, 0.35, 14, 0, WD], [0, 0.12, 2, 0.5, 4, 14, W]]},
	"hedge": {"size": Vector2(1, 0.5), "parts": [[0, 0, 1, 0.5, 18, 0, "#86b47d"]]},
	"chair": {"size": Vector2(0.6, 0.6), "parts": [
		[0, 0, 0.6, 0.1, 30, 0, WD], [0.05, 0.1, 0.5, 0.45, 16, 0, W]]},
}

const DEFAULT_TOKENS := {"accent": "#b5523f", "accent2": "#d98b6a"}


static func has(kind: String) -> bool:
	return PRESETS.has(kind)


static func size_of(kind: String) -> Vector2:
	return PRESETS[kind].size if PRESETS.has(kind) else Vector2.ONE


static func draw(ci: CanvasItem, o: Vector2, kind: String, at: Vector2, spec: Dictionary) -> void:
	for p in PRESETS[kind].parts:
		IsoDraw.box(ci, o, at + Vector2(p[0], p[1]), Vector2(p[2], p[3]), p[4], color(p[6], spec), p[5])


static func color(c, spec: Dictionary) -> Color:
	if c is Color:
		return c
	var s := str(c)
	if s.begins_with("$"):
		var key := s.substr(1)
		var v = spec.get(key, DEFAULT_TOKENS.get(key, "#ff00ff"))
		return v if v is Color else Color(str(v))
	return Color(s)
