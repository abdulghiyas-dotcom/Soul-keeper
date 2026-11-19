class_name Preview3D
extends SubViewportContainer
## A small 3D stage inside the UI: its own light and camera, transparent background.
## Used for the avatar in the creator and for item pictures in the decorating tray.

var content: Node3D
var spin := 0.0          # gentle sway speed; 0 = still picture rendered once
var _t := 0.0
var focus := Vector3(0, 0.5, 0)
var extent := 1.5        # how much of the scene fits in view
var _vp: SubViewport
var _pivot: Node3D


func _init(p_content: Node3D = null, p_focus := Vector3(0, 0.5, 0), p_extent := 1.5, p_spin := 0.0) -> void:
	content = p_content
	focus = p_focus
	extent = p_extent
	spin = p_spin
	stretch = true
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if spin != 0.0 else SubViewport.UPDATE_ONCE
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff0dc")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var light := DirectionalLight3D.new()
	light.light_energy = 0.6
	_vp.add_child(light)
	light.basis = Basis.looking_at(Vector3(0.6, -1.0, -0.4).normalized(), Vector3.UP)
	_pivot = Node3D.new()
	_pivot.position = focus
	_vp.add_child(_pivot)
	if content:
		content.position -= focus
		_pivot.add_child(content)
		if spin != 0.0:
			_pivot.rotation.y = PI * 0.25
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = extent
	_vp.add_child(cam)
	cam.position = focus + Vector3(1, 0.8, 1).normalized() * 10.0
	cam.look_at(focus, Vector3.UP)


func _process(delta: float) -> void:
	if spin != 0.0 and _pivot:
		_t += delta * spin
		_pivot.rotation.y = PI * 0.25 + sin(_t) * 0.3  # sways gently, always turned towards us


## Re-render a still picture (e.g. after changing colours).
func refresh() -> void:
	if _vp and spin == 0.0:
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
