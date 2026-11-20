class_name ArenaApp
extends Control

const DISPLAY := preload("res://assets/fonts/Display.ttf")
const BOLD := preload("res://assets/fonts/OpenSans-Bold.ttf")
const TEXT := preload("res://assets/fonts/OpenSans-Regular.ttf")
const DARK := Color("#101728")
const PANEL := Color("#19263d")
const EDGE := Color("#40536b")
const PAPER := Color("#f8f0df")
const DIM := Color("#b7c6d3")
const MINT := Color("#9ee9ce")
const PEACH := Color("#ffad94")
const SAVE_FILE := "user://arena.cfg"
const TOURNAMENT_ROUNDS := 4
const VERSUS_TIMES: Array[int] = [30, 60, 90, 150, 240, 0]
const CPU_LEVELS: Array[String] = ["Einsteiger", "Normal", "Fortgeschritten", "Profi"]
const PRACTICE_PERCENT: Array[int] = [0, 50, 100, 150]
const MUSIC_DEFAULT := 55
const EFFECTS_DEFAULT := 70
const KEYS_ONE := [[KEY_A], [KEY_D], [KEY_W, KEY_SPACE], [KEY_F], [KEY_G], [KEY_Q, KEY_SHIFT], [KEY_S]]
const KEYS_TWO := [[KEY_LEFT], [KEY_RIGHT], [KEY_UP], [KEY_J], [KEY_K], [KEY_L], [KEY_DOWN]]
const GAMEPAD := [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A, JOY_BUTTON_X,
	JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_DPAD_DOWN]

var catalog: ArenaCatalog
var view: ArenaView
var link: DuelLink
var ui: Control
var bout: ArenaBout
var screen := ""
var selection_mode := "campaign"
var selected := Vector2i(0, 5)
var picking := 0
var stage_pick := 1
var versus_bot := true
var versus_stocks := ArenaBout.DEFAULT_STOCKS
var versus_time := ArenaBout.MAX_SECONDS
var versus_difficulty := 1
var practice_behavior := 0
var practice_damage := 0
var chapter := 0
var tournament_round := 0
var tournament_matchups: Array[Vector2i] = []
var tournament_wins := 0
var paused := false
var outcome_shown := false
var heard_lesson := false
var previous_keys := Vector2i.ZERO
var frame_serial := 0
var music: AudioStreamPlayer
var track := ""
var effects: Dictionary = {}
var muted := false
var music_level := MUSIC_DEFAULT
var effects_level := EFFECTS_DEFAULT
var fullscreen := false
var reduced_effects := false
var settings_from_pause := false
var controls_from_pause := false
var fullscreen_button: Button
var completed := false
var lobby_status: Label
var region: Label
var ready_button: Button
var end_connection_button: Button
var host_button: Button
var join_button: Button
var address_box: LineEdit
var port_box: LineEdit
var last_address := ""
var last_port := str(DuelLink.DEFAULT_PORT)


func _ready() -> void:
	catalog = ArenaCatalog.new()
	view = ArenaView.new()
	view.catalog = catalog
	add_child(view)
	link = DuelLink.new()
	link.name = "DuelLink"
	link.arena_count = catalog.arenas.size()
	add_child(link)
	link.lobby_updated.connect(refresh_lobby)
	link.match_started.connect(network_bout)
	link.state_received.connect(receive_state)
	link.connection_lost.connect(network_lost)
	load_settings()
	make_audio()
	apply_audio()
	apply_display()
	view.reduced_effects = reduced_effects
	show_home()



func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for sound: AudioStreamPlayer in effects.values():
		sound.stop()
		sound.stream = null


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_FILE) != OK:
		return
	muted = config.get_value("audio", "muted", false) == true
	completed = config.get_value("campaign", "finished", false) == true
	tournament_wins = bounded_int(config.get_value("tournament", "wins", 0), 0, 0, 1000000)
	music_level = bounded_int(config.get_value("audio", "music", MUSIC_DEFAULT), MUSIC_DEFAULT, 0, 100)
	effects_level = bounded_int(config.get_value("audio", "effects", EFFECTS_DEFAULT), EFFECTS_DEFAULT, 0, 100)
	fullscreen = config.get_value("display", "fullscreen", false) == true
	reduced_effects = config.get_value("display", "reduced_effects", false) == true


func bounded_int(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	return clampi(value, minimum, maximum) if value is int else fallback


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_FILE)
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "music", music_level)
	config.set_value("audio", "effects", effects_level)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "reduced_effects", reduced_effects)
	config.set_value("campaign", "finished", completed)
	config.set_value("tournament", "wins", tournament_wins)
	var result := config.save(SAVE_FILE)
	if result != OK:
		push_warning("Einstellungen konnten nicht gespeichert werden (%s)." % error_string(result))


func make_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	music.finished.connect(repeat_music)
	for cue in ["select", "jump", "swing", "hit", "special", "out", "success", "boss"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % cue)
		player.max_polyphony = 3
		add_child(player)
		effects[cue] = player


func change_music(name: String) -> void:
	if track == name:
		return
	track = name
	music.stop()
	music.stream = load("res://assets/audio/%s.wav" % name)
	repeat_music()


func repeat_music() -> void:
	if not muted and DisplayServer.get_name() != "headless":
		music.play()


