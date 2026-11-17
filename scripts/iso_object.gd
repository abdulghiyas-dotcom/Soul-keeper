class_name IsoObject
extends Node2D
## One thing standing in the world (tree, house, bed...). Drawn with
## placeholder geometry. Positioned at the centre of its footprint so the
## parent's y-sort puts the avatar correctly in front of / behind it.

var spec: Dictionary
var gpos: Vector2
var gsize: Vector2


func setup(s: Dictionary) -> IsoObject:
	spec = s
	gpos = s.pos
	gsize = s.get("size", Furniture.size_of(s.kind))
	position = Iso.to_screen(gpos + gsize * 0.5)
	return self


func footprint() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(floori(gpos.x), ceili(gpos.x + gsize.x)):
		for y in range(floori(gpos.y), ceili(gpos.y + gsize.y)):
			tiles.append(Vector2i(x, y))
	return tiles


func _draw() -> void:
	var o := position
	match str(spec.kind):
		"tree": _tree()
		"bush": _bush()
		"plant": _plant(o)
		"flowers": _flowers(o)
		"lamp": _lamp(o)
		"house": _house(o)
		"building": _building(o)
		"sign": _sign(o)
		"easel": _easel(o)
		"mannequin": _mannequin(o)
		var kind:
			if Furniture.has(kind):
				Furniture.draw(self, o, kind, gpos, spec)


# --- nature -----------------------------------------------------------------

func _variant() -> int:
	return int(absf(gpos.x * 7.0 + gpos.y * 13.0)) % 3


func _tree() -> void:
	var v := _variant()
	var k := 0.9 + 0.12 * v
	var greens := [Color("#6fa86a"), Color("#7fb877"), Color("#5f9a63")]
	var g: Color = greens[v]
	IsoDraw.shadow(self, Vector2.ZERO, 24 * k)
	IsoDraw.box(self, position, gpos + gsize * 0.5 - Vector2(0.1, 0.1), Vector2(0.2, 0.2), 34 * k, Color("#8a6446"))
	draw_circle(Vector2(-13, -44) * k, 17 * k, g.darkened(0.12), true, -1.0, true)
	draw_circle(Vector2(13, -46) * k, 17 * k, g.darkened(0.08), true, -1.0, true)
	draw_circle(Vector2(0, -56) * k, 22 * k, g, true, -1.0, true)
	draw_circle(Vector2(-6, -64) * k, 10 * k, g.lightened(0.15), true, -1.0, true)
	if v == 1:  # pomegranate tree
		for p in [Vector2(-14, -44), Vector2(10, -50), Vector2(2, -38), Vector2(-4, -58)]:
			draw_circle(p * k, 3.2, Color("#c94a4a"), true, -1.0, true)


func _bush() -> void:
	var g := Color("#7fb877")
	IsoDraw.shadow(self, Vector2.ZERO, 16)
	draw_circle(Vector2(-8, -8), 10, g.darkened(0.1), true, -1.0, true)
	draw_circle(Vector2(8, -9), 10, g.darkened(0.05), true, -1.0, true)
	draw_circle(Vector2(0, -14), 12, g, true, -1.0, true)


func _plant(o: Vector2) -> void:
	var c := gpos + gsize * 0.5
	IsoDraw.box(self, o, c - Vector2(0.2, 0.2), Vector2(0.4, 0.4), 16, Color("#c07a55"))
	var g := Color("#6fa86a")
	draw_circle(Vector2(-8, -28), 8, g.darkened(0.1), true, -1.0, true)
	draw_circle(Vector2(8, -29), 8, g.darkened(0.05), true, -1.0, true)
	draw_circle(Vector2(0, -36), 10, g, true, -1.0, true)


func _flowers(o: Vector2) -> void:
	IsoDraw.box(self, o, gpos, gsize, 7, Color("#8b6a4e"))
	var cols := [Color("#f2a7b8"), Color("#f7d775"), Color("#ffffff"), Color("#b79be0"), Color("#f08a6c")]
	var i := 0
	var y := gpos.y + 0.2
	while y < gpos.y + gsize.y:
		var x := gpos.x + 0.2
		while x < gpos.x + gsize.x:
			var p := IsoDraw.pt(o, x, y, 10)
			draw_circle(p + Vector2(0, 2), 2.2, Color("#5f9a63"), true, -1.0, true)
			draw_circle(p, 3.2, cols[i % cols.size()], true, -1.0, true)
			i += 1
			x += 0.3
		y += 0.3


