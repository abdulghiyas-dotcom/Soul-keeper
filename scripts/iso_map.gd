class_name IsoMap
extends Node2D
## A location built from a WorldData dictionary: ground layer, y-sorted
## objects, a walkability grid and A* pathfinding for tap-to-walk.

var data: Dictionary
var size: Vector2i
var objects: Node2D
var solid := {}       # Vector2i -> true
var door_of := {}     # solid tile -> door tile (tapping a house walks to its door)
var astar := AStarGrid2D.new()


func build(d: Dictionary) -> void:
	data = d
	size = d.size
	var ground := IsoGround.new()
	ground.map = self
	add_child(ground)
	objects = Node2D.new()
	objects.y_sort_enabled = true
	add_child(objects)

	for s in d.get("objects", []):
		var ob := IsoObject.new().setup(s)
		objects.add_child(ob)
		if s.get("solid", true):
			for t in ob.footprint():
				solid[t] = true
				if s.has("door"):
					door_of[t] = s.door
	for t in d.get("blocked", []):
		solid[t] = true
		if d.has("blocked_door"):
			door_of[t] = d.blocked_door

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
