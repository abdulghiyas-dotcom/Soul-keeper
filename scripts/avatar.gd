class_name Avatar
extends RefCounted
## Draws the user's avatar from her `look` dictionary (see GameState).
## Placeholder geometry: replace with sprites later without touching callers.


static func draw(ci: CanvasItem, look: Dictionary, at: Vector2, s := 1.0, facing_back := false, bob := 0.0) -> void:
	var skin := Palette.pick(Palette.SKIN, look.get("skin", 0))
	var hair := Palette.pick(Palette.HAIR, look.get("hair", 0))
	var dress := Palette.pick(Palette.DRESS, look.get("dress", 0))
	var scarf_i := int(look.get("scarf", 0))
	var dark := Color("#3b2f35")

	IsoDraw.shadow(ci, at, 13 * s)
	# feet
	IsoDraw.ellipse(ci, at + Vector2(-5, -3) * s, 4 * s, 2.4 * s, dark)
	IsoDraw.ellipse(ci, at + Vector2(5, -3) * s, 4 * s, 2.4 * s, dark)
	# dress
	var top := -34.0 + bob
	ci.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-8, top) * s, at + Vector2(8, top) * s,
		at + Vector2(13, -5) * s, at + Vector2(-13, -5) * s]), dress)
	ci.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-13, -5) * s, at + Vector2(13, -5) * s,
		at + Vector2(12, -9) * s, at + Vector2(-12, -9) * s]), dress.darkened(0.12))
	# hands
	ci.draw_circle(at + Vector2(-11, -19 + bob) * s, 3.2 * s, skin, true, -1.0, true)
	ci.draw_circle(at + Vector2(11, -19 + bob) * s, 3.2 * s, skin, true, -1.0, true)

	var head := at + Vector2(0, -45 + bob) * s
	if scarf_i >= 0:
		var scarf := Palette.pick(Palette.SCARF, scarf_i)
		ci.draw_colored_polygon(PackedVector2Array([
			head + Vector2(-12, 0) * s, head + Vector2(12, 0) * s,
			at + Vector2(11, -26 + bob) * s, at + Vector2(-11, -26 + bob) * s]), scarf)
		ci.draw_circle(head + Vector2(0, -1) * s, 12.5 * s, scarf, true, -1.0, true)
		if not facing_back:
			ci.draw_circle(head + Vector2(0, 1.5) * s, 8.2 * s, skin, true, -1.0, true)
	else:
		if facing_back:
			ci.draw_colored_polygon(PackedVector2Array([
				head + Vector2(-11, 0) * s, head + Vector2(11, 0) * s,
				at + Vector2(9, -30 + bob) * s, at + Vector2(-9, -30 + bob) * s]), hair)
		ci.draw_circle(head + Vector2(0, -1) * s, 11 * s, hair, true, -1.0, true)
		if not facing_back:
			ci.draw_circle(head + Vector2(0, 2) * s, 8.8 * s, skin, true, -1.0, true)
	if not facing_back:
		ci.draw_circle(head + Vector2(-3.2, 2) * s, 1.3 * s, dark, true, -1.0, true)
		ci.draw_circle(head + Vector2(3.2, 2) * s, 1.3 * s, dark, true, -1.0, true)
		ci.draw_circle(head + Vector2(-5, 5) * s, 1.8 * s, Color(0.95, 0.55, 0.55, 0.35), true, -1.0, true)
		ci.draw_circle(head + Vector2(5, 5) * s, 1.8 * s, Color(0.95, 0.55, 0.55, 0.35), true, -1.0, true)
