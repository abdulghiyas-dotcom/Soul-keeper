class_name ObjectMeshes
extends RefCounted
## Turns world data into low-poly 3D shapes (see MeshBuilder).
## `mb` gets normal surfaces, `gb` gets softly glowing ones (window glass, lamps),
## and water areas are added to `water` as {"rect": Rect2, "y": height} or {"disc": ...}.

const U := 1.0 / 48.0  # converts heights from the old 2D pixel data into tiles
const STONE := Color("#d9d2c5")
const BROWN := Color("#8a6446")
const CREAM := Color("#f5efe4")
const GLASS := Color("#bfe3f0")


static func c(hex: String) -> Color:
	return Color(hex)


static func _variant(p: Vector2) -> int:
	return int(absf(p.x * 7.0 + p.y * 13.0)) % 3


# --- objects ----------------------------------------------------------------------

static func add_object(spec: Dictionary, mb: MeshBuilder, gb: MeshBuilder, water: Array) -> void:
	var kind := str(spec.kind)
	var p: Vector2 = spec.pos
	var s := MapGrid.size_of(spec)
	var ctr := Vector3(p.x + s.x * 0.5, 0, p.y + s.y * 0.5)
	match kind:
		"tree": _tree(mb, ctr, _variant(p) if not spec.has("user") else [0, 2][_variant(p) % 2], p)
		"fruit_tree": _tree(mb, ctr, 1, p)
		"bush": _bush(mb, ctr)
		"plant": _plant(mb, ctr)
		"flowers": _flowers(mb, p, s)
		"lamp": _lamp(mb, gb, ctr)
		"house": _house(mb, gb, spec, p, s)
		"building": _building(mb, gb, spec, p, s)
		"sign": _sign(mb, ctr)
		"easel": _easel(mb, ctr)
		"mannequin": _mannequin(mb, ctr, Furniture.color(spec.get("accent", "#d98b8b"), spec))
		"arch": _arch(mb, spec, p, s)
		"fountain": _fountain(mb, gb, water, ctr, s)
		"stall": _stall(mb, p, s, Furniture.color(spec.get("accent", "#c8604a"), spec))
		"rock": _rock(mb, ctr)
		"globe": _globe(mb, ctr)
		_:
			if Furniture.has(kind):
				for part in Furniture.PRESETS[kind].parts:
					mb.box(Vector3(p.x + part[0], part[5] * U, p.y + part[1]),
						Vector3(part[2], part[4] * U, part[3]), Furniture.color(part[6], spec))


static func _tree(mb: MeshBuilder, ctr: Vector3, v: int, p: Vector2) -> void:
	var k := 0.9 + 0.12 * v
	var greens := [c("#6fa86a"), c("#7fb877"), c("#5f9a63")]
	var g: Color = greens[v]
	var rot := float(int(p.x * 3 + p.y * 5) % 7) * 0.9
	var off := func(x: float, z: float) -> Vector3:
		return Vector3(x * cos(rot) - z * sin(rot), 0, x * sin(rot) + z * cos(rot))
	mb.cylinder(ctr, 0.09 * k, 0.06 * k, 0.85 * k, BROWN, 7)
	mb.sphere(ctr + off.call(-0.16, 0.06) + Vector3(0, 0.95 * k, 0), 0.38 * k, g.darkened(0.12))
	mb.sphere(ctr + off.call(0.18, -0.1) + Vector3(0, 1.0 * k, 0), 0.36 * k, g.darkened(0.06))
	mb.sphere(ctr + Vector3(0, 1.28 * k, 0), 0.42 * k, g)
	mb.sphere(ctr + off.call(-0.06, 0.05) + Vector3(0, 1.55 * k, 0), 0.24 * k, g.lightened(0.12))
	if v == 1:  # pomegranates
		for f in [Vector3(0.3, 1.05, 0.25), Vector3(-0.32, 0.95, 0.2), Vector3(0.1, 1.25, 0.4), Vector3(-0.1, 1.5, 0.25), Vector3(0.38, 1.3, -0.05)]:
			mb.sphere(ctr + f * k, 0.07, c("#c94a4a"), Vector3.ONE, 3, 6)


static func _bush(mb: MeshBuilder, ctr: Vector3) -> void:
	var g := c("#7fb877")
	mb.sphere(ctr + Vector3(-0.15, 0.22, 0.08), 0.27, g.darkened(0.1))
	mb.sphere(ctr + Vector3(0.16, 0.22, -0.06), 0.26, g.darkened(0.04))
	mb.sphere(ctr + Vector3(0, 0.34, 0), 0.3, g)


