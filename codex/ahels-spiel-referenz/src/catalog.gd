class_name ArenaCatalog
extends RefCounted

const STUDENTS := 24
const TUTOR := 24
const BOSS := 25
const SPRITE_SIZE := Vector2(76, 96)
const FIELD_SIZE := Vector2(1280, 720)

# The first clip in each list is the event cue. Manual playback uses the whole list.
const CLASS_DUELS := [
	{
		"id": "figur-05", "arena": "aula", "event": "ring_out", "callout": "Ring-out",
		"clips": ["stefan-03.ogg"], "voice_note": "Beim Ring-out",
		"hint": "Stefan sucht den Nahkampf und setzt dort seinen Schallkreis ein.",
	},
	{
		"id": "figur-11", "arena": "werkstatt", "event": "block", "callout": "Angriff abgewehrt",
		"clips": ["lukas-04.ogg", "lukas-02.ogg", "lukas-06.ogg", "lukas-08.ogg"],
		"voice_note": "Beim Block",
		"hint": "Lukas wartet auf deinen Angriff und fängt ihn mit seinem Schutzfeld ab.",
	},
	{
		"id": "figur-10", "arena": "computerraum", "event": "projectile", "callout": "Impulslinie trifft",
		"clips": ["valentin-09.ogg", "valentin-05.ogg", "valentin-07.ogg"],
		"voice_note": "Beim Projektiltreffer",
		"hint": "Valentin sucht Abstand und schickt seine Impulslinie quer durch die Arena.",
	},
]

var fighters: Array[Dictionary] = []
var class_duel_fighters: Array[int] = []
var arenas: Array[Dictionary] = []
var sprites: Array[Texture2D] = []
var portraits: Array[Texture2D] = []
var backdrops: Array[Texture2D] = []


func _init() -> void:
	var move_sets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/move_sets.json"))
	for entry: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")):
		entry["accent"] = Color.from_string(entry["color"], Color.WHITE)
		entry.merge(move_sets[entry["id"]])
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

	for profile in CLASS_DUELS:
		for id in fighters.size():
			if fighters[id]["id"] == profile["id"]:
				fighters[id]["class_duel"] = profile
				class_duel_fighters.append(id)
				break


func arena_index(id: String) -> int:
	for index in arenas.size():
		if arenas[index]["id"] == id:
			return index
	return -1


func draw_sprite(canvas: CanvasItem, index: int, frame: int, destination: Rect2,
		facing: int = 1, tint: Color = Color.WHITE) -> void:
	var source := Rect2(Vector2(frame * SPRITE_SIZE.x, 0), SPRITE_SIZE)
	if facing < 0:
		canvas.draw_set_transform(destination.position + Vector2(destination.size.x, 0), 0, Vector2(-1, 1))
		canvas.draw_texture_rect_region(sprites[index], Rect2(Vector2.ZERO, destination.size), source, tint)
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		canvas.draw_texture_rect_region(sprites[index], destination, source, tint)