func _lamp(o: Vector2) -> void:
	var c := gpos + gsize * 0.5
	IsoDraw.shadow(self, Vector2.ZERO, 8)
	IsoDraw.box(self, o, c - Vector2(0.06, 0.06), Vector2(0.12, 0.12), 62, Color("#4d4a52"))
	draw_circle(Vector2(0, -68), 14, Color(1.0, 0.9, 0.55, 0.22), true, -1.0, true)
	draw_circle(Vector2(0, -68), 6, Color("#ffe39a"), true, -1.0, true)


# --- buildings ----------------------------------------------------------------

func _house(o: Vector2) -> void:
	var wall: Color = spec.wall
	var roof: Color = spec.roof
	var x0 := gpos.x
	var y0 := gpos.y
	var x1 := gpos.x + gsize.x
	var y1 := gpos.y + gsize.y
	var h := 70.0
	IsoDraw.box(self, o, gpos, gsize, h, wall)
	# door (on the front-left face) and windows
	var dx: float = spec.door.x
	IsoDraw.face_y(self, o, y1, dx + 0.15, dx + 0.85, 0, 42, Color("#7a5236"))
	IsoDraw.face_y(self, o, y1, dx + 0.22, dx + 0.78, 4, 38, Color("#8f6444"))
	draw_circle(IsoDraw.pt(o, dx + 0.7, y1, 21), 1.8, Color("#e8c66a"), true, -1.0, true)
	for wx in [x0 + 0.6, x1 - 1.4]:
		if absf(wx - dx) > 1.0:
			_window_y(o, y1, wx, wx + 0.8, 26, 52)
	for wy in [y0 + 0.8, y1 - 1.6]:
		_window_x(o, x1, wy, wy + 0.8, 26, 52)
	# gable roof, ridge along x
	var e := 0.18
	var ym := (y0 + y1) * 0.5
	var zr := h + 44.0
	IsoDraw.quad(self, IsoDraw.pt(o, x0 - e, y0 - e, h), IsoDraw.pt(o, x1 + e, y0 - e, h),
		IsoDraw.pt(o, x1 + e, ym, zr), IsoDraw.pt(o, x0 - e, ym, zr), roof.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([IsoDraw.pt(o, x1, y1, h), IsoDraw.pt(o, x1, y0, h),
		IsoDraw.pt(o, x1, ym, zr)]), wall.darkened(0.24))
	_window_round(IsoDraw.pt(o, x1, ym, h + 16))
	IsoDraw.quad(self, IsoDraw.pt(o, x0 - e, y1 + e, h), IsoDraw.pt(o, x1 + e, y1 + e, h),
		IsoDraw.pt(o, x1 + e, ym, zr), IsoDraw.pt(o, x0 - e, ym, zr), roof)
	draw_line(IsoDraw.pt(o, x0 - e, ym, zr), IsoDraw.pt(o, x1 + e, ym, zr), roof.lightened(0.25), 2.0)


func _building(o: Vector2) -> void:
	var col: Color = spec.color
	var wall := col.lightened(0.62)
	var x1 := gpos.x + gsize.x
	var y1 := gpos.y + gsize.y
	var h := 78.0
	IsoDraw.box(self, o, gpos, gsize, h, wall)
	IsoDraw.box(self, o, gpos - Vector2(0.12, 0.12), gsize + Vector2(0.24, 0.24), 8, col.darkened(0.1), h)
	var dx: float = spec.door.x
	# big windows on both faces
	_window_y(o, y1, gpos.x + 0.3, dx - 0.15, 20, 56)
	if x1 - (dx + 1.15) > 0.5:
		_window_y(o, y1, dx + 1.15, x1 - 0.3, 20, 56)
	_window_x(o, x1, gpos.y + 0.4, y1 - 0.4, 20, 56)
	# door
	IsoDraw.face_y(self, o, y1, dx + 0.1, dx + 0.9, 0, 46, col.darkened(0.35))
	IsoDraw.face_y(self, o, y1, dx + 0.18, dx + 0.82, 4, 42, Color("#cfe6ee"))
	# striped awning above the door
	for i in 4:
		var a := dx - 0.1 + i * 0.3
		var c := col if i % 2 == 0 else Color("#fbf6ec")
		IsoDraw.quad(self, IsoDraw.pt(o, a, y1, 58), IsoDraw.pt(o, a + 0.3, y1, 58),
			IsoDraw.pt(o, a + 0.3, y1 + 0.45, 48), IsoDraw.pt(o, a, y1 + 0.45, 48), c)
	# sign board with emblem
	IsoDraw.face_y(self, o, y1, gpos.x + 0.6, x1 - 0.6, 62, 76, Color("#fbf6ec"))
	var em := IsoDraw.pt(o, (gpos.x + x1) * 0.5, y1, 69)
	draw_circle(em, 6, col, true, -1.0, true)
	if spec.get("career", "") == "clinic":
		draw_rect(Rect2(em - Vector2(1.5, 4.5), Vector2(3, 9)), Color.WHITE)
		draw_rect(Rect2(em - Vector2(4.5, 1.5), Vector2(9, 3)), Color.WHITE)