static func _plant(mb: MeshBuilder, ctr: Vector3) -> void:
	mb.cylinder(ctr, 0.15, 0.19, 0.3, c("#c07a55"), 10)
	mb.disc(ctr + Vector3(0, 0.29, 0), 0.17, c("#6b4a33"))
	var g := c("#6fa86a")
	mb.sphere(ctr + Vector3(-0.1, 0.46, 0.02), 0.16, g.darkened(0.1))
	mb.sphere(ctr + Vector3(0.1, 0.47, -0.02), 0.16, g.darkened(0.04))
	mb.sphere(ctr + Vector3(0, 0.6, 0), 0.18, g)


static func _flowers(mb: MeshBuilder, p: Vector2, s: Vector2) -> void:
	mb.box(Vector3(p.x, 0, p.y), Vector3(s.x, 0.14, s.y), c("#8b6a4e"))
	mb.box(Vector3(p.x + 0.05, 0.14, p.y + 0.05), Vector3(s.x - 0.1, 0.01, s.y - 0.1), c("#6b4a33"))
	var cols := [c("#f2a7b8"), c("#f7d775"), c("#ffffff"), c("#b79be0"), c("#f08a6c")]
	var i := 0
	var y := p.y + 0.18
	while y < p.y + s.y - 0.05:
		var x := p.x + 0.18
		while x < p.x + s.x - 0.05:
			mb.box_c(Vector3(x, 0.14, y), Vector3(0.02, 0.1, 0.02), c("#5f9a63"))
			mb.sphere(Vector3(x, 0.26, y), 0.065, cols[i % cols.size()], Vector3.ONE, 3, 6)
			i += 1
			x += 0.27
		y += 0.27


static func _lamp(mb: MeshBuilder, gb: MeshBuilder, ctr: Vector3) -> void:
	var dark := c("#4d4a52")
	mb.cylinder(ctr, 0.1, 0.08, 0.1, dark, 8)
	mb.cylinder(ctr + Vector3(0, 0.1, 0), 0.035, 0.03, 1.45, dark, 6)
	gb.sphere(ctr + Vector3(0, 1.62, 0), 0.12, c("#ffe7a3"))
	mb.cylinder(ctr + Vector3(0, 1.72, 0), 0.14, 0.0, 0.12, dark, 8)


static func _window_z(mb: MeshBuilder, gb: MeshBuilder, z: float, x0: float, w: float, y0: float, h: float, frame := CREAM) -> void:
	mb.box(Vector3(x0, y0, z - 0.01), Vector3(w, h, 0.05), frame)
	gb.box(Vector3(x0 + 0.07, y0 + 0.07, z), Vector3(w - 0.14, h - 0.14, 0.06), GLASS)
	mb.box(Vector3(x0 + w * 0.5 - 0.02, y0, z + 0.03), Vector3(0.04, h, 0.04), frame)
	mb.box(Vector3(x0, y0 - 0.04, z), Vector3(w, 0.05, 0.12), frame.darkened(0.1))


static func _window_x(mb: MeshBuilder, gb: MeshBuilder, x: float, z0: float, w: float, y0: float, h: float, frame := CREAM) -> void:
	mb.box(Vector3(x - 0.01, y0, z0), Vector3(0.05, h, w), frame)
	gb.box(Vector3(x, y0 + 0.07, z0 + 0.07), Vector3(0.06, h - 0.14, w - 0.14), GLASS)
	mb.box(Vector3(x + 0.03, y0, z0 + w * 0.5 - 0.02), Vector3(0.04, h, 0.04), frame)
	mb.box(Vector3(x, y0 - 0.04, z0), Vector3(0.12, 0.05, w), frame.darkened(0.1))


static func _house(mb: MeshBuilder, gb: MeshBuilder, spec: Dictionary, p: Vector2, s: Vector2) -> void:
	var wall: Color = spec.wall
	var roof: Color = spec.roof
	var x0 := p.x
	var z0 := p.y
	var x1 := p.x + s.x
	var z1 := p.y + s.y
	var h := 1.75
	mb.box(Vector3(x0 - 0.05, 0, z0 - 0.05), Vector3(s.x + 0.1, 0.16, s.y + 0.1), wall.darkened(0.22))
	mb.box(Vector3(x0, 0, z0), Vector3(s.x, h, s.y), wall)
	mb.box(Vector3(x0 - 0.04, h - 0.1, z0 - 0.04), Vector3(s.x + 0.08, 0.1, s.y + 0.08), wall.lightened(0.15))
	mb.box(Vector3(x0 + 0.8, h + 0.3, z0 + 0.55), Vector3(0.32, 0.95, 0.32), c("#a8644e"))
	mb.gable_roof(x0 - 0.22, x1 + 0.22, z0 - 0.25, z1 + 0.25, h, 1.05, roof, wall.darkened(0.05))
	# door, step and knob
	var dx: float = spec.door.x
	mb.box(Vector3(dx + 0.06, 0, z1), Vector3(0.88, 0.07, 0.4), STONE)
	mb.box(Vector3(dx + 0.16, 0.07, z1 - 0.01), Vector3(0.68, 1.15, 0.05), CREAM)
	mb.box(Vector3(dx + 0.22, 0.07, z1), Vector3(0.56, 1.06, 0.06), c("#7a5236"))
	mb.box(Vector3(dx + 0.27, 0.12, z1 + 0.05), Vector3(0.46, 0.45, 0.02), c("#8f6444"))
	mb.box(Vector3(dx + 0.27, 0.62, z1 + 0.05), Vector3(0.46, 0.45, 0.02), c("#8f6444"))
	mb.sphere(Vector3(dx + 0.7, 0.6, z1 + 0.09), 0.035, c("#e8c66a"), Vector3.ONE, 3, 6)
	for wx in [x0 + 0.55, x1 - 1.35]:
		if absf(wx - dx) > 1.0:
			_window_z(mb, gb, z1, wx, 0.8, 0.65, 0.7)
			_flower_box(mb, Vector3(wx + 0.05, 0.5, z1), Vector3(0.7, 0.13, 0.18))
	for wz in [z0 + 0.7, z1 - 1.5]:
		_window_x(mb, gb, x1, wz, 0.8, 0.65, 0.7)


