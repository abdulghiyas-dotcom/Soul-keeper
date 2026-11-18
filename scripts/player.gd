class_name Player
extends Node2D
## The avatar in the world. Moves in grid space; walks with arrow keys/WASD
## or along an A* path after a tap. Emits entered_tile when she steps onto a
## new tile (doors use this, so standing still on a door never re-triggers).

signal entered_tile(tile: Vector2i)

const SPEED := 3.4      # tiles per second
const RADIUS := 0.2     # collision radius in tiles

var map: IsoMap
var look: Dictionary
var g := Vector2.ZERO
var path := PackedVector2Array()
var frozen := false
var _facing_back := false
var _walk_t := 0.0
var _last_tile := Vector2i(-99, -99)
var _step_t := 0.0


func place(at: Vector2) -> void:
	g = at
	path.clear()
	_last_tile = Iso.tile_of(g)
	_sync()


func walk_to(tile: Vector2i) -> void:
	path = map.find_path(g, tile)


func _process(delta: float) -> void:
	if frozen:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var step := Vector2.ZERO
	if dir != Vector2.ZERO:
		path.clear()
		step = Iso.to_grid(dir.normalized()).normalized() * SPEED * delta
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
		_walk_t += delta
		_step_t += delta
		if _step_t >= 0.32:
			_step_t = 0.0
			Sound.play("step", -12.0, 0.15)
		var screen_dir := Iso.to_screen(step)
		if absf(screen_dir.y) > 0.001:
			_facing_back = screen_dir.y < 0.0
		_sync()
	elif _walk_t != 0.0:
		_walk_t = 0.0
		queue_redraw()

	var t := Iso.tile_of(g)
	if t != _last_tile:
		_last_tile = t
		entered_tile.emit(t)


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


func _sync() -> void:
	position = Iso.to_screen(g)
	queue_redraw()


func _draw() -> void:
	var bob := sin(_walk_t * 14.0) * 1.4 if _walk_t > 0.0 else 0.0
	Avatar.draw(self, look, Vector2.ZERO, 1.0, _facing_back, bob)
