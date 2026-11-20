class_name ArenaKeys
extends RefCounted

const DEFAULTS := [
	[[KEY_A], [KEY_D], [KEY_W, KEY_SPACE], [KEY_F], [KEY_G], [KEY_Q, KEY_SHIFT], [KEY_S]],
	[[KEY_LEFT], [KEY_RIGHT], [KEY_UP], [KEY_J], [KEY_K], [KEY_L], [KEY_DOWN]],
]
const ACTION_NAMES := ["Links", "Rechts", "Springen", "Angreifen", "Spezialfähigkeit", "Ausweichen", "Fallen lassen"]
const RESERVED := [KEY_ESCAPE, KEY_TAB, KEY_ENTER, KEY_KP_ENTER, KEY_F11, KEY_R, KEY_F2]

var layouts: Array = DEFAULTS.duplicate(true)


func load_layouts(value: Variant) -> void:
	if not value is Array or value.size() != DEFAULTS.size():
		return
	var used := {}
	for layout: Variant in value:
		if not layout is Array or layout.size() != ACTION_NAMES.size():
			return
		for group: Variant in layout:
			if not group is Array or group.is_empty() or group.size() > 2:
				return
			for key: Variant in group:
				if not key is int or not valid_key(key) or used.has(key):
					return
				used[key] = true
	layouts = value.duplicate(true)


func restore_defaults() -> void:
	layouts = DEFAULTS.duplicate(true)


func valid_key(key: int) -> bool:
	return key > KEY_NONE and key < KEY_UNKNOWN and key not in RESERVED and not OS.get_keycode_string(key).is_empty()


func conflict(key: int, target: Vector2i) -> String:
	for player in layouts.size():
		for action in ACTION_NAMES.size():
			if target != Vector2i(player, action) and key in layouts[player][action]:
				return "Spieler %d · %s" % [player + 1, ACTION_NAMES[action]]
	return ""


func caption(player: int, action: int) -> String:
	var names := PackedStringArray()
	for key: int in layouts[player][action]:
		var display_key := key
		if DisplayServer.get_name() != "headless":
			var translated := DisplayServer.keyboard_get_keycode_from_physical(key)
			if translated != KEY_NONE:
				display_key = translated
		match display_key:
			KEY_SPACE:
				names.append("Leertaste")
			KEY_SHIFT:
				names.append("Umschalt")
			KEY_LEFT:
				names.append("←")
			KEY_RIGHT:
				names.append("→")
			KEY_UP:
				names.append("↑")
			KEY_DOWN:
				names.append("↓")
			_:
				names.append(OS.get_keycode_string(display_key))
	return " / ".join(names)