static func _flower_box(mb: MeshBuilder, at: Vector3, size: Vector3) -> void:
	mb.box(at, size, c("#9b6b4a"))
	var cols := [c("#f2a7b8"), c("#f7d775"), c("#ffffff")]
	for i in 4:
		mb.sphere(at + Vector3(0.1 + i * (size.x - 0.2) / 3.0, size.y + 0.04, size.z * 0.5), 0.06, cols[i % 3], Vector3.ONE, 3, 6)


static func _building(mb: MeshBuilder, gb: MeshBuilder, spec: Dictionary, p: Vector2, s: Vector2) -> void:
	var col: Color = spec.color
	var wall := col.lightened(0.62)
	var x0 := p.x
	var z0 := p.y
	var x1 := p.x + s.x
	var z1 := p.y + s.y
	var h: float = float(spec.get("height", 78.0)) / 40.0
	mb.box(Vector3(x0 - 0.05, 0, z0 - 0.05), Vector3(s.x + 0.1, 0.14, s.y + 0.1), wall.darkened(0.25))
	mb.box(Vector3(x0, 0, z0), Vector3(s.x, h, s.y), wall)
	mb.box(Vector3(x0 - 0.12, h, z0 - 0.12), Vector3(s.x + 0.24, 0.16, s.y + 0.24), col.darkened(0.1))
	mb.box(Vector3(x0 - 0.12, h + 0.16, z0 - 0.12), Vector3(s.x + 0.24, 0.1, 0.12), col.darkened(0.2))
	var dx: float = spec.door.x
	if spec.get("columns", false):
		_columns(mb, gb, p, s, h, col)
		_window_x(mb, gb, x1, z0 + 0.4, s.y - 0.8, 0.6, h - 1.1)
		return
	# big windows and a glass door
	if dx - 0.15 - (x0 + 0.3) > 0.4:
		_window_z(mb, gb, z1, x0 + 0.3, dx - 0.15 - (x0 + 0.3), 0.55, 1.0)
	if x1 - 0.3 - (dx + 1.15) > 0.4:
		_window_z(mb, gb, z1, dx + 1.15, x1 - 0.3 - (dx + 1.15), 0.55, 1.0)
	_window_x(mb, gb, x1, z0 + 0.4, s.y - 0.8, 0.55, 1.0)
	mb.box(Vector3(dx + 0.08, 0, z1 - 0.01), Vector3(0.84, 1.3, 0.05), col.darkened(0.35))
	gb.box(Vector3(dx + 0.16, 0.05, z1), Vector3(0.68, 1.18, 0.06), GLASS)
	# striped awning over the door
	for i in 4:
		var a := dx - 0.1 + i * 0.3
		var stripe := col if i % 2 == 0 else Color("#fbf6ec")
		mb.quad(Vector3(a, 1.55, z1), Vector3(a + 0.3, 1.55, z1), Vector3(a + 0.3, 1.3, z1 + 0.55),
			Vector3(a, 1.3, z1 + 0.55), stripe, Vector3(0, 1, 1))
		mb.quad(Vector3(a, 1.55, z1), Vector3(a + 0.3, 1.55, z1), Vector3(a + 0.3, 1.3, z1 + 0.55),
			Vector3(a, 1.3, z1 + 0.55), stripe.darkened(0.2), Vector3(0, -1, -1))
	# sign with emblem
	mb.box(Vector3(x0 + 0.6, h - 0.5, z1), Vector3(s.x - 1.2, 0.36, 0.06), Color("#fbf6ec"))
	_emblem(mb, Vector3((x0 + x1) * 0.5, h - 0.32, z1 + 0.07), col, str(spec.get("emblem", spec.get("career", ""))))


