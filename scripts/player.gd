class_name Player
extends Node3D
## The avatar in the world. Moves in grid space (x, y) = 3D (x, z); walks with
## arrow keys/WASD (relative to the camera) or along an A* path after a tap.
## Emits entered_tile when she steps onto a new tile (doors use this).

signal entered_tile(tile: Vector2i)

const SPEED := 3.0      # tiles per second
const RADIUS := 0.2     # collision radius in tiles

var map: MapGrid
var look: Dictionary
var camera: Camera3D    # keyboard directions follow the camera
var g := Vector2.ZERO
var path := PackedVector2Array()
var frozen := false
var avatar: Avatar3D
var _last_tile := Vector2i(-99, -99)
var _step_t := 0.0
var _yaw := 0.0


func _ready() -> void:
	avatar = Avatar3D.new(look)
	add_child(avatar)
	var sb := MeshBuilder.new()
	sb.soft_disc(Vector2.ZERO, 0.32, 0.015, ObjectMeshes.SHADOW)
	sb.soft_disc(ObjectMeshes.shadow_offset(0.9), 0.24, 0.016, ObjectMeshes.SHADOW)
	var shadow := MeshInstance3D.new()
	shadow.mesh = sb.commit()
	shadow.material_override = WorldView.shadow_material()
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	avatar.rotation.y = _yaw


func place(at: Vector2) -> void:
	g = at
	path.clear()
	_last_tile = Iso.tile_of(g)
	position = Iso.to_3d(g)


func face(dir: Vector2) -> void:
	_yaw = atan2(dir.x, dir.y)
	if avatar:
		avatar.rotation.y = _yaw


func walk_to(tile: Vector2i) -> void:
	path = map.find_path(g, tile)


func _process(delta: float) -> void:
	if frozen:
		if avatar:
			avatar.idle(delta)
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var step := Vector2.ZERO
	if dir != Vector2.ZERO:
		path.clear()
		step = _screen_to_ground(dir.normalized()) * SPEED * delta
	elif not path.is_empty():
		var to := path[0] - g
		if to.length() <= SPEED * delta:
			step = to
			path.remove_at(0)
		else:
			step = to.normalized() * SPEED * delta

	if step != Vector2.ZERO:
		if not _try_move(step):
			path.clear()
		var target := atan2(step.x, step.y)
		_yaw = lerp_angle(_yaw, target, minf(1.0, delta * 12.0))
		avatar.rotation.y = _yaw
		avatar.walk(delta)
		_step_t += delta
		if _step_t >= 0.33:
			_step_t = 0.0
			Sound.play("step", -12.0, 0.15)
		position = Iso.to_3d(g)
	else:
		avatar.idle(delta)

	var t := Iso.tile_of(g)
	if t != _last_tile:
		_last_tile = t
		entered_tile.emit(t)


## Screen direction (x right, y down) to a direction on the ground.
func _screen_to_ground(dir: Vector2) -> Vector2:
	var right := Vector2(1, -1).normalized()
	var fwd := Vector2(-1, -1).normalized()
	if camera:
		var r := camera.global_basis.x
		var f := -camera.global_basis.z
		right = Vector2(r.x, r.z).normalized()
		fwd = Vector2(f.x, f.z).normalized()
	return (right * dir.x - fwd * dir.y).normalized()


func _try_move(step: Vector2) -> bool:
	var n := g + step
	if _free(n):
		g = n
	elif _free(Vector2(n.x, g.y)):
		g.x = n.x
	elif _free(Vector2(g.x, n.y)):
		g.y = n.y
	else:
		return false
	return true


func _free(p: Vector2) -> bool:
	for off in [Vector2(-RADIUS, -RADIUS), Vector2(RADIUS, -RADIUS), Vector2(-RADIUS, RADIUS), Vector2(RADIUS, RADIUS)]:
		if not map.is_walkable(p + off):
			return false
	return true
