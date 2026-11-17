class_name IsoDraw
extends RefCounted
## Drawing primitives for the placeholder art: isometric boxes, tiles, faces.
## `o` is the screen-space origin to subtract (the drawing node's position),
## `z` is height above the ground in pixels.
## These are the only functions that need replacing when real art arrives.


static func pt(o: Vector2, x: float, y: float, z: float = 0.0) -> Vector2:
	return Iso.to_screen(Vector2(x, y)) - o - Vector2(0, z)


static func quad(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([a, b, c, d]), col)


## Flat diamond (top of a tile area) at height z.
static func diamond(ci: CanvasItem, o: Vector2, g0: Vector2, sz: Vector2, col: Color, z := 0.0) -> void:
	quad(ci, pt(o, g0.x, g0.y, z), pt(o, g0.x + sz.x, g0.y, z),
		pt(o, g0.x + sz.x, g0.y + sz.y, z), pt(o, g0.x, g0.y + sz.y, z), col)


## Solid box: footprint g0..g0+sz, height h, lifted by z. Light comes from the left.
static func box(ci: CanvasItem, o: Vector2, g0: Vector2, sz: Vector2, h: float, col: Color, z := 0.0) -> void:
	var x0 := g0.x
	var y0 := g0.y
	var x1 := g0.x + sz.x
	var y1 := g0.y + sz.y
	if h > 0.0:
		quad(ci, pt(o, x0, y1, z), pt(o, x1, y1, z), pt(o, x1, y1, z + h), pt(o, x0, y1, z + h),
			col.darkened(0.10))
		quad(ci, pt(o, x1, y1, z), pt(o, x1, y0, z), pt(o, x1, y0, z + h), pt(o, x1, y1, z + h),
			col.darkened(0.24))
	diamond(ci, o, g0, sz, col.lightened(0.06), z + h)


## Rectangle painted on a left-facing face (plane y = const), e.g. a door.
static func face_y(ci: CanvasItem, o: Vector2, y: float, xa: float, xb: float, za: float, zb: float, col: Color) -> void:
	quad(ci, pt(o, xa, y, za), pt(o, xb, y, za), pt(o, xb, y, zb), pt(o, xa, y, zb), col)


## Rectangle painted on a right-facing face (plane x = const).
static func face_x(ci: CanvasItem, o: Vector2, x: float, ya: float, yb: float, za: float, zb: float, col: Color) -> void:
	quad(ci, pt(o, x, ya, za), pt(o, x, yb, za), pt(o, x, yb, zb), pt(o, x, ya, zb), col)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, segments := 24) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ellipse(ci, c, rx, rx * 0.5, Color(0.1, 0.15, 0.1, 0.16))