static func _emblem(mb: MeshBuilder, at: Vector3, col: Color, kind: String) -> void:
	mb.sphere(at, 0.15, col, Vector3(1, 1, 0.3), 3, 10)
	match kind:
		"clinic":
			mb.box_c(at + Vector3(0, -0.09, 0.04), Vector3(0.05, 0.18, 0.03), Color.WHITE)
			mb.box_c(at + Vector3(0, -0.025, 0.04), Vector3(0.18, 0.05, 0.03), Color.WHITE)
		"book":
			mb.box(at + Vector3(-0.09, -0.06, 0.04), Vector3(0.08, 0.12, 0.02), Color.WHITE)
			mb.box(at + Vector3(0.01, -0.06, 0.04), Vector3(0.08, 0.12, 0.02), Color.WHITE)


static func _columns(mb: MeshBuilder, gb: MeshBuilder, p: Vector2, s: Vector2, h: float, col: Color) -> void:
	var x0 := p.x + 0.5
	var x1 := p.x + s.x - 0.5
	var z1 := p.y + s.y
	var stone := Color("#f3eee4")
	mb.box(Vector3(x0, 0, z1), Vector3(x1 - x0, 0.1, 0.75), stone.darkened(0.1))
	mb.box(Vector3(x0 + 0.15, 0.1, z1), Vector3(x1 - x0 - 0.3, 0.1, 0.5), stone.darkened(0.05))
	_window_z(mb, gb, z1, p.x + 1.0, 1.0, 0.7, 1.1)
	_window_z(mb, gb, z1, p.x + s.x - 2.0, 1.0, 0.7, 1.1)
	mb.box(Vector3(p.x + s.x * 0.5 - 0.45, 0.2, z1 - 0.01), Vector3(0.9, 1.4, 0.05), col.darkened(0.4))
	var n := int(s.x) + 1
	for i in n:
		var x := x0 + 0.2 + i * (x1 - x0 - 0.4) / float(n - 1)
		mb.cylinder(Vector3(x, 0.2, z1 + 0.42), 0.11, 0.1, h - 0.35, stone, 10)
	mb.box(Vector3(x0, h - 0.15, z1), Vector3(x1 - x0, 0.22, 0.6), stone)
	mb.pediment(x0, x1, z1 + 0.6, h + 0.07, 0.75, 0.6, stone)
	_emblem(mb, Vector3((x0 + x1) * 0.5, h + 0.35, z1 + 0.62), col, "book")


static func _sign(mb: MeshBuilder, ctr: Vector3) -> void:
	mb.box_c(ctr, Vector3(0.08, 0.85, 0.08), BROWN)
	mb.box_c(ctr + Vector3(0, 0.5, 0.06), Vector3(0.75, 0.42, 0.06), c("#e8d2a8"))
	mb.box_c(ctr + Vector3(0, 0.63, 0.1), Vector3(0.22, 0.05, 0.02), c("#7a5236"))
	mb.box_c(ctr + Vector3(0, 0.55, 0.1), Vector3(0.05, 0.21, 0.02), c("#7a5236"))


static func _easel(mb: MeshBuilder, ctr: Vector3) -> void:
	mb.box_c(ctr + Vector3(-0.25, 0, 0.1), Vector3(0.05, 1.3, 0.05), BROWN)
	mb.box_c(ctr + Vector3(0.25, 0, 0.1), Vector3(0.05, 1.3, 0.05), BROWN)
	mb.box_c(ctr + Vector3(0, 0, -0.2), Vector3(0.05, 1.2, 0.05), BROWN)
	mb.box_c(ctr + Vector3(0, 0.5, 0.12), Vector3(0.7, 0.05, 0.12), BROWN)
	mb.box_c(ctr + Vector3(0, 0.55, 0.14), Vector3(0.66, 0.62, 0.04), CREAM)
	mb.box_c(ctr + Vector3(0, 0.82, 0.17), Vector3(0.56, 0.3, 0.02), c("#a9d2e0"))
	mb.box_c(ctr + Vector3(0, 0.62, 0.17), Vector3(0.56, 0.2, 0.02), c("#86b38a"))
	mb.sphere(ctr + Vector3(0.14, 0.98, 0.19), 0.06, c("#f2c46b"), Vector3(1, 1, 0.3), 3, 8)


static func _mannequin(mb: MeshBuilder, ctr: Vector3, dress: Color) -> void:
	mb.cylinder(ctr, 0.18, 0.18, 0.04, BROWN, 10)
	mb.cylinder(ctr + Vector3(0, 0.04, 0), 0.025, 0.025, 0.45, BROWN, 6)
	mb.cylinder(ctr + Vector3(0, 0.45, 0), 0.24, 0.13, 0.55, dress, 10)
	mb.cylinder(ctr + Vector3(0, 1.0, 0), 0.13, 0.08, 0.1, dress, 10)
	mb.sphere(ctr + Vector3(0, 1.17, 0), 0.1, c("#e8dccb"))


