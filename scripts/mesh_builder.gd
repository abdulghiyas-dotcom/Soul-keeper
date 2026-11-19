class_name MeshBuilder
extends RefCounted
## Builds one merged, vertex-coloured, flat-shaded (low-poly) mesh from many
## simple shapes. A whole place becomes a handful of meshes, which keeps phones fast.
## Units: 1 = one tile. Y is up.

var _st := SurfaceTool.new()
var _empty := true


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


func is_empty() -> bool:
	return _empty


func commit() -> ArrayMesh:
	return _st.commit() if not _empty else null


## Triangle given counter-clockwise as seen from its front side.
func tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	_st.set_color(col)
	_st.set_normal(n)
	# Godot treats clockwise as front-facing, so emit a, c, b.
	_st.add_vertex(a)
	_st.add_vertex(c)
	_st.add_vertex(b)
	_empty = false


## Quad a-b-c-d; flips itself if needed so it faces `outward`.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, outward := Vector3.ZERO) -> void:
	if outward != Vector3.ZERO and (b - a).cross(c - a).dot(outward) < 0.0:
		tri(a, c, b, col)
		tri(a, d, c, col)
	else:
		tri(a, b, c, col)
		tri(a, c, d, col)


func box(min_corner: Vector3, size: Vector3, col: Color, bottom := false) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return
	var p := min_corner
	var q := min_corner + size
	var c := [Vector3(p.x, p.y, p.z), Vector3(q.x, p.y, p.z), Vector3(q.x, p.y, q.z), Vector3(p.x, p.y, q.z),
		Vector3(p.x, q.y, p.z), Vector3(q.x, q.y, p.z), Vector3(q.x, q.y, q.z), Vector3(p.x, q.y, q.z)]
	quad(c[4], c[5], c[6], c[7], col.lightened(0.04), Vector3.UP)
	quad(c[3], c[2], c[6], c[7], col, Vector3.BACK)        # +z
	quad(c[1], c[2], c[6], c[5], col.darkened(0.06), Vector3.RIGHT)  # +x
	quad(c[0], c[1], c[5], c[4], col, Vector3.FORWARD)     # -z
	quad(c[0], c[3], c[7], c[4], col, Vector3.LEFT)        # -x
	if bottom:
		quad(c[0], c[1], c[2], c[3], col, Vector3.DOWN)


## Box given by its bottom-centre.
func box_c(base_center: Vector3, size: Vector3, col: Color) -> void:
	box(base_center - Vector3(size.x * 0.5, 0, size.z * 0.5), size, col)


## Cylinder / cone frustum standing on `base`. r_top = 0 makes a cone.
func cylinder(base: Vector3, r_bottom: float, r_top: float, h: float, col: Color, segments := 10) -> void:
	var top := base + Vector3(0, h, 0)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var out := (d0 + d1).normalized()
		if r_top > 0.0:
			quad(base + d0 * r_bottom, base + d1 * r_bottom, top + d1 * r_top, top + d0 * r_top, col, out)
			_cap(top, top + d0 * r_top, top + d1 * r_top, col.lightened(0.04))
		else:
			var a := base + d0 * r_bottom
			var b := base + d1 * r_bottom
			if (b - a).cross(top - a).dot(out) < 0.0:
				tri(a, top, b, col)
			else:
				tri(a, b, top, col)


func _cap(center: Vector3, a: Vector3, b: Vector3, col: Color) -> void:
	if (a - center).cross(b - center).dot(Vector3.UP) < 0.0:
		tri(center, a, b, col)
	else:
		tri(center, b, a, col)


## Low-poly sphere (or ellipsoid with `scale`).
func sphere(center: Vector3, r: float, col: Color, scale := Vector3.ONE, rings := 5, segments := 8) -> void:
	for j in rings:
		var t0 := PI * j / rings
		var t1 := PI * (j + 1) / rings
		for i in segments:
			var p0 := TAU * i / segments
			var p1 := TAU * (i + 1) / segments
			var v := func(t: float, p: float) -> Vector3:
				return center + Vector3(sin(t) * cos(p), cos(t), sin(t) * sin(p)) * r * scale
			var a: Vector3 = v.call(t0, p0)
			var b: Vector3 = v.call(t0, p1)
			var c: Vector3 = v.call(t1, p1)
			var d: Vector3 = v.call(t1, p0)
			var out := ((a + b + c + d) * 0.25 - center).normalized()
			var shade := col.lightened(0.05) if out.y > 0.3 else (col.darkened(0.05) if out.y < -0.3 else col)
			if j == 0:
				_face(a, c, d, shade, out)
			elif j == rings - 1:
				_face(a, b, c, shade, out)
			else:
				quad(a, b, c, d, shade, out)