func _window_y(o: Vector2, y: float, xa: float, xb: float, za: float, zb: float) -> void:
	IsoDraw.face_y(self, o, y, xa, xb, za, zb, Color("#fbf6ec"))
	IsoDraw.face_y(self, o, y, xa + 0.07, xb - 0.07, za + 3, zb - 3, Color("#a9d2e0"))
	draw_line(IsoDraw.pt(o, (xa + xb) * 0.5, y, za), IsoDraw.pt(o, (xa + xb) * 0.5, y, zb), Color("#fbf6ec"), 2)


func _window_x(o: Vector2, x: float, ya: float, yb: float, za: float, zb: float) -> void:
	IsoDraw.face_x(self, o, x, ya, yb, za, zb, Color("#ece5d8"))
	IsoDraw.face_x(self, o, x, ya + 0.07, yb - 0.07, za + 3, zb - 3, Color("#8fbccc"))
	draw_line(IsoDraw.pt(o, x, (ya + yb) * 0.5, za), IsoDraw.pt(o, x, (ya + yb) * 0.5, zb), Color("#ece5d8"), 2)


func _window_round(c: Vector2) -> void:
	draw_circle(c, 7, Color("#ece5d8"), true, -1.0, true)
	draw_circle(c, 5, Color("#8fbccc"), true, -1.0, true)


# --- small props --------------------------------------------------------------

func _sign(o: Vector2) -> void:
	var c := gpos + gsize * 0.5
	IsoDraw.shadow(self, Vector2.ZERO, 8)
	IsoDraw.box(self, o, c - Vector2(0.05, 0.05), Vector2(0.1, 0.1), 30, Color("#8a6446"))
	IsoDraw.box(self, o, c - Vector2(0.45, 0.04), Vector2(0.9, 0.08), 22, Color("#e8d2a8"), 26)
	var p := IsoDraw.pt(o, c.x, c.y + 0.04, 37)
	draw_line(p - Vector2(5, 0), p + Vector2(5, 0), Color("#7a5236"), 2.5)
	draw_line(p - Vector2(0, 5), p + Vector2(0, 5), Color("#7a5236"), 2.5)


func _easel(o: Vector2) -> void:
	var c := gpos + gsize * 0.5
	var leg := Color("#8a6446")
	IsoDraw.shadow(self, Vector2.ZERO, 14)
	draw_line(IsoDraw.pt(o, c.x - 0.3, c.y, 0), IsoDraw.pt(o, c.x, c.y, 66), leg, 2.5)
	draw_line(IsoDraw.pt(o, c.x + 0.3, c.y, 0), IsoDraw.pt(o, c.x, c.y, 66), leg, 2.5)
	draw_line(IsoDraw.pt(o, c.x, c.y - 0.3, 0), IsoDraw.pt(o, c.x, c.y, 60), leg, 2.5)
	IsoDraw.face_y(self, o, c.y + 0.05, c.x - 0.4, c.x + 0.4, 26, 62, Color("#fbf6ec"))
	IsoDraw.face_y(self, o, c.y + 0.05, c.x - 0.32, c.x + 0.32, 30, 44, Color("#a9d2e0"))
	IsoDraw.face_y(self, o, c.y + 0.05, c.x - 0.32, c.x + 0.32, 30, 36, Color("#86b38a"))
	draw_circle(IsoDraw.pt(o, c.x + 0.12, c.y + 0.05, 52), 4, Color("#f2c46b"), true, -1.0, true)


func _mannequin(o: Vector2) -> void:
	var c := gpos + gsize * 0.5
	var dress := Furniture.color(spec.get("accent", "#d98b8b"), spec)
	IsoDraw.shadow(self, Vector2.ZERO, 10)
	IsoDraw.ellipse(self, Vector2(0, -2), 9, 4, Color("#8a6446"))
	draw_line(Vector2(0, -2), Vector2(0, -20), Color("#8a6446"), 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -50), Vector2(7, -50), Vector2(12, -18), Vector2(-12, -18)]), dress)
	draw_circle(Vector2(0, -56), 6, Color("#e8dccb"), true, -1.0, true)