static func _arch(mb: MeshBuilder, spec: Dictionary, p: Vector2, s: Vector2) -> void:
	var along_x: bool = spec.get("axis", "y") == "y"
	var a := Vector3(p.x, 0, p.y)
	var b := a + (Vector3(s.x, 0, 0) if along_x else Vector3(0, 0, s.y))
	mb.box_c(a, Vector3(0.14, 1.75, 0.14), BROWN)
	mb.box_c(b, Vector3(0.14, 1.75, 0.14), BROWN)
	var beam := (b - a)
	var mid := (a + b) * 0.5 + Vector3(0, 1.66, 0)
	mb.box_c(mid, Vector3(absf(beam.x) + 0.35, 0.14, 0.16) if along_x else Vector3(0.16, 0.14, absf(beam.z) + 0.35), BROWN.lightened(0.1))
	for i in 6:
		var q := a.lerp(b, (i + 0.5) / 6.0) + Vector3(0, 1.82, 0)
		mb.sphere(q, 0.14, c("#86b47d"), Vector3.ONE, 3, 7)
		mb.sphere(q + Vector3(0.06, 0.1, 0.08), 0.05, c("#f2a7b8"), Vector3.ONE, 3, 6)


static func _fountain(mb: MeshBuilder, gb: MeshBuilder, water: Array, ctr: Vector3, s: Vector2) -> void:
	var r := minf(s.x, s.y) * 0.48
	mb.cylinder(ctr, r, r, 0.34, STONE, 16)
	water.append({"disc": Vector2(ctr.x, ctr.z), "r": r - 0.1, "y": 0.35})
	mb.cylinder(ctr + Vector3(0, 0.3, 0), 0.1, 0.09, 0.5, STONE.lightened(0.05), 8)
	mb.cylinder(ctr + Vector3(0, 0.8, 0), 0.12, 0.32, 0.1, STONE, 12)
	gb.sphere(ctr + Vector3(0, 1.0, 0), 0.12, c("#cdeefa"))


static func _stall(mb: MeshBuilder, p: Vector2, s: Vector2, canopy: Color) -> void:
	mb.box(Vector3(p.x, 0, p.y + 0.05), Vector3(0.08, 1.55, 0.08), BROWN)
	mb.box(Vector3(p.x + s.x - 0.08, 0, p.y + 0.05), Vector3(0.08, 1.55, 0.08), BROWN)
	mb.box(Vector3(p.x, 0, p.y + 0.3), Vector3(s.x, 0.62, s.y - 0.3), Furniture.color(Furniture.W, {}))
	var goods := [c("#c94a4a"), c("#e0b65c"), c("#86b38a"), c("#e08a4c"), c("#9a86c9")]
	for i in 6:
		mb.sphere(Vector3(p.x + 0.18 + i * (s.x - 0.36) / 5.0, 0.7, p.y + 0.7), 0.085, goods[i % goods.size()], Vector3.ONE, 3, 6)
	mb.box(Vector3(p.x - 0.1, 1.5, p.y - 0.1), Vector3(s.x + 0.2, 0.08, s.y * 0.85), canopy)
	for i in 3:
		var xa := p.x - 0.1 + (s.x + 0.2) * (i * 2 + 1) / 6.0
		mb.box(Vector3(xa, 1.58, p.y - 0.1), Vector3((s.x + 0.2) / 6.0, 0.01, s.y * 0.85), Color("#fbf6ec"))


static func _rock(mb: MeshBuilder, ctr: Vector3) -> void:
	var g := c("#a9a39a")
	mb.sphere(ctr + Vector3(-0.1, 0.1, 0.02), 0.3, g.darkened(0.1), Vector3(1, 0.6, 0.9), 4, 7)
	mb.sphere(ctr + Vector3(0.16, 0.12, -0.06), 0.22, g, Vector3(1, 0.75, 1), 4, 7)


static func _globe(mb: MeshBuilder, ctr: Vector3) -> void:
	mb.cylinder(ctr, 0.16, 0.12, 0.06, BROWN, 8)
	mb.cylinder(ctr + Vector3(0, 0.06, 0), 0.03, 0.03, 0.35, BROWN, 6)
	mb.sphere(ctr + Vector3(0, 0.6, 0), 0.21, c("#6fa6c9"), Vector3.ONE, 6, 10)
	mb.sphere(ctr + Vector3(-0.08, 0.66, 0.15), 0.08, c("#86b38a"), Vector3(1, 0.8, 0.5), 3, 6)
	mb.sphere(ctr + Vector3(0.12, 0.52, 0.13), 0.06, c("#86b38a"), Vector3(1, 0.8, 0.5), 3, 6)


# --- drawn shadows ----------------------------------------------------------------
# Real-time shadows render wrongly in WebGL, so each object gets a soft shadow
# cast in the sun's direction and stretched by its height.

