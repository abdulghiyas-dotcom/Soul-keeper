class_name IsoGround
extends Node2D
## Draws everything flat or behind the action: floor tiles, paths, ponds,
## rugs, the island edge, and (indoors) the two back walls with their decor.

var map  # IsoMap


func _draw() -> void:
	var d: Dictionary = map.data
	var size: Vector2i = d.size
	var o := Vector2.ZERO
	var outdoor: bool = d.get("outdoor", true)

	# island / floor thickness
	var side := Palette.EARTH if outdoor else Color("#6b5240")
	IsoDraw.quad(self, IsoDraw.pt(o, 0, size.y, 0), IsoDraw.pt(o, size.x, size.y, 0),
		IsoDraw.pt(o, size.x, size.y, -20), IsoDraw.pt(o, 0, size.y, -20), side)
	IsoDraw.quad(self, IsoDraw.pt(o, size.x, size.y, 0), IsoDraw.pt(o, size.x, 0, 0),
		IsoDraw.pt(o, size.x, 0, -20), IsoDraw.pt(o, size.x, size.y, -20), side.darkened(0.2))

	var paths := {}
	for t in d.get("paths", []):
		paths[t] = true
	for x in size.x:
		for y in size.y:
			var col: Color
			if outdoor:
				col = Palette.PATH if paths.has(Vector2i(x, y)) else (
					Palette.GRASS_A if (x + y) % 2 == 0 else Palette.GRASS_B)
			else:
				col = Palette.FLOOR_A if x % 2 == 0 else Palette.FLOOR_B
			IsoDraw.diamond(self, o, Vector2(x, y), Vector2.ONE, col)

	if d.has("walls"):
		_walls(d.walls, size)

	for dec in d.get("decals", []):
		_decal(dec)


func _decal(dec: Dictionary) -> void:
	var o := Vector2.ZERO
	var p: Vector2 = dec.pos
	var s: Vector2 = dec.size
	match str(dec.kind):
		"pond":
			IsoDraw.diamond(self, o, p, s, Color("#c9b88f"))
			IsoDraw.diamond(self, o, p + Vector2(0.15, 0.15), s - Vector2(0.3, 0.3), Palette.WATER)
			IsoDraw.diamond(self, o, p + Vector2(0.6, 0.6), Vector2(0.6, 0.4), Palette.WATER.lightened(0.3))
		"plot":
			IsoDraw.diamond(self, o, p, s, Color("#b89a78"))
			IsoDraw.diamond(self, o, p + Vector2(0.2, 0.2), s - Vector2(0.4, 0.4), Color("#a8896a"))
			for i in 6:
				var q := IsoDraw.pt(o, p.x + 0.6 + (i % 3) * 1.2, p.y + 0.8 + (i / 3) * 1.6)
				draw_circle(q + Vector2(-2, -3), 2.5, Color("#7fb877"), true, -1.0, true)
				draw_circle(q + Vector2(2, -4), 2.5, Color("#86c07c"), true, -1.0, true)
		"rug":
			var c := Furniture.color(dec.get("accent", "#b5523f"), dec)
			IsoDraw.diamond(self, o, p, s, c)
			IsoDraw.diamond(self, o, p + Vector2(0.15, 0.15), s - Vector2(0.3, 0.3), c.lightened(0.25))
			IsoDraw.diamond(self, o, p + Vector2(0.4, 0.4), s - Vector2(0.8, 0.8), c)
		"mat":
			IsoDraw.diamond(self, o, p, s, Color("#9e7a5a"))


func _walls(w: Dictionary, size: Vector2i) -> void:
	var o := Vector2.ZERO
	var col: Color = w.color
	var h := 112.0
	IsoDraw.box(self, o, Vector2(-0.25, -0.25), Vector2(size.x + 0.25, 0.25), h, col.lightened(0.1))
	IsoDraw.box(self, o, Vector2(-0.25, 0), Vector2(0.25, size.y), h, col.lightened(0.18))
	# skirting boards
	IsoDraw.face_y(self, o, 0, 0, size.x, 0, 8, col.darkened(0.25))
	IsoDraw.face_x(self, o, 0, 0, size.y, 0, 8, col.darkened(0.35))
	for dec in w.get("decor", []):
		_wall_decor(dec)


func _wall_decor(dec: Dictionary) -> void:
	var o := Vector2.ZERO
	var a: float = dec.a
	var b: float = dec.b
	var za: float = dec.za
	var zb: float = dec.zb
	var on_y: bool = dec.wall == "y"
	var frame := Color("#fbf6ec")
	var inner: Color
	match str(dec.kind):
		"window": inner = Color("#a9d2e0")
		"painting": frame = Color("#8a6446"); inner = Furniture.color(dec.get("accent", "#e0b65c"), dec)
		"blackboard": frame = Color("#8a6446"); inner = Color("#3f5a4c")
		"mirror": frame = Color("#c49a4a"); inner = Color("#d8ecf0")
		"cross": frame = Color("#ffffff"); inner = Color("#d0544a")
		_: inner = Color.GRAY
	_rect(on_y, a, b, za, zb, frame)
	if dec.kind == "cross":
		var m := (a + b) * 0.5
		var mz := (za + zb) * 0.5
		_rect(on_y, m - 0.08, m + 0.08, za + 4, zb - 4, inner)
		_rect(on_y, a + 0.1, b - 0.1, mz - 4, mz + 4, inner)
		return
	_rect(on_y, a + 0.08, b - 0.08, za + 4, zb - 4, inner)
	if dec.kind == "window":
		var m := (a + b) * 0.5
		_rect(on_y, m - 0.03, m + 0.03, za, zb, frame)
		_rect(on_y, a, b, (za + zb) * 0.5 - 1.5, (za + zb) * 0.5 + 1.5, frame)
	elif dec.kind == "painting":
		var q := _pt(on_y, a + (b - a) * 0.65, za + (zb - za) * 0.65)
		draw_circle(q, 4, Color("#fbf6ec"), true, -1.0, true)
		_rect(on_y, a + 0.1, b - 0.1, za + 4, za + 10, Color("#86b38a"))
	elif dec.kind == "blackboard":
		for i in 3:
			var z := zb - 12 - i * 9
			draw_line(_pt(on_y, a + 0.3, z), _pt(on_y, a + 0.3 + (b - a) * (0.5 - i * 0.1), z), Color(1, 1, 1, 0.7), 1.5)


func _pt(on_y: bool, s: float, z: float) -> Vector2:
	return IsoDraw.pt(Vector2.ZERO, s, 0, z) if on_y else IsoDraw.pt(Vector2.ZERO, 0, s, z)


func _rect(on_y: bool, a: float, b: float, za: float, zb: float, c: Color) -> void:
	if on_y:
		IsoDraw.face_y(self, Vector2.ZERO, 0, a, b, za, zb, c)
	else:
		IsoDraw.face_x(self, Vector2.ZERO, 0, a, b, za, zb, c)