func apply_audio() -> void:
	music.volume_db = -13.8 + linear_to_db(maxf(0.0001, music_level / 100.0))
	for effect: AudioStreamPlayer in effects.values():
		effect.volume_db = -9.9 + linear_to_db(maxf(0.0001, effects_level / 100.0))


func toggle_audio() -> void:
	muted = not muted
	if muted:
		music.stop()
		for effect: AudioStreamPlayer in effects.values():
			effect.stop()
	else:
		repeat_music()
	save_settings()


func apply_display() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().min_size = Vector2i(640, 360)
		get_window().mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


func toggle_fullscreen() -> void:
	if DisplayServer.get_name() != "headless":
		fullscreen = get_window().mode != Window.MODE_FULLSCREEN
	else:
		fullscreen = not fullscreen
	apply_display()
	if is_instance_valid(fullscreen_button):
		fullscreen_button.text = display_mode_text()
	save_settings()


func display_mode_text() -> String:
	return "Vollbild (F11)" if fullscreen else "Fenster (F11)"


func play_sound(cue: String) -> void:
	if not muted and DisplayServer.get_name() != "headless" and effects.has(cue):
		var player: AudioStreamPlayer = effects[cue]
		player.play()


func _physics_process(delta: float) -> void:
	if screen != "bout" or bout == null:
		return
	var first := poll_controls(0)
	var second := poll_controls(1) if bout.mode == "local" else 0
	var first_edge := first & ~previous_keys.x
	var second_edge := second & ~previous_keys.y
	previous_keys = Vector2i(first, second)
	if paused:
		if bout.mode != "network":
			return
		first = 0
		first_edge = 0
	if bout.mode == "network":
		if link.hosting:
			var remote := link.consume_controls()
			bout.tick(delta, first, first_edge, remote.x, remote.y)
			frame_serial += 1
			if frame_serial % 2 == 0:
				link.send_state(bout.snapshot())
		else:
			link.send_controls(first, first_edge)
	else:
		bout.tick(delta, first, first_edge, second, second_edge)
	for cue in bout.audio_queue:
		play_sound(cue)
	bout.audio_queue.clear()
	if bout.mode == "training" and bout.tutorial_step == 5 and not heard_lesson and not paused:
		heard_lesson = true
		show_tutorial_finish()
	if bout.winner != ArenaBout.ONGOING and not outcome_shown and not paused:
		outcome_shown = true
		show_result()


func poll_controls(index: int) -> int:
	var bindings: Array = KEYS_ONE if index == 0 else KEYS_TWO
	var flags := 0
	for n in bindings.size():
		for key: int in bindings[n]:
			if Input.is_physical_key_pressed(key):
				flags |= 1 << n
				break
	var pads := Input.get_connected_joypads()
	if pads.size() > index:
		var pad := pads[index]
		for n in GAMEPAD.size():
			if Input.is_joy_button_pressed(pad, GAMEPAD[n]):
				flags |= 1 << n
		var stick := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if stick < -0.35:
			flags |= ArenaBout.LEFT
		elif stick > 0.35:
			flags |= ArenaBout.RIGHT
		if Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y) > 0.55:
			flags |= ArenaBout.DOWN
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER):
			flags |= ArenaBout.DODGE
	return flags


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and not option_is_open():
			go_back()
			get_viewport().set_input_as_handled()
		elif screen == "bout" and bout.mode == "practice" and not paused:
			match event.physical_keycode:
				KEY_R:
					restart_bout()
					get_viewport().set_input_as_handled()
				KEY_F2:
					cycle_practice_behavior()
					get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if (event.button_index == JOY_BUTTON_START and screen == "bout") or (
				event.button_index == JOY_BUTTON_B and not option_is_open()
				and (screen != "bout" or paused or outcome_shown or heard_lesson)):
			go_back()
			get_viewport().set_input_as_handled()


func option_is_open() -> bool:
	var focused := get_viewport().gui_get_focus_owner() as OptionButton
	return is_instance_valid(focused) and focused.get_popup().visible


func go_back() -> void:
	if controls_from_pause:
		show_settings(true)
		return
	if settings_from_pause:
		show_pause()
		return
	match screen:
		"bout":
			if outcome_shown or heard_lesson:
				show_home()
			elif paused:
				resume_bout()
			else:
				show_pause()
		"network":
			link.close()
			show_selection("network")
		"controls":
			show_settings()
		"rules":
			show_selection("versus")
		"select", "settings":
			show_home()


func make_ui() -> void:
	fullscreen_button = null
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.name = "Menü"
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_menu(name: String) -> void:
	bout = null
	view.bout = null
	view.menu_scene = name
	screen = name
	paused = false
	settings_from_pause = false
	controls_from_pause = false
	make_ui()
	change_music("lobby")