const SHADOW := Color(0.12, 0.18, 0.1, 0.24)
const SUN_DIR := Vector3(0.45, -0.8, -0.5)  # keep in step with WorldView's light


static func shadow_offset(h: float) -> Vector2:
	return Vector2(-SUN_DIR.x / SUN_DIR.y, -SUN_DIR.z / SUN_DIR.y) * h


## Roughly how tall an object stands (for drawn shadows and for tapping it).
static func object_height(spec: Dictionary) -> float:
	return _object_height(spec)


static func _object_height(spec: Dictionary) -> float:
	var kind := str(spec.kind)
	match kind:
		"tree", "fruit_tree": return 1.8
		"bush": return 0.6
		"plant": return 0.75
		"lamp": return 1.8
		"rock": return 0.45
		"fountain": return 1.1
		"house": return 2.4
		"building": return float(spec.get("height", 78.0)) / 40.0 + 0.2
		"stall": return 1.5
		"flowers": return 0.25
		"sign": return 0.8
		"easel": return 1.2
		"mannequin": return 1.2
		"globe": return 0.8
	if Furniture.has(kind):
		var top := 0.0
		for p in Furniture.PRESETS[kind].parts:
			top = maxf(top, (p[4] + p[5]) * U)
		return top
	return 0.0


static func add_shadow(spec: Dictionary, sb: MeshBuilder) -> void:
	var kind := str(spec.kind)
	var p: Vector2 = spec.pos
	var s := MapGrid.size_of(spec)
	var c2 := p + s * 0.5
	match kind:
		"tree", "fruit_tree":
			sb.soft_disc(c2 + shadow_offset(1.15), 0.55, 0.012, SHADOW)
			sb.soft_disc(c2, 0.2, 0.011, SHADOW)
			return
		"bush":
			sb.soft_disc(c2 + shadow_offset(0.2), 0.45, 0.012, SHADOW)
			return
		"plant":
			sb.soft_disc(c2 + shadow_offset(0.3), 0.3, 0.012, SHADOW)
			return
		"rock":
			sb.soft_disc(c2 + shadow_offset(0.12), 0.38, 0.012, SHADOW)
			return
		"lamp":
			sb.soft_disc(c2, 0.14, 0.012, SHADOW)
			sb.soft_disc(c2 + shadow_offset(1.6), 0.18, 0.012, SHADOW)
			return
		"fountain":
			sb.soft_disc(c2 + shadow_offset(0.25), minf(s.x, s.y) * 0.55, 0.012, SHADOW)
			return
		"arch":
			return
	var h := _object_height(spec)
	if h <= 0.0:
		return
	# Convex hull of the footprint and the same rectangle shifted by the shadow.
	var o := shadow_offset(h)
	var pts: Array[Vector2] = []
	for q in [p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y)]:
		pts.append(q)
		pts.append(q + o)
	sb.soft_polygon(Array(Geometry2D.convex_hull(pts)).slice(0, -1), 0.012, SHADOW, 0.15)


# --- ground, walls, decals ---------------------------------------------------------

static func add_ground(d: Dictionary, mb: MeshBuilder, solid: Dictionary) -> void:
	var size: Vector2i = d.size
	var outdoor: bool = d.get("outdoor", true)
	var paths := {}
	for t in d.get("paths", []):
		paths[t] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(d.get("id", "")))
	for x in size.x:
		for y in size.y:
			var col: Color
			if outdoor:
				col = Palette.PATH if paths.has(Vector2i(x, y)) else (Palette.GRASS_A if (x + y) % 2 == 0 else Palette.GRASS_B)
			else:
				col = Palette.FLOOR_A if x % 2 == 0 else Palette.FLOOR_B
			mb.quad(Vector3(x, 0, y), Vector3(x + 1, 0, y), Vector3(x + 1, 0, y + 1), Vector3(x, 0, y + 1), col, Vector3.UP)
			if outdoor and not paths.has(Vector2i(x, y)) and not solid.has(Vector2i(x, y)) and rng.randf() < 0.4:
				for i in 3:  # little tufts of grass
					var q := Vector3(x + rng.randf_range(0.15, 0.85), 0, y + rng.randf_range(0.15, 0.85))
					mb.cylinder(q, 0.035, 0.0, rng.randf_range(0.09, 0.16), Palette.GRASS_A.darkened(0.18), 4)
				if rng.randf() < 0.15:
					mb.sphere(Vector3(x + rng.randf(), 0.04, y + rng.randf()), 0.035, Color.WHITE, Vector3.ONE, 3, 5)
	var side := Palette.EARTH if outdoor else Color("#6b5240")
	# The earth block stops well below the ground so the two never flicker together.
	mb.box(Vector3(0, -0.5, 0), Vector3(size.x, 0.46, size.y), side)
	mb.box(Vector3(0.15, -0.85, 0.15), Vector3(size.x - 0.3, 0.35, size.y - 0.3), side.darkened(0.25))