func _face(a: Vector3, b: Vector3, c: Vector3, col: Color, out: Vector3) -> void:
	if (b - a).cross(c - a).dot(out) < 0.0:
		tri(a, c, b, col)
	else:
		tri(a, b, c, col)


## Gable roof: ridge along X over the rectangle [x0,x1] x [z0,z1], starting at height y.
func gable_roof(x0: float, x1: float, z0: float, z1: float, y: float, h: float, col: Color, gable_col: Color) -> void:
	var zm := (z0 + z1) * 0.5
	var r0 := Vector3(x0, y + h, zm)
	var r1 := Vector3(x1, y + h, zm)
	quad(Vector3(x0, y, z1), Vector3(x1, y, z1), r1, r0, col, Vector3(0, 1, 1))            # front slope
	quad(Vector3(x0, y, z0), Vector3(x1, y, z0), r1, r0, col.darkened(0.12), Vector3(0, 1, -1))  # back slope
	_face(Vector3(x1, y, z0), Vector3(x1, y, z1), r1, gable_col, Vector3.RIGHT)
	_face(Vector3(x0, y, z0), Vector3(x0, y, z1), r0, gable_col, Vector3.LEFT)
	quad(Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1), col.darkened(0.3), Vector3.DOWN)


## Upright triangle facing +Z (a pediment), given base corners and apex height.
func pediment(x0: float, x1: float, z: float, y: float, h: float, depth: float, col: Color) -> void:
	var xm := (x0 + x1) * 0.5
	var f := [Vector3(x0, y, z), Vector3(x1, y, z), Vector3(xm, y + h, z)]
	var b := [Vector3(x0, y, z - depth), Vector3(x1, y, z - depth), Vector3(xm, y + h, z - depth)]
	_face(f[0], f[1], f[2], col, Vector3.BACK)
	quad(f[1], b[1], b[2], f[2], col.darkened(0.06), Vector3(1, 1, 0))
	quad(f[0], b[0], b[2], f[2], col, Vector3(-1, 1, 0))


## Flat disc lying at height y.
func disc(center: Vector3, r: float, col: Color, segments := 16) -> void:
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		_cap(center, center + Vector3(cos(a0), 0, sin(a0)) * r, center + Vector3(cos(a1), 0, sin(a1)) * r, col)


## Soft-edged flat polygon at height y (for drawn shadows). `pts` is a convex outline
## in grid (x, z); the colour's alpha fades to 0 over `feather` at the edge.
func soft_polygon(pts: Array, y: float, col: Color, feather := 0.18) -> void:
	if pts.size() < 3:
		return
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	var edge := Color(col, 0.0)
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var ai := a.move_toward(c, feather)
		var bi := b.move_toward(c, feather)
		_flat_tri(Vector3(c.x, y, c.y), Vector3(ai.x, y, ai.y), Vector3(bi.x, y, bi.y), col, col, col)
		_flat_tri(Vector3(ai.x, y, ai.y), Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), col, edge, edge)
		_flat_tri(Vector3(ai.x, y, ai.y), Vector3(b.x, y, b.y), Vector3(bi.x, y, bi.y), col, edge, col)


func soft_disc(center: Vector2, r: float, y: float, col: Color, squash := 1.0) -> void:
	var pts := []
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(center + Vector2(cos(a) * r, sin(a) * r * squash))
	soft_polygon(pts, y, col, r * 0.45)


func _flat_tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	_st.set_normal(Vector3.UP)
	_st.set_color(ca)
	_st.add_vertex(a)
	_st.set_color(cc)
	_st.add_vertex(c)
	_st.set_color(cb)
	_st.add_vertex(b)
	_empty = false
