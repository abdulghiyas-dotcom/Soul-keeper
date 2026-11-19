class_name Iso
extends RefCounted
## Grid helpers. Tile (i, j) covers the square [i, i+1) x [j, j+1) and sits at
## 3D position (i, 0, j). (The name is kept from the earlier isometric 2D version.)


static func tile_of(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x), floori(g.y))


static func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t) + Vector2(0.5, 0.5)


static func to_3d(g: Vector2, h := 0.0) -> Vector3:
	return Vector3(g.x, h, g.y)
