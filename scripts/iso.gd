class_name Iso
extends RefCounted
## Isometric math.
## "Grid" space is measured in tiles: +x goes down-right on screen, +y goes
## down-left. Tile (i, j) covers the square [i, i+1) x [j, j+1).

const TILE_W := 64.0
const TILE_H := 32.0


static func to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TILE_W * 0.5, (g.x + g.y) * TILE_H * 0.5)


static func to_grid(s: Vector2) -> Vector2:
	return Vector2(s.x / TILE_W + s.y / TILE_H, s.y / TILE_H - s.x / TILE_W)


static func tile_of(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x), floori(g.y))


static func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t) + Vector2(0.5, 0.5)
