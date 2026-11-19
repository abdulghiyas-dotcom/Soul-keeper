class_name WorldView
extends Node3D
## Draws one location in 3D from its MapGrid: sky and light, ground, walls,
## objects, water, mountains. Also turns screen taps into grid positions.

static var _solid_mat: ShaderMaterial
static var _glow_mat: ShaderMaterial
static var _water_mat: ShaderMaterial
static var _shadow_mat: StandardMaterial3D

var map: MapGrid
var light: DirectionalLight3D
var _highlight: MeshInstance3D
var _pick_boxes: Array = []  # [AABB, centre in grid] for solid objects, so taps hit walls


static func solid_material() -> ShaderMaterial:
	if _solid_mat == null:
		_solid_mat = ShaderMaterial.new()
		_solid_mat.shader = load("res://shaders/world.gdshader")
	return _solid_mat


static func glow_material() -> ShaderMaterial:
	if _glow_mat == null:
		_glow_mat = ShaderMaterial.new()
		_glow_mat.shader = load("res://shaders/glow.gdshader")
	return _glow_mat


static func shadow_material() -> StandardMaterial3D:
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.vertex_color_use_as_albedo = true
		_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shadow_mat.render_priority = -1
	return _shadow_mat


static func water_material() -> ShaderMaterial:
	if _water_mat == null:
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = load("res://shaders/water.gdshader")
	return _water_mat


func build(m: MapGrid) -> void:
	map = m
	var d := m.data
	var outdoor: bool = d.get("outdoor", true)
	_environment(outdoor, d.get("mountains", false))

	var mb := MeshBuilder.new()
	var gb := MeshBuilder.new()
	var sb := MeshBuilder.new()
	var water: Array = []
	ObjectMeshes.add_ground(d, mb, m.solid)
	if d.has("walls"):
		ObjectMeshes.add_walls(d.walls, m.size, mb, gb)
	for dec in d.get("decals", []):
		ObjectMeshes.add_decal(dec, mb, water)
	for s in d.get("objects", []):
		ObjectMeshes.add_object(s, mb, gb, water)
		ObjectMeshes.add_shadow(s, sb)
		var h := ObjectMeshes.object_height(s)
		if s.get("solid", true) and h > 0.3:
			var p: Vector2 = s.pos
			var sz := MapGrid.size_of(s)
			_pick_boxes.append([AABB(Vector3(p.x, 0, p.y), Vector3(sz.x, h, sz.y)), p + sz * 0.5])
	if d.get("mountains", false):
		ObjectMeshes.add_mountains(mb, m.size)
	_add_mesh(mb, solid_material(), true)
	_add_mesh(gb, glow_material(), false)
	_add_mesh(sb, shadow_material(), false)
	for w in water:
		_add_water(w)

	_highlight = MeshInstance3D.new()
	_highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_highlight)


func _add_mesh(b: MeshBuilder, mat: Material, shadows: bool) -> void:
	if b.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _add_water(w: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	mi.material_override = water_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if w.has("rect"):
		var r: Rect2 = w.rect
		var pm := PlaneMesh.new()
		pm.size = r.size
		pm.subdivide_width = int(r.size.x * 3)
		pm.subdivide_depth = int(r.size.y * 3)
		mi.mesh = pm
		mi.position = Vector3(r.position.x + r.size.x * 0.5, w.y, r.position.y + r.size.y * 0.5)
	else:
		var cm := CylinderMesh.new()
		cm.top_radius = w.r
		cm.bottom_radius = w.r
		cm.height = 0.01
		cm.radial_segments = 20
		mi.mesh = cm
		mi.position = Vector3(w.disc.x, w.y, w.disc.y)
	add_child(mi)


func _environment(outdoor: bool, mountains: bool) -> void:
	var env := Environment.new()
	if outdoor:
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color("#86b9df")
		sm.sky_horizon_color = Color("#f3e5d6")
		sm.ground_horizon_color = Color("#f3e5d6")
		sm.ground_bottom_color = Color("#b9cdb3")
		sm.sky_curve = 0.12
		var sky := Sky.new()
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		# Even, soft fill light (lighting from the sky itself washed out flat ground).
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#eef2f5")
		env.ambient_light_energy = 0.68
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Palette.SKY_INSIDE
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#fff0dc")
		env.ambient_light_energy = 0.62
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.glow_enabled = false
	if mountains:
		env.fog_enabled = true
		env.fog_light_color = Color("#e9eef2")
		env.fog_density = 0.0035
		env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	light = DirectionalLight3D.new()
	light.light_color = Color("#fff3e2")
	# The web renderer has no high-dynamic-range lighting, so the sun stays gentle.
	light.light_energy = 0.55 if outdoor else 0.45
	# No real-time shadow maps: WebGL rendered them wrongly (washed-out colours).
	# Soft shadows are drawn instead (ObjectMeshes.add_shadow); also faster on phones.
	light.shadow_enabled = false
	add_child(light)
	# Sun from the front-left: left-facing sides lit, shadows fall back and to the right.
	light.basis = Basis.looking_at(ObjectMeshes.SUN_DIR.normalized(), Vector3.UP)


## What the tap points at, in grid units: a building or object the ray hits first
## (its centre), otherwise the spot on the ground. (-1, -1) if nothing.
func screen_to_grid(cam: Camera3D, screen_pos: Vector2, objects := true) -> Vector2:
	var o := cam.project_ray_origin(screen_pos)
	var n := cam.project_ray_normal(screen_pos)
	if objects:
		var best := INF
		var best_g := Vector2(-1, -1)
		for pb in _pick_boxes:
			var hit = (pb[0] as AABB).intersects_ray(o, n)
			if hit != null and o.distance_to(hit) < best:
				best = o.distance_to(hit)
				best_g = pb[1]
		var ground := _ground_hit(o, n)
		if best_g.x >= 0.0 and (ground.x < 0.0 or best < o.distance_to(Vector3(ground.x, 0, ground.y))):
			return best_g
		return ground
	return _ground_hit(o, n)


func _ground_hit(o: Vector3, n: Vector3) -> Vector2:
	if absf(n.y) < 1e-4:
		return Vector2(-1, -1)
	var t := -o.y / n.y
	if t < 0.0:
		return Vector2(-1, -1)
	var hit := o + n * t
	return Vector2(hit.x, hit.z)


func set_highlight(tiles: Array, color := Color("#fff6c8")) -> void:
	if tiles.is_empty():
		_highlight.mesh = null
		return
	var b := MeshBuilder.new()
	for t in tiles:
		b.box(Vector3(t.x + 0.04, 0.0, t.y + 0.04), Vector3(0.92, 0.06, 0.92), color)
	_highlight.mesh = b.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1, 0.55)
	_highlight.material_override = mat


## A soft ring that grows and fades where she tapped.
func tap_marker(g: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.18
	tm.outer_radius = 0.24
	tm.rings = 16
	mi.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.85)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(g.x, 0.05, g.y)
	mi.scale = Vector3(1, 0.3, 1)
	add_child(mi)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(2.2, 0.3, 2.2), 0.5)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_callback(mi.queue_free)
