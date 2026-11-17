class_name Palette
extends RefCounted
## All colour choices in one place. Soft, warm, hopeful tones.

const SKIN := [Color("#f6d9c6"), Color("#e9bc9b"), Color("#cf9a76"), Color("#a9714f"), Color("#7a4a31")]
const HAIR := [Color("#2b1b14"), Color("#4a2f22"), Color("#7a5236"), Color("#1d1d22")]
const SCARF := [Color("#c8604a"), Color("#6a8caf"), Color("#5b9e7a"), Color("#d9a441"),
	Color("#8e6cb5"), Color("#ece5d8"), Color("#33434d")]
const DRESS := [Color("#7aa6c2"), Color("#d98b8b"), Color("#86b38a"), Color("#e0b65c"),
	Color("#9a86c9"), Color("#4f6d7a"), Color("#c97b5a")]
const WALL := [Color("#f1e6d4"), Color("#ebd2b8"), Color("#d8e4dc"), Color("#f2d8da"),
	Color("#dce6f2"), Color("#e8ddbd")]
const ROOF := [Color("#b8674b"), Color("#6f9273"), Color("#5f7ca0"), Color("#8d6c92"), Color("#c49a4a")]

const GRASS_A := Color("#a9cf98")
const GRASS_B := Color("#a2c991")
const PATH := Color("#e6d5b3")
const EARTH := Color("#9b7b5c")
const WATER := Color("#8cc3d6")
const FLOOR_A := Color("#d7b48f")
const FLOOR_B := Color("#cfab85")
const WOOD := Color("#b08560")
const WOOD_DARK := Color("#8a6446")
const CREAM := Color("#f5efe4")
const INK := Color("#4a3f4f")
const SKY_OUTSIDE := Color("#c4dde2")
const SKY_INSIDE := Color("#3e3846")


static func pick(arr: Array, i) -> Color:
	return arr[posmod(int(i), arr.size())]