func show_home() -> void:
	link.close()
	set_menu("home")
	ribbon(Rect2(67, 90, 48, 4), MINT)
	label("AHELS", Rect2(65, 93, 535, 131), 117, DISPLAY)
	label("ARENA", Rect2(59, 195, 605, 113), 109, DISPLAY)
	label("Der Pixel-Plattform-Fighter eurer Klasse", Rect2(68, 319, 500, 30), 20, TEXT, PAPER)
	var play := button("Solo-Kampagne", Rect2(68, 375, 356, 56), func() -> void: show_selection("campaign"), true)
	button("Turnier", Rect2(68, 441, 356, 46), func() -> void: show_selection("tournament"))
	button("Versus", Rect2(68, 497, 356, 46), func() -> void: show_selection("versus"))
	button("Netzwerk", Rect2(68, 553, 356, 46), func() -> void: show_selection("network"))
	button("Training", Rect2(438, 497, 161, 46), func() -> void: show_selection("practice"))
	if completed:
		label("Kampagne abgeschlossen", Rect2(69, 604, 420, 23), 15, BOLD, MINT)
	button("Einstellungen", Rect2(68, 650, 183, 42), show_settings)
	button("Tutorial", Rect2(264, 650, 140, 42), func() -> void: show_selection("training"))
	label("F11  Vollbild", Rect2(1006, 651, 202, 42), 16, BOLD, DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	play.grab_focus()


func show_settings(from_pause: bool = false) -> void:
	if from_pause:
		make_ui()
		ribbon(Rect2(0, 0, 1280, 720), Color(0.035, 0.055, 0.105, 0.95))
	else:
		set_menu("settings")
	settings_from_pause = from_pause
	controls_from_pause = false
	header("Einstellungen", "Änderungen werden gespeichert", show_pause if from_pause else show_home)
	style_panel(Rect2(60, 143, 563, 358), PANEL, EDGE)
	style_panel(Rect2(651, 143, 568, 358), PANEL, EDGE)
	label("Ton", Rect2(88, 164, 485, 48), 32, DISPLAY)
	label("Anzeige", Rect2(679, 164, 490, 48), 32, DISPLAY)
	var slider := audio_slider("Musik", music_level, 227, true)
	audio_slider("Soundeffekte", effects_level, 317, false)
	var mute_button := button(mute_text(), Rect2(90, 416, 491, 53), toggle_audio)
	mute_button.pressed.connect(func() -> void: mute_button.text = mute_text())
	fullscreen_button = button(display_mode_text(), Rect2(680, 233, 488, 52), toggle_fullscreen)
	var visual := button(effects_text(), Rect2(680, 314, 488, 52), toggle_effects)
	visual.pressed.connect(func() -> void: visual.text = effects_text())
	label("Weniger Partikel und Blinkeffekte. Warnzeichen bleiben sichtbar.",
		Rect2(681, 375, 482, 60), 16, TEXT, DIM, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	button("Steuerungsübersicht", Rect2(61, 537, 353, 54), show_controls)
	slider.grab_focus()


func audio_slider(caption: String, level: int, y: int, is_music: bool) -> HSlider:
	label(caption, Rect2(90, y, 320, 31), 18, BOLD)
	var value_label := label("%d%%" % level, Rect2(450, y, 130, 31), 17, BOLD, MINT, HORIZONTAL_ALIGNMENT_RIGHT)
	var slider := HSlider.new()
	slider.position = Vector2(92, y + 44)
	slider.size = Vector2(487, 20)
	slider.max_value = 100
	slider.step = 1
	slider.value = level
	slider.add_theme_stylebox_override("slider", style(Color("#101b31"), EDGE, 4))
	slider.add_theme_stylebox_override("grabber_area", style(MINT, MINT, 4))
	slider.add_theme_stylebox_override("grabber_area_highlight", style(MINT, MINT, 4))
	ui.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		if is_music:
			music_level = roundi(value)
		else:
			effects_level = roundi(value)
		value_label.text = "%d%%" % value
		apply_audio()
		save_settings())
	return slider


func mute_text() -> String:
	return "Ton einschalten" if muted else "Ton stummschalten"


func effects_text() -> String:
	return "Reduzierte Effekte: An" if reduced_effects else "Reduzierte Effekte: Aus"


func toggle_effects() -> void:
	reduced_effects = not reduced_effects
	view.reduced_effects = reduced_effects
	save_settings()


func show_controls() -> void:
	var from_pause := settings_from_pause
	if from_pause:
		make_ui()
		ribbon(Rect2(0, 0, 1280, 720), Color(0.035, 0.055, 0.105, 0.95))
	else:
		set_menu("controls")
	controls_from_pause = from_pause
	var back := header("Steuerung", "Tastatur und Controller", show_settings.bind(from_pause))
	style_panel(Rect2(61, 144, 1158, 427), PANEL, EDGE)
	var columns := [89, 542, 789, 1002]
	for col in 4:
		label(["Aktion", "Spieler 1", "Spieler 2", "Controller"][col],
			Rect2(columns[col], 164, 190, 38), 18, BOLD, MINT)
	var keys := [
		["Laufen", "A / D", "← / →", "Stick / Steuerkreuz"],
		["Springen / Doppelsprung", "W / Leertaste", "↑", "A"],
		["Angreifen", "F", "J", "X"],
		["Spezialfähigkeit", "G", "K", "Y"],
		["Ausweichen", "Q / Umschalt", "L", "B / RB"],
		["Plattform fallen lassen", "S", "↓", "Stick / Steuerkreuz ↓"],
	]
	for row in keys.size():
		ribbon(Rect2(86, 208 + row*54, 1108, 1), EDGE)
		for col in 4:
			label(keys[row][col], Rect2(columns[col], 213 + row*54, 375 if col == 0 else 192, 41),
				18, BOLD if col == 0 else TEXT, PAPER)
	label("Esc oder Start öffnet das Pausenmenü. F11 schaltet Vollbild um.",
		Rect2(64, 594, 1142, 40), 18, TEXT, DIM)
	back.grab_focus()


func show_selection(kind: String) -> void:
	if selection_mode != kind or screen == "home":
		picking = 0
	selection_mode = kind
	set_menu("select")
	var title := "Figur wählen" if kind != "versus" else "Versus"
	var details := {
		"campaign": "Solo-Kampagne",
		"tournament": "Turniersiege · %d" % tournament_wins if tournament_wins > 0 else "Turnier · Vier Duelle",
		"training": "Tutorial mit Herrn Haidenthaler",
		"practice": "Freies Training · Turnsaal",
		"network": "Netzwerkduell",
		"versus": "Lokal am selben PC",
	}
	var detail: String = details[kind]
	header(title, detail, show_home)

	var chosen := selected.x if picking == 0 else selected.y
	var selected_card: Button
	var two_fighters := kind == "versus" or kind == "practice"
	for i in ArenaCatalog.STUDENTS:
		var x := 59 + (i % 6) * 126
		var y := 139 + (i / 6) * 117
		var card := button("", Rect2(x, y, 115, 107), choose_fighter.bind(i), i == chosen)
		card.tooltip_text = String(catalog.fighters[i]["ability"])
		portrait(i, Rect2(27, 4, 59, 62), card)
		var ink := DARK if i == chosen else PAPER
		var fit := 14 if String(catalog.fighters[i]["name"]).length() < 12 else 12
		label(String(catalog.fighters[i]["name"]), Rect2(4, 69, 107, 20), fit, BOLD, ink,
			HORIZONTAL_ALIGNMENT_CENTER, card)
		label("%02d" % (i+1), Rect2(8, 5, 29, 17), 11, BOLD, ink, HORIZONTAL_ALIGNMENT_LEFT, card)
		if i == chosen:
			selected_card = card
		if i == selected.y and two_fighters:
			label("2", Rect2(83, 5, 23, 17), 12, BOLD, ink if i == chosen else PEACH,
				HORIZONTAL_ALIGNMENT_RIGHT, card)
		if i == selected.x and two_fighters:
			label("1", Rect2(67, 5, 19, 17), 12, BOLD, ink if i == chosen else MINT,
				HORIZONTAL_ALIGNMENT_RIGHT, card)

	var info: Dictionary = catalog.fighters[chosen]
	var accent: Color = info["accent"]
	style_panel(Rect2(829, 139, 392, 456), PANEL, EDGE)
	ribbon(Rect2(829, 139, 392, 3), accent)
	style_panel(Rect2(853, 161, 344, 191), Color("#22334a"), EDGE)
	add_texture(catalog.portraits[chosen], Rect2(880, 162, 170, 188), ui)
	fighter_texture(chosen, Rect2(1048, 194, 119, 158), 0)
	var font_size := 42 if String(info["name"]).length() < 15 else 32
	label(fighter_name(chosen), Rect2(853, 360, 345, 53), font_size, DISPLAY)
	label(String(info["ability"]), Rect2(856, 417, 338, 27), 18, BOLD, accent)
	label(String(info["description"]), Rect2(856, 446, 333, 52), 15, TEXT, DIM,
		HORIZONTAL_ALIGNMENT_LEFT, null, true)
	var names := ["Tempo", "Sprung", "Gewicht"]
	var values: Array[float] = [float(info["speed"]), float(info["jump"]), float(info["weight"])]
	for i in 3:
		var x := 857 + 111 * i
		label(names[i], Rect2(x, 518, 102, 28), 13, BOLD, DIM)
		ribbon(Rect2(x, 553, 92, 5), EDGE)
		ribbon(Rect2(x, 553, 92 * clampf((values[i] - .75) / .52, .1, 1.0), 5), accent)

	if kind == "versus":
		button("Spieler 1", Rect2(59, 620, 119, 51), pick_player.bind(0), picking == 0)
		button("KI-Figur" if versus_bot else "Spieler 2", Rect2(189, 620, 120, 51),
			pick_player.bind(1), picking == 1)
		button("Modus: CPU" if versus_bot else "Modus: 2 am PC", Rect2(321, 620, 166, 51), toggle_versus)
		button(String(catalog.arenas[stage_pick]["name"]) + "  ›", Rect2(499, 620, 177, 51), next_arena)
		button("Regeln", Rect2(687, 620, 115, 51), show_versus_rules)
		button("Runde starten", Rect2(829, 618, 392, 53), start_versus, true)
	elif kind == "practice":
		button("Spieler 1", Rect2(59, 620, 146, 51), pick_player.bind(0), picking == 0)
		button("Übungsgegner", Rect2(218, 620, 151, 51), pick_player.bind(1), picking == 1)
		option_picker("Gegnerverhalten", ArenaBout.PRACTICE_BEHAVIORS, Rect2(389, 620, 200, 51),
			practice_behavior, set_practice_behavior)
		button("Training starten", Rect2(829, 618, 392, 53), start_practice, true)
	elif kind == "network":
		button("Zur Lobby", Rect2(829, 618, 392, 53), show_lobby, true)
	elif kind == "tournament":
		button("Turnier starten", Rect2(829, 618, 392, 53), begin_tournament, true)
	else:
		button("Tutorial starten", Rect2(829, 618, 392, 53), begin_campaign, true)
	if is_instance_valid(selected_card):
		selected_card.grab_focus()


func choose_fighter(id: int) -> void:
	if picking == 0:
		selected.x = id
	else:
		selected.y = id
	show_selection(selection_mode)


func pick_player(index: int) -> void:
	picking = index
	show_selection(selection_mode)


func toggle_versus() -> void:
	versus_bot = not versus_bot
	show_selection(selection_mode)


func next_arena() -> void:
	stage_pick = stage_pick % (catalog.arenas.size() - 1) + 1
	show_selection(selection_mode)


func begin_campaign() -> void:
	chapter = 0
	begin_bout(0, selected.x, 0, "training")


func next_chapter() -> void:
	chapter += 1
	match chapter:
		1:
			begin_bout(1, selected.x, 18, "solo", 0)
		2:
			begin_bout(2, selected.x, 12, "solo", 1)
		3:
			begin_bout(3, selected.x, ArenaCatalog.BOSS, "boss")


func begin_tournament() -> void:
	var arena_indices := range(1, catalog.arenas.size())
	var opponents := range(ArenaCatalog.STUDENTS)
	opponents.erase(selected.x)
	arena_indices.shuffle()
	opponents.shuffle()
	tournament_matchups.clear()
	for round_index in TOURNAMENT_ROUNDS:
		tournament_matchups.append(Vector2i(arena_indices[round_index], opponents[round_index]))
	tournament_round = -1
	next_tournament_round()


func next_tournament_round() -> void:
	tournament_round += 1
	var matchup := tournament_matchups[tournament_round]
	begin_bout(matchup.x, selected.x, matchup.y, "tournament", tournament_round)


func show_versus_rules() -> void:
	set_menu("rules")
	header("Versus-Regeln", "Lokales Duell", show_selection.bind("versus"))
	style_panel(Rect2(59, 145, 1161, 393), PANEL, EDGE)
	label("Versuche pro Figur", Rect2(91, 162, 470, 49), 25, BOLD)
	var stocks := option_picker("Versuche", ["1", "2", "3", "4", "5"], Rect2(734, 166, 442, 50),
		versus_stocks - 1, func(index: int) -> void: versus_stocks = index + 1)
	label("Zeitlimit", Rect2(91, 242, 470, 49), 25, BOLD)
	option_picker("Zeitlimit", ["0:30", "1:00", "1:30", "2:30", "4:00", "Ohne Zeitlimit"],
		Rect2(734, 246, 442, 50), VERSUS_TIMES.find(int(versus_time)),
		func(index: int) -> void: versus_time = float(VERSUS_TIMES[index]))
	label("CPU-Schwierigkeit", Rect2(91, 321, 470, 49), 25, BOLD)
	var cpu := option_picker("CPU-Schwierigkeit", CPU_LEVELS, Rect2(734, 325, 442, 50),
		versus_difficulty, func(index: int) -> void: versus_difficulty = index)
	cpu.disabled = not versus_bot
	label("Höhere Stufen reagieren schneller und nutzen häufiger Spezialfähigkeiten." if versus_bot
		else "Im Duell zu zweit steuern beide Personen selbst.",
		Rect2(91, 392, 1074, 41), 17, TEXT, DIM)
	label("Bei Zeitablauf entscheiden übrige Versuche, dann der niedrigere Rückstoßwert.",
		Rect2(91, 464, 1074, 40), 17, TEXT, DIM)
	button("Übernehmen", Rect2(872, 580, 348, 56), show_selection.bind("versus"), true)
	stocks.grab_focus()


func start_versus() -> void:
	chapter = 0
	begin_bout(stage_pick, selected.x, selected.y, "solo" if versus_bot else "local",
		versus_difficulty, versus_stocks, versus_time)


func set_practice_behavior(index: int) -> void:
	practice_behavior = index
	if bout != null and bout.mode == "practice":
		bout.practice_behavior = index
		bout.bot_clock = 0.0
		bout.bot_direction = 0


func cycle_practice_behavior() -> void:
	set_practice_behavior((practice_behavior + 1) % ArenaBout.PRACTICE_BEHAVIORS.size())


func start_practice() -> void:
	chapter = 0
	begin_bout(0, selected.x, selected.y, "practice", 1, ArenaBout.DEFAULT_STOCKS, 0.0)


func show_lobby() -> void:
	set_menu("network")
	header("Netzwerkduell", String(catalog.fighters[selected.x]["name"]), go_back)
	style_panel(Rect2(59, 148, 564, 350), PANEL, EDGE)
	style_panel(Rect2(646, 148, 575, 350), PANEL, EDGE)
	label("SPIEL HOSTEN", Rect2(83, 169, 430, 57), 40, DISPLAY)
	label("SPIEL BEITRETEN", Rect2(670, 169, 451, 57), 40, DISPLAY)
	label("Gib der anderen Person deine Adresse und den UDP-Port.",
		Rect2(85, 234, 504, 54), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	label("Nutze die Adresse der hostenden Person. Im Internet muss der Host erreichbar sein.",
		Rect2(670, 230, 501, 65), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	region = label("", Rect2(85, 289, 506, 66), 16, BOLD, MINT, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	var arena_button := button(String(catalog.arenas[stage_pick]["name"]) + "  ›", Rect2(85, 365, 510, 49),
		func() -> void: cycle_lobby_arena())
	arena_button.name = "ArenaChoice"
	host_button = button("Host starten", Rect2(85, 429, 510, 48), host_game, true)
	label("HOST-ADRESSE", Rect2(670, 300, 518, 28), 13, BOLD, DIM)
	address_box = field(Rect2(670, 331, 520, 45), last_address, "z. B. 192.168.1.42")
	address_box.text_submitted.connect(func(_value: String) -> void: join_game())
	label("UDP-PORT FÜR HOST UND GAST", Rect2(670, 383, 306, 31), 13, BOLD, DIM)
	port_box = field(Rect2(1028, 380, 162, 42), last_port, "24738")
	join_button = button("Verbinden", Rect2(670, 429, 520, 48), join_game, true)
	style_panel(Rect2(59, 518, 1162, 142), PANEL, EDGE)
	lobby_status = label("", Rect2(84, 532, 1104, 45), 18, BOLD, PAPER)
	end_connection_button = button("Trennen", Rect2(83, 597, 140, 44), disconnect_lobby)
	ready_button = button("Runde starten", Rect2(944, 587, 246, 53), start_network, true)
	refresh_lobby()


func cycle_lobby_arena() -> void:
	stage_pick = stage_pick % (catalog.arenas.size() - 1) + 1
	var chooser := ui.get_node("ArenaChoice") as Button
	chooser.text = String(catalog.arenas[stage_pick]["name"]) + "  ›"


func get_lobby_port() -> int:
	last_address = address_box.text.strip_edges()
	last_port = port_box.text.strip_edges()
	if not last_port.is_valid_int() or last_port.to_int() < 1 or last_port.to_int() > 65535:
		lobby_status.text = "Gib einen gültigen UDP-Port zwischen 1 und 65535 ein."
		return -1
	return last_port.to_int()


func host_game() -> void:
	var port := get_lobby_port()
	if port > 0:
		link.listen(port, selected.x)


func join_game() -> void:
	var port := get_lobby_port()
	if port <= 0:
		return
	if last_address.is_empty():
		lobby_status.text = "Trag zuerst eine Host-Adresse ein."
		return
	link.join(last_address, port, selected.x)


func disconnect_lobby() -> void:
	link.close()
	refresh_lobby()


func refresh_lobby() -> void:
	if screen != "network" or not is_instance_valid(lobby_status):
		return
	lobby_status.text = link.status if not link.status.is_empty() else "Wähle Hosten oder Beitreten."
	region.text = "Deine LAN-Adresse:  %s" % DuelLink.lan_addresses()
	host_button.disabled = link.peer != null
	join_button.disabled = link.peer != null
	end_connection_button.visible = link.peer != null
	ready_button.visible = link.hosting
	ready_button.disabled = not link.can_start()


func start_network() -> void:
	link.start_round(stage_pick)


func network_bout(arena: int, one: int, two: int) -> void:
	begin_bout(arena, one, two, "network")


func network_lost(_message: String) -> void:
	if screen == "bout" and bout != null and bout.mode == "network":
		show_lobby()


func receive_state(state: Dictionary) -> void:
	if screen == "bout" and bout != null and bout.mode == "network":
		bout.apply_snapshot(state)


func begin_bout(arena: int, one: int, two: int, mode: String, difficulty: int = 1,
		stocks: int = ArenaBout.DEFAULT_STOCKS, seconds: float = ArenaBout.MAX_SECONDS) -> void:
	bout = ArenaBout.new(catalog, arena, one, two, mode, difficulty, stocks, seconds)
	if mode == "practice":
		bout.practice_behavior = practice_behavior
		bout.practice_damage = practice_damage
		bout.reset_position(1, false)
	view.bout = bout
	view.match_context = "TURNIER · RUNDE %d / %d" % [tournament_round + 1, TOURNAMENT_ROUNDS] if mode == "tournament" else ""
	view.smooth_remote = mode == "network" and not link.hosting
	screen = "bout"
	paused = false
	outcome_shown = false
	heard_lesson = false
	previous_keys = Vector2i(poll_controls(0), poll_controls(1))
	frame_serial = 0
	make_ui()
	change_music("finale" if mode == "boss" else "arena")


func show_tutorial_finish() -> void:
	style_panel(Rect2(720, 157, 494, 239), Color("#17243a"), EDGE)
	ribbon(Rect2(720, 157, 494, 3), MINT)
	label("TUTORIAL GESCHAFFT", Rect2(743, 177, 449, 51), 38, DISPLAY)
	var practice := selection_mode == "training"
	var finish_text := "Du hast alle fünf Übungen geschafft." if practice else "Die Pausenglocke gibt den Start frei."
	label(finish_text, Rect2(744, 238, 430, 30), 18, TEXT, DIM)
	button("Zum Hauptmenü" if practice else "Zum Pausenhof", Rect2(743, 292, 271, 58),
		show_home if practice else next_chapter, true).grab_focus()
	button("Wiederholen", Rect2(1025, 292, 166, 58), restart_bout)


func show_pause() -> void:
	settings_from_pause = false
	controls_from_pause = false
	paused = true
	make_ui()
	if bout.mode == "practice":
		show_practice_pause()
		return
	overlay()
	var online := bout.mode == "network"
	label("PAUSE", Rect2(384, 199, 513, 86), 64, DISPLAY, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	if online:
		label("Die Netzwerkrunde läuft weiter.", Rect2(387, 285, 505, 32), 17, TEXT, DIM,
			HORIZONTAL_ALIGNMENT_CENTER)
	button("Weiter", Rect2(439, 330, 404, 54), resume_bout, true).grab_focus()
	if not online:
		button("Neu starten", Rect2(439, 397, 404, 50), restart_bout)
	button("Einstellungen", Rect2(439, 456 if not online else 397, 197, 50), show_settings.bind(true))
	button("Zum Hauptmenü", Rect2(646, 456 if not online else 397, 197, 50), show_home)


func show_practice_pause() -> void:
	ribbon(Rect2(0, 0, 1280, 720), Color(0.045, 0.07, 0.13, 0.80))
	style_panel(Rect2(345, 115, 590, 510), PANEL, EDGE)
	ribbon(Rect2(345, 115, 590, 4), MINT)
	label("TRAINING", Rect2(379, 133, 522, 75), 54, DISPLAY, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label("Gegner", Rect2(377, 246, 205, 46), 18, BOLD)
	option_picker("Gegnerverhalten", ArenaBout.PRACTICE_BEHAVIORS, Rect2(597, 246, 303, 46),
		practice_behavior, set_practice_behavior)
	label("Zielwert beim Reset", Rect2(377, 300, 207, 46), 18, BOLD)
	option_picker("Start-Rückstoß", ["0 %", "50 %", "100 %", "150 %"], Rect2(597, 300, 303, 46),
		PRACTICE_PERCENT.find(practice_damage), func(index: int) -> void: practice_damage = PRACTICE_PERCENT[index])
	label("Der Zielwert gilt ab dem nächsten Reset.", Rect2(377, 352, 515, 30), 15, TEXT, DIM)
	button("Weiter", Rect2(377, 401, 253, 54), resume_bout, true).grab_focus()
	button("Zurücksetzen", Rect2(646, 401, 254, 54), restart_bout)
	button("Figurenwahl", Rect2(377, 474, 253, 52), show_selection.bind("practice"))
	button("Einstellungen", Rect2(646, 474, 254, 52), show_settings.bind(true))
	button("Zum Hauptmenü", Rect2(377, 546, 523, 48), show_home)


func resume_bout() -> void:
	settings_from_pause = false
	paused = false
	make_ui()


func restart_bout() -> void:
	var one := bout.fighters[0].id
	var two := bout.fighters[1].id if bout.fighters.size() > 1 else 0
	begin_bout(bout.stage_index, one, two, bout.mode, bout.difficulty, bout.max_stocks, bout.time_limit)


func show_result() -> void:
	make_ui()
	overlay()
	var title := "UNENTSCHIEDEN"
	var subtitle := String(bout.stage["name"])
	var victor := bout.winner
	if victor >= 0:
		var winner_fighter := bout.fighters[victor]
		title = "%s GEWINNT" % fighter_name(winner_fighter.id).to_upper()
	var primary := "Noch eine Runde"
	var next_action := restart_bout
	var enabled := true
	if bout.mode == "network":
		primary = "Revanche starten" if link.hosting else "Host entscheidet über Revanche"
		next_action = start_network
		enabled = link.hosting
	elif bout.mode == "tournament":
		subtitle = "Runde %d von %d · %s" % [tournament_round + 1, TOURNAMENT_ROUNDS, bout.stage["name"]]
		primary = "Runde wiederholen"
		if victor == 0 and tournament_round + 1 < TOURNAMENT_ROUNDS:
			primary = "Nächste Runde"
			next_action = next_tournament_round
		elif victor == 0:
			title = "TURNIER GEWONNEN"
			tournament_wins += 1
			save_settings()
			subtitle = "%s hat alle vier Duelle gewonnen." % bout.fighters[0].profile["name"]
			primary = "Neues Turnier"
			next_action = begin_tournament
	elif selection_mode == "campaign" and chapter > 0:
		primary = "Erneut versuchen"
		if victor == 0 and chapter < 3:
			primary = "Weiter zum Computerraum" if chapter == 1 else "Weiter zu Herrn Grimmer"
			next_action = next_chapter
		elif victor == 0:
			title = "FINALE GESCHAFFT"
			subtitle = "Du hast Herrn Grimmers Regalwelle überstanden."
			primary = "Kampagne erneut spielen"
			next_action = begin_campaign
			completed = true
			save_settings()
	label(title, Rect2(376, 202, 528, 91), 51 if title.length() < 18 else 40,
		DISPLAY, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label(subtitle, Rect2(379, 299, 523, 50), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	var action := button(primary, Rect2(422, 369, 436, 53), next_action, true)
	action.disabled = not enabled
	var home := button("Zum Hauptmenü", Rect2(422, 440, 436, 50), show_home)
	if enabled:
		action.grab_focus()
	else:
		home.grab_focus()


func overlay() -> void:
	ribbon(Rect2(0, 0, 1280, 720), Color(0.045, 0.07, 0.13, 0.72))
	style_panel(Rect2(358, 172, 564, 365), PANEL, EDGE)
	ribbon(Rect2(358, 172, 564, 4), MINT)


func header(title: String, detail: String, back: Callable) -> Button:
	var back_button := button("‹  Zurück", Rect2(57, 48, 118, 43), back)
	label(title, Rect2(196, 34, 600, 68), 52, DISPLAY)
	label(detail, Rect2(861, 49, 359, 42), 18, BOLD, DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	ribbon(Rect2(58, 111, 1162, 2), EDGE)
	return back_button


func label(value: String, area: Rect2, size: int, font: Font = TEXT, color: Color = PAPER,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, parent: Control = null,
		wrap: bool = false) -> Label:
	var item := Label.new()
	item.text = value
	item.position = area.position
	item.size = area.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.horizontal_alignment = alignment
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		item.clip_text = true
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.add_theme_font_override("font", font)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	(ui if parent == null else parent).add_child(item)
	return item


func button(value: String, area: Rect2, action: Callable, primary: bool = false) -> Button:
	var item := Button.new()
	item.text = value
	item.position = area.position
	item.size = area.size
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_font_override("font", BOLD)
	item.add_theme_font_size_override("font_size", 17)
	var base := MINT if primary else Color("#23354f")
	var line_color := MINT if primary else Color("#4d6680")
	item.add_theme_stylebox_override("normal", style(base, line_color, 7))
	item.add_theme_stylebox_override("hover", style(base.lightened(0.14), MINT, 7))
	item.add_theme_stylebox_override("pressed", style(base.darkened(0.12), MINT, 7))
	item.add_theme_stylebox_override("disabled", style(Color("#28374e"), EDGE, 7))
	item.add_theme_stylebox_override("focus", style(Color(0,0,0,0), Color("#ffe3ae"), 7))
	for key in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		item.add_theme_color_override(key, DARK if primary else PAPER)
	item.add_theme_color_override("font_disabled_color", Color("#a4b2c2"))
	item.pressed.connect(func() -> void:
		play_sound("select")
		action.call())
	ui.add_child(item)
	return item


func option_picker(caption: String, values: Array, area: Rect2, selected_index: int,
		action: Callable) -> OptionButton:
	var item := OptionButton.new()
	item.position = area.position
	item.size = area.size
	item.tooltip_text = caption
	item.accessibility_name = caption
	item.add_theme_font_override("font", BOLD)
	item.add_theme_font_size_override("font_size", 17)
	item.add_theme_stylebox_override("normal", style(Color("#23354f"), EDGE, 7))
	item.add_theme_stylebox_override("hover", style(Color("#324b67"), MINT, 7))
	item.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, Color("#ffe3ae"), 7))
	for value: String in values:
		item.add_item(value)
	item.select(selected_index)
	item.item_selected.connect(action)
	ui.add_child(item)
	return item


func fighter_name(index: int) -> String:
	var given_name := String(catalog.fighters[index]["name"])
	return "%s · %02d" % [given_name, index + 1] if index in [5, 7, 15, 16] else given_name


func field(area: Rect2, value: String, placeholder: String) -> LineEdit:
	var item := LineEdit.new()
	item.position = area.position
	item.size = area.size
	item.text = value
	item.placeholder_text = placeholder
	item.max_length = 90
	item.add_theme_font_override("font", TEXT)
	item.add_theme_font_size_override("font_size", 17)
	item.add_theme_color_override("font_color", PAPER)
	item.add_theme_color_override("font_placeholder_color", DIM)
	var background := style(Color("#141e30"), EDGE, 6)
	background.content_margin_left = 13
	background.content_margin_right = 12
	item.add_theme_stylebox_override("normal", background)
	item.add_theme_stylebox_override("focus", style(Color(0,0,0,0), MINT, 6))
	ui.add_child(item)
	return item


func style_panel(area: Rect2, fill: Color, border: Color) -> void:
	var panel := Panel.new()
	panel.position = area.position
	panel.size = area.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style(fill, border, 9))
	ui.add_child(panel)


func style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = false
	return box


func ribbon(area: Rect2, color: Color) -> void:
	var fill := ColorRect.new()
	fill.position = area.position
	fill.size = area.size
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fill)


func portrait(index: int, area: Rect2, parent: Control) -> void:
	add_texture(catalog.portraits[index], area, parent)


func fighter_texture(index: int, area: Rect2, frame: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = catalog.sprites[index]
	atlas.region = Rect2(Vector2(frame * ArenaCatalog.SPRITE_SIZE.x, 0), ArenaCatalog.SPRITE_SIZE)
	atlas.filter_clip = true
	add_texture(atlas, area, ui)


func add_texture(texture: Texture2D, area: Rect2, parent: Control) -> void:
	var item := TextureRect.new()
	item.texture = texture
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.position = area.position
	item.size = area.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