static func add_walls(w: Dictionary, size: Vector2i, mb: MeshBuilder, gb: MeshBuilder) -> void:
	var col: Color = w.color
	var h := 2.4
	mb.box(Vector3(-0.25, -0.5, -0.25), Vector3(size.x + 0.25, h + 0.5, 0.25), col.lightened(0.1))
	mb.box(Vector3(-0.25, -0.5, 0), Vector3(0.25, h + 0.5, size.y), col.lightened(0.16))
	mb.box(Vector3(-0.28, h, -0.28), Vector3(size.x + 0.28, 0.06, 0.31), col.darkened(0.1))
	mb.box(Vector3(-0.28, h, 0), Vector3(0.31, 0.06, size.y), col.darkened(0.1))
	mb.box(Vector3(0, 0, 0), Vector3(size.x, 0.13, 0.03), col.darkened(0.28))
	mb.box(Vector3(0, 0, 0), Vector3(0.03, 0.13, size.y), col.darkened(0.28))
	for dec in w.get("decor", []):
		_wall_decor(dec, mb, gb)


static func _wall_rect(on_back: bool, a: float, b: float, y0: float, y1: float, depth: float, col: Color, target: MeshBuilder) -> void:
	if on_back:
		target.box(Vector3(a, y0, 0), Vector3(b - a, y1 - y0, depth), col)
	else:
		target.box(Vector3(0, y0, a), Vector3(depth, y1 - y0, b - a), col)


static func _wall_decor(dec: Dictionary, mb: MeshBuilder, gb: MeshBuilder) -> void:
	var back: bool = dec.wall == "y"
	var a: float = dec.a
	var b: float = dec.b
	var y0: float = float(dec.za) * U
	var y1: float = float(dec.zb) * U
	match str(dec.kind):
		"window":
			_wall_rect(back, a, b, y0, y1, 0.05, CREAM, mb)
			_wall_rect(back, a + 0.08, b - 0.08, y0 + 0.08, y1 - 0.08, 0.06, GLASS, gb)
			var m := (a + b) * 0.5
			_wall_rect(back, m - 0.025, m + 0.025, y0, y1, 0.08, CREAM, mb)
			_wall_rect(back, a, b, (y0 + y1) * 0.5 - 0.025, (y0 + y1) * 0.5 + 0.025, 0.08, CREAM, mb)
			_wall_rect(back, a - 0.05, b + 0.05, y0 - 0.06, y0, 0.14, CREAM.darkened(0.08), mb)
		"painting":
			_wall_rect(back, a, b, y0, y1, 0.05, BROWN, mb)
			_wall_rect(back, a + 0.07, b - 0.07, y0 + 0.07, y1 - 0.07, 0.06, Furniture.color(dec.get("accent", "#e0b65c"), dec), mb)
			_wall_rect(back, a + 0.07, b - 0.07, y0 + 0.07, y0 + 0.2, 0.07, c("#86b38a"), mb)
		"blackboard":
			_wall_rect(back, a, b, y0, y1, 0.05, BROWN, mb)
			_wall_rect(back, a + 0.08, b - 0.08, y0 + 0.08, y1 - 0.08, 0.06, c("#3f5a4c"), mb)
			for i in 3:
				var y := y1 - 0.3 - i * 0.22
				_wall_rect(back, a + 0.35, a + 0.35 + (b - a) * (0.5 - i * 0.1), y, y + 0.025, 0.07, Color(0.95, 0.95, 0.95), mb)
		"mirror":
			_wall_rect(back, a, b, y0, y1, 0.05, c("#c49a4a"), mb)
			_wall_rect(back, a + 0.06, b - 0.06, y0 + 0.06, y1 - 0.06, 0.06, c("#d8ecf0"), gb)
		"cross":
			_wall_rect(back, a, b, y0, y1, 0.04, Color.WHITE, mb)
			var m := (a + b) * 0.5
			var my := (y0 + y1) * 0.5
			_wall_rect(back, m - 0.07, m + 0.07, y0 + 0.08, y1 - 0.08, 0.06, c("#d0544a"), mb)
			_wall_rect(back, a + 0.12, b - 0.12, my - 0.07, my + 0.07, 0.06, c("#d0544a"), mb)


