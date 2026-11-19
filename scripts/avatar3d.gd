class_name Avatar3D
extends Node3D
## The avatar in 3D, built from simple rounded shapes in her chosen colours.
## Faces +Z. Call walk(delta) while moving and idle(delta) when standing.

var look: Dictionary
var _body: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _t := 0.0
var _mats := {}


func _init(p_look: Dictionary = {}) -> void:
	look = p_look


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for ch in get_children():
		ch.queue_free()
	var skin := Palette.pick(Palette.SKIN, look.get("skin", 0))
	var hair := Palette.pick(Palette.HAIR, look.get("hair", 0))
	var dress := Palette.pick(Palette.DRESS, look.get("dress", 0))
	var scarf_i := int(look.get("scarf", 0))
	var dark := Color("#3b2f35")

	_body = Node3D.new()
	add_child(_body)
	# shoes
	for x in [-0.09, 0.09]:
		_part(_sphere(0.075), Vector3(x, 0.05, 0.03), dark, Vector3(1, 0.6, 1.4))
	# dress: a soft bell shape, plus bodice
	_part(_cyl(0.16, 0.31, 0.6), Vector3(0, 0.36, 0), dress)
	_part(_cyl(0.13, 0.16, 0.2), Vector3(0, 0.75, 0), dress)
	_part(_cyl(0.31, 0.3, 0.05), Vector3(0, 0.08, 0), dress.darkened(0.12))
	# arms that swing
	_arm_l = _arm(Vector3(-0.19, 0.8, 0), dress, skin)
	_arm_r = _arm(Vector3(0.19, 0.8, 0), dress, skin)
	# head
	var head := Vector3(0, 1.03, 0)
	if scarf_i >= 0:
		var sc := Palette.pick(Palette.SCARF, scarf_i)
		_part(_cyl(0.27, 0.19, 0.2), Vector3(0, 0.88, -0.01), sc)  # drape over the shoulders
		_part(_sphere(0.245), head + Vector3(0, 0.01, -0.07), sc)
	else:
		_part(_sphere(0.225), head + Vector3(0, 0.03, -0.07), hair)
		_part(_cyl(0.13, 0.17, 0.4), Vector3(0, 0.82, -0.1), hair)  # long hair down the back
	_part(_sphere(0.17), head + Vector3(0, -0.02, 0.13), skin, Vector3(1, 1.08, 0.8))  # face
	for x in [-0.065, 0.065]:
		_part(_sphere(0.024), head + Vector3(x, 0.0, 0.265), dark)
		_part(_sphere(0.03), head + Vector3(x * 1.55, -0.07, 0.245), Color(0.95, 0.6, 0.6), Vector3(1, 0.6, 0.4), 0.45)
	_part(_sphere(0.02), head + Vector3(0, -0.09, 0.265), Color("#c4706a"), Vector3(1.6, 0.6, 0.6))  # a small smile


func walk(delta: float) -> void:
	_t += delta * 9.0
	var swing := sin(_t) * 0.6
	_arm_l.rotation.x = swing
	_arm_r.rotation.x = -swing
	_body.position.y = absf(sin(_t)) * 0.04
	_body.rotation.z = sin(_t) * 0.03


func idle(delta: float) -> void:
	_t = 0.0
	_arm_l.rotation.x = lerpf(_arm_l.rotation.x, 0.0, delta * 10.0)
	_arm_r.rotation.x = lerpf(_arm_r.rotation.x, 0.0, delta * 10.0)
	_body.position.y = lerpf(_body.position.y, 0.0, delta * 10.0)
	_body.rotation.z = 0.0


func _arm(shoulder: Vector3, sleeve: Color, skin: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = shoulder
	_body.add_child(pivot)
	var a := _mesh(_capsule(0.055, 0.36), sleeve)
	a.position = Vector3(0, -0.16, 0)
	pivot.add_child(a)
	var h := _mesh(_sphere(0.055), skin)
	h.position = Vector3(0, -0.36, 0)
	pivot.add_child(h)
	return pivot


func _part(m: Mesh, at: Vector3, col: Color, scale := Vector3.ONE, alpha := 1.0) -> MeshInstance3D:
	var mi := _mesh(m, col, alpha)
	mi.position = at
	mi.scale = scale
	_body.add_child(mi)
	return mi


func _mesh(m: Mesh, col: Color, alpha := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var key := str(col) + str(alpha)
	if not _mats.has(key):
		_mats[key] = Avatar3D.material(Color(col, alpha))
	mi.material_override = _mats[key]
	if alpha < 1.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Single-colour material with the same soft lighting as the world.
static func material(col: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var sh: Shader = load("res://shaders/solid_color.gdshader")
	if col.a < 1.0:
		sh = sh.duplicate()
		sh.code = sh.code.replace("render_mode ", "render_mode blend_mix, depth_draw_opaque, ")
	mat.shader = sh
	mat.set_shader_parameter("color", col)
	return mat


static func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 16
	m.rings = 1
	return m


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m
