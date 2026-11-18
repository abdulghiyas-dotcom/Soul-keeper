class_name IsoMap
extends Node2D
## A location built from a WorldData dictionary: ground layer, y-sorted
## objects, a walkability grid and A* pathfinding for tap-to-walk.

var data: Dictionary
var size: Vector2i
var objects: Node2D
var solid := {}       # Vector2i -> true
var door_of := {}     # solid tile -> door tile (tapping a house walks to its door)
var user_at := {}     # tile -> index of the item she placed there (see Decor)
var keep_clear := {}  # tiles where she arrives; never decorated over
var astar := AStarGrid2D.new()
var _highlight: Highlight


func build(d: Dictionary) -> void:
	data = d
	size = d.size
	var ground := IsoGround.new()
	ground.map = self
	add_child(ground)
	objects = Node2D.new()
	objects.y_sort_enabled = true
	add_child(objects)

	for dec in d.get("decals", []):
		if dec.has("user"):
			for t in Decor.footprint(Iso.tile_of(dec.pos), dec.kind):
				user_at[t] = dec.user
	for s in d.get("objects", []):
		var ob := IsoObject.new().setup(s)
		objects.add_child(ob)
		if s.has("user"):
			for t in ob.footprint():
				user_at[t] = s.user
		if s.get("solid", true):
			for t in ob.footprint():
				solid[t] = true
				if s.has("door"):
					door_of[t] = s.door
	for t in d.get("blocked", []):
		solid[t] = true
		if d.has("blocked_door"):
			door_of[t] = d.blocked_door

	for g in d.get("keep_clear", []):
		keep_clear[Iso.tile_of(g)] = true
	_highlight = Highlight.new()
	_highlight.z_index = 10
	add_child(_highlight)

	astar.region = Rect2i(Vector2i.ZERO, size)
	astar.cell_size = Vector2.ONE
	astar.offset = Vector2(0.5, 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for t in solid:
		if astar.is_in_boundsv(t):
			astar.set_point_solid(t, true)
	# Paths never pass *through* a door; a door is only walked to on purpose.
	for t in d.get("doors", {}):
		if astar.is_in_boundsv(t):
			astar.set_point_solid(t, true)


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y


func is_walkable_tile(t: Vector2i) -> bool:
	return in_bounds(t) and not solid.has(t)


func is_walkable(g: Vector2) -> bool:
	return g.x >= 0.0 and g.y >= 0.0 and is_walkable_tile(Iso.tile_of(g))


func door_at(t: Vector2i) -> Dictionary:
	return data.get("doors", {}).get(t, {})


## Tile the avatar should walk to when the user taps tile `t`, or (-1,-1).
func tap_target(t: Vector2i) -> Vector2i:
	if is_walkable_tile(t):
		return t
	if door_of.has(t):
		return door_of[t]
	return Vector2i(-1, -1)


func find_path(from: Vector2, to: Vector2i) -> PackedVector2Array:
	var start := Iso.tile_of(from)
	if not is_walkable_tile(start) or not is_walkable_tile(to):
		return PackedVector2Array()
	if start == to:
		return PackedVector2Array([Iso.tile_center(to)])
	# Standing on a door (e.g. just arrived): let A* start from it.
	var start_door := not door_at(start).is_empty()
	if start_door:
		astar.set_point_solid(start, false)
	var is_door := not door_at(to).is_empty()
	if is_door:
		astar.set_point_solid(to, false)
	var path := astar.get_point_path(start, to)
	if is_door:
		astar.set_point_solid(to, true)
	if start_door:
		astar.set_point_solid(start, true)
	if path.size() > 0:
		path.remove_at(0)  # we are already on the first tile
	return path


## Tiles covered by the placed item with this index.
func user_tiles(index: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for t in user_at:
		if user_at[t] == index:
			out.append(t)
	return out


## Would the avatar still reach every door and arrival spot if `extra` tiles were
## blocked and `freed` tiles were cleared? (Stops her trapping herself.)
func keeps_paths_open(extra: Dictionary, freed: Dictionary, from: Vector2i) -> bool:
	var blocked := func(t: Vector2i) -> bool:
		return not in_bounds(t) or extra.has(t) or (solid.has(t) and not freed.has(t))
	if blocked.call(from):
		return false
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var t: Vector2i = queue.pop_back()
		for n in [t + Vector2i.RIGHT, t + Vector2i.LEFT, t + Vector2i.UP, t + Vector2i.DOWN]:
			if not seen.has(n) and not blocked.call(n):
				seen[n] = true
				queue.append(n)
	for t in data.get("doors", {}):
		if not seen.has(t):
			return false
	for t in keep_clear:
		if not seen.has(t):
			return false
	return true


func set_highlight(tiles: Array, color := Color(1, 1, 1, 0.9)) -> void:
	_highlight.tiles = tiles
	_highlight.color = color
	_highlight.queue_redraw()


class Highlight extends Node2D:
	var tiles: Array = []
	var color := Color.WHITE

	func _draw() -> void:
		for t in tiles:
			var p := PackedVector2Array([Iso.to_screen(Vector2(t)), Iso.to_screen(Vector2(t) + Vector2(1, 0)),
				Iso.to_screen(Vector2(t) + Vector2(1, 1)), Iso.to_screen(Vector2(t) + Vector2(0, 1))])
			draw_colored_polygon(p, Color(color, 0.25))
			p.append(p[0])
			draw_polyline(p, color, 2.0, true)