static func add_decal(dec: Dictionary, mb: MeshBuilder, water: Array) -> void:
	var p: Vector2 = dec.pos
	var s := MapGrid.size_of(dec)
	match str(dec.kind):
		"pond":
			for r in [Rect2(p.x, p.y, s.x, 0.2), Rect2(p.x, p.y + s.y - 0.2, s.x, 0.2),
					Rect2(p.x, p.y, 0.2, s.y), Rect2(p.x + s.x - 0.2, p.y, 0.2, s.y)]:
				mb.box(Vector3(r.position.x, 0, r.position.y), Vector3(r.size.x, 0.14, r.size.y), STONE)
			mb.box(Vector3(p.x + 0.2, -0.2, p.y + 0.2), Vector3(s.x - 0.4, 0.17, s.y - 0.4), c("#5f8f8a"))
			water.append({"rect": Rect2(p.x + 0.2, p.y + 0.2, s.x - 0.4, s.y - 0.4), "y": 0.07})
		"river":
			mb.box(Vector3(p.x, -0.25, p.y), Vector3(s.x, 0.22, s.y), c("#5f8f8a"))
			mb.box(Vector3(p.x - 0.06, 0, p.y), Vector3(0.12, 0.06, s.y), c("#b9a98a"))
			mb.box(Vector3(p.x + s.x - 0.06, 0, p.y), Vector3(0.12, 0.06, s.y), c("#b9a98a"))
			water.append({"rect": Rect2(p.x, p.y, s.x, s.y), "y": 0.03})
		"bridge":
			var wood := c("#b08560")
			mb.box(Vector3(p.x, 0.06, p.y), Vector3(s.x, 0.1, s.y), wood)
			for i in int(s.x * 4):
				mb.box(Vector3(p.x + 0.05 + i * 0.25, 0.16, p.y), Vector3(0.02, 0.005, s.y), wood.darkened(0.2))
			for z in [p.y, p.y + s.y - 0.07]:
				mb.box(Vector3(p.x, 0.16, z), Vector3(s.x, 0.06, 0.07), wood.darkened(0.15))
				mb.box(Vector3(p.x, 0.45, z), Vector3(s.x, 0.06, 0.07), wood.darkened(0.15))
				for x in [p.x, p.x + s.x * 0.5, p.x + s.x - 0.07]:
					mb.box(Vector3(x, 0.16, z), Vector3(0.07, 0.35, 0.07), wood.darkened(0.2))
		"plot":
			mb.box(Vector3(p.x, 0, p.y), Vector3(s.x, 0.05, s.y), c("#b89a78"))
			mb.box(Vector3(p.x + 0.2, 0.05, p.y + 0.2), Vector3(s.x - 0.4, 0.02, s.y - 0.4), c("#a8896a"))
			for i in 6:
				var q := Vector3(p.x + 0.6 + (i % 3) * 1.2, 0.07, p.y + 0.8 + (i / 3) * 1.6)
				mb.sphere(q + Vector3(-0.05, 0.04, 0), 0.05, c("#7fb877"), Vector3(1, 0.6, 1), 3, 5)
				mb.sphere(q + Vector3(0.05, 0.05, 0), 0.05, c("#86c07c"), Vector3(1, 0.6, 1), 3, 5)
		"rug":
			var col := Furniture.color(dec.get("accent", "#b5523f"), dec)
			mb.box(Vector3(p.x, 0, p.y), Vector3(s.x, 0.02, s.y), col)
			mb.box(Vector3(p.x + 0.15, 0, p.y + 0.15), Vector3(s.x - 0.3, 0.025, s.y - 0.3), col.lightened(0.25))
			mb.box(Vector3(p.x + 0.4, 0, p.y + 0.4), Vector3(s.x - 0.8, 0.03, s.y - 0.8), col)
		"mat":
			mb.box(Vector3(p.x, 0, p.y), Vector3(s.x, 0.02, s.y), c("#9e7a5a"))
		"picnic":
			mb.box(Vector3(p.x, 0, p.y), Vector3(s.x, 0.02, s.y), c("#e8d2a8"))
			mb.box(Vector3(p.x + 0.15, 0, p.y + 0.15), Vector3(s.x - 0.3, 0.025, s.y - 0.3), c("#d98b8b"))
			mb.sphere(Vector3(p.x + s.x * 0.5, 0.08, p.y + s.y * 0.5), 0.09, c("#e0b65c"), Vector3(1, 0.7, 1), 3, 6)


## Far-away mountains beyond the back edges of the island.
static func add_mountains(mb: MeshBuilder, size: Vector2i) -> void:
	var far := c("#a9b9cc")
	var near := c("#94b29f")
	var peaks := [[-8, -14, 7, 9, far], [3, -17, 8, 11, far], [14, -15, 7, 9.5, far], [24, -11, 6, 7, far],
		[-15, -3, 7, 8, far], [-16, 9, 6, 7, far], [-3, -7, 4.5, 4, near], [9, -8, 5, 4.5, near],
		[-7, 3, 4.5, 3.8, near], [18, -6, 4, 3.5, near]]
	for m in peaks:
		var base := Vector3(m[0], -0.5, m[1])
		var r: float = m[2]
		var h: float = m[3]
		var col: Color = m[4]
		mb.cylinder(base, r, 0.0, h, col, 9)
		if col == far:
			mb.cylinder(base + Vector3(0, h * 0.68, 0), r * 0.32, 0.0, h * 0.32 + 0.02, Color("#f4f6f8"), 9)
