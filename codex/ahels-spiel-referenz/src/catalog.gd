class_name ArenaCatalog
extends RefCounted

const STUDENTS := 24
const TUTOR := 24
const BOSS := 25
const SPRITE_SIZE := Vector2(76, 96)
const FIELD_SIZE := Vector2(1280, 720)

var fighters: Array[Dictionary] = []
var arenas: Array[Dictionary] = []
var sprites: Array[Texture2D] = []
var portraits: Array[Texture2D] = []
var backdrops: Array[Texture2D] = []


func _init() -> void:
	for entry: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")):
		entry["accent"] = Color.from_string(entry["color"], Color.WHITE)
		fighters.append(entry)
		sprites.append(load("res://assets/pixel/%s.png" % entry["id"]) as Texture2D)
		portraits.append(load("res://assets/pixel/%s-portrait.png" % entry["id"]) as Texture2D)
	for entry: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas.json")):
		var surfaces: Array[Rect2] = []
		for surface: Array in entry["platforms"]:
			surfaces.append(Rect2(surface[0], surface[1], surface[2], surface[3]))
		entry["surfaces"] = surfaces
		entry["accent"] = Color.from_string(entry["color"], Color.WHITE)
		arenas.append(entry)
		backdrops.append(load("res://assets/pixel/%s.png" % entry["id"]) as Texture2D)


func draw_sprite(canvas: CanvasItem, index: int, frame: int, destination: Rect2,
		facing: int = 1, tint: Color = Color.WHITE) -> void:
	var source := Rect2(Vector2(frame * SPRITE_SIZE.x, 0), SPRITE_SIZE)
	if facing < 0:
		canvas.draw_set_transform(destination.position + Vector2(destination.size.x, 0), 0, Vector2(-1, 1))
		canvas.draw_texture_rect_region(sprites[index], Rect2(Vector2.ZERO, destination.size), source, tint)
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		canvas.draw_texture_rect_region(sprites[index], destination, source, tint)
