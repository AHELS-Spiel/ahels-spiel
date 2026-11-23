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
const TOURNAMENT_LEVELS: Array[String] = ["Einsteiger", "Klasse", "Meisterschaft"]
const TOURNAMENT_BOTS := [[0, 0, 1, 1], [0, 1, 2, 3], [2, 2, 3, 3]]
const FIXED_TOURNAMENT_ROUTE := ["pausenhof", "aula", "physiksaal", "dachterrasse"]
const CAMPAIGN_ARENAS := ["pausenhof", "computerraum", "aula", "bibliothek"]
const CAMPAIGN_OPPONENTS := [18, 12, 17, ArenaCatalog.BOSS]
const CAMPAIGN_GOALS := [
	"Treffer erhöhen den Rückstoßwert. Befördere die andere Figur über den Rand.",
	"Nutze den Doppelsprung für die versetzten Plattformen. Mit der Falltaste kommst du wieder hinunter.",
	"Gewinne das Bühnenduell. Weiche gegnerischen Spezialfähigkeiten aus und nutze deine eigene.",
	"Spring über die Regalwelle. Weiche dem Kreidebogen seitlich aus und nutze Grimmers Pause zum Kontern.",
]
const VERSUS_TIMES: Array[int] = [30, 60, 90, 150, 240, 0]
const CPU_LEVELS: Array[String] = ["Einsteiger", "Normal", "Fortgeschritten", "Profi"]
const PRACTICE_PERCENT: Array[int] = [0, 50, 100, 150]
const SURVIVAL_DIFFICULTIES := [0, 1, 2, 3, 3]
const GOALS := {
	"tutorial": ["Trainingsstart", "Schließe die fünf Übungen mit Herrn Haidenthaler ab."],
	"duel": ["Erstes Duell", "Gewinne ein lokales Versus."],
	"tournament": ["Turniersieg", "Gewinne ein Turnier über vier Runden."],
	"campaign": ["Finale geschafft", "Besiege Herrn Grimmer in der Kampagne."],
	"survival": ["Letzter auf der Bühne", "Überstehe alle fünf Überlebenswellen."],
}
const MUSIC_DEFAULT := 55
const EFFECTS_DEFAULT := 70
const VOICE_GREETING := "lukas-04.ogg"
const VOICE_KNOCKOUT := "stefan-03.ogg"
const VOICE_LUKAS_KNOCKOUT := "lukas-02.ogg"
const VOICE_ACTION_GAP := 4.0
const VOICE_IDLE_GAP := 7.5
const FOUR_PLAYER_FORMATS := ["Alle gegen alle", "2 gegen 2 · Blau P1 + P2",
	"2 gegen 2 · Blau P1 + P3", "2 gegen 2 · Blau P1 + P4"]
const GAMEPAD := [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A, JOY_BUTTON_X,
	JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_DPAD_DOWN]

class VoiceClip:
	var fighter_id: int
	var stream: AudioStream

	func _init(speaker: int, audio: AudioStream) -> void:
		fighter_id = speaker
		stream = audio


var catalog: ArenaCatalog
var view: ArenaView
var link: DuelLink
var ui: Control
var bout: ArenaBout
var screen := ""
var home_focus := "Solo-Kampagne"
var selection_mode := "campaign"
var selected := Vector2i(0, 5)
var extra_picks := Vector2i(9, 10)
var picking := 0
var stage_pick := 1
var class_duel_opponent := -1
var host_stage_pick := 1
var arena_picker_source := "versus"
var survival_stage_pick := 6
var survival_arena := 0
var survival_wave := 0
var survival_best := 0
var survival_opponents: Array[int] = []
var local_goals := PackedStringArray()
var versus_bot := true
var versus_four := false
var versus_team_partner := 0
var versus_stocks := ArenaBout.DEFAULT_STOCKS
var versus_time := ArenaBout.MAX_SECONDS
var versus_difficulty := 1
var practice_behavior := 0
var practice_damage := 0
var chapter := 0
var tournament_round := 0
var tournament_matchups: Array[Vector2i] = []
var tournament_wins := 0
var tournament_level := 1
var tournament_fixed_route := false
var tournament_retries := 0
var paused := false
var outcome_shown := false
var heard_lesson := false
var previous_keys := PackedInt32Array([0, 0, 0, 0])
var frame_serial := 0
var quitting := false
var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var fighter_voices: Dictionary[int, Array] = {}
var voice_clips: Dictionary[String, VoiceClip] = {}
var next_voice_clip: Dictionary = {}
var ambient_voices: Array[VoiceClip] = []
var next_ambient_voice := 0
var prefer_event_voice := true
var voices_enabled := true
var last_bout_voice_at := 0.0
var knockout_playing := false
var pending_knockouts: Array[int] = []
var match_voice_keys: Array[int] = []
var match_voice_ids: Array[int] = []
var track := ""
var effects: Dictionary = {}
var muted := false
var music_level := MUSIC_DEFAULT
var effects_level := EFFECTS_DEFAULT
var fullscreen := false
var reduced_effects := false
var pause_page := ""
var keyboard := ArenaKeys.new()
var key_capture := Vector2i(-1, -1)
var binding_message: Label
var fullscreen_button: Button
var completed := false
var lobby_status: Label
var region: Label
var ready_button: Button
var rematch_button: Button
var lobby_matchup: Label
var end_connection_button: Button
var host_button: Button
var host_size_picker: OptionButton
var host_format_picker: OptionButton
var host_size := 2
var host_team_partner := 0
var join_button: Button
var address_box: LineEdit
var port_box: LineEdit
var last_address := ""
var last_port := str(DuelLink.DEFAULT_PORT)


func _ready() -> void:
	get_tree().auto_accept_quit = false
	bind_menu_buttons()
	catalog = ArenaCatalog.new()
	view = ArenaView.new()
	view.catalog = catalog
	view.keyboard = keyboard
	add_child(view)
	link = DuelLink.new()
	link.name = "DuelLink"
	for entry in catalog.arenas:
		link.arena_ids.append(String(entry["id"]))
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



func bind_menu_buttons() -> void:
	var buttons := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B}
	for action: String in buttons:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or not is_node_ready() or quitting:
		return
	quitting = true
	set_physics_process(false)
	set_process_input(false)
	link.close()
	stop_audio()
	# Let the audio mixer retire active playback before destroying the scene.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for sound: AudioStreamPlayer in effects.values():
		sound.stop()
		sound.stream = null
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_FILE) != OK:
		return
	muted = saved_flag(config.get_value("audio", "muted", false))
	voices_enabled = saved_flag(config.get_value("audio", "class_voices", true))
	completed = saved_flag(config.get_value("campaign", "finished", false))
	tournament_wins = bounded_int(config.get_value("tournament", "wins", 0), 0, 0, 1000000)
	survival_best = bounded_int(config.get_value("survival", "best_wave", 0), 0, 0, SURVIVAL_DIFFICULTIES.size())
	var saved_goals: Variant = config.get_value("goals", "achieved", PackedStringArray())
	if saved_goals is PackedStringArray:
		local_goals = saved_goals
	music_level = bounded_int(config.get_value("audio", "music", MUSIC_DEFAULT), MUSIC_DEFAULT, 0, 100)
	effects_level = bounded_int(config.get_value("audio", "effects", EFFECTS_DEFAULT), EFFECTS_DEFAULT, 0, 100)
	fullscreen = saved_flag(config.get_value("display", "fullscreen", false))
	reduced_effects = saved_flag(config.get_value("display", "reduced_effects", false))
	keyboard.load_layouts(config.get_value("controls", "keyboard", []))


func saved_flag(value: Variant) -> bool:
	return value is bool and bool(value)


func bounded_int(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	return clampi(value, minimum, maximum) if value is int else fallback


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_FILE)
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "class_voices", voices_enabled)
	config.set_value("audio", "music", music_level)
	config.set_value("audio", "effects", effects_level)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "reduced_effects", reduced_effects)
	config.set_value("controls", "keyboard", keyboard.layouts)
	config.set_value("campaign", "finished", completed)
	config.set_value("tournament", "wins", tournament_wins)
	config.set_value("survival", "best_wave", survival_best)
	config.set_value("goals", "achieved", local_goals)
	var result := config.save(SAVE_FILE)
	if result != OK:
		push_warning("Einstellungen konnten nicht gespeichert werden (%s)." % error_string(result))


func make_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	music.finished.connect(repeat_music)
	for cue in ["select", "jump", "swing", "hit", "special", "out", "success", "boss", "combo"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % cue)
		player.max_polyphony = 3
		add_child(player)
		effects[cue] = player
	for id in catalog.class_duel_fighters:
		var profile: Dictionary = catalog.fighters[id]["class_duel"]
		var clips: Array[VoiceClip] = []
		for filename: String in profile["clips"]:
			var stream := load_voice_stream(filename)
			if stream == null:
				continue
			var clip := VoiceClip.new(id, stream)
			voice_clips[filename] = clip
			clips.append(clip)
			if filename not in [VOICE_GREETING, VOICE_KNOCKOUT]:
				ambient_voices.append(clip)
		if not clips.is_empty():
			fighter_voices[id] = clips
	if not voice_clips.is_empty():
		voice = AudioStreamPlayer.new()
		add_child(voice)
		voice.finished.connect(apply_music_level)


func load_voice_stream(filename: String) -> AudioStream:
	var path := "res://assets/class_voice/%s" % filename
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


func change_music(name: String) -> void:
	if track == name:
		return
	track = name
	music.stop()
	var loop := load("res://assets/audio/%s.ogg" % name) as AudioStreamOggVorbis
	loop.loop = true
	music.stream = loop
	repeat_music()


func repeat_music() -> void:
	if not muted and not quitting and DisplayServer.get_name() != "headless":
		music.play()


func voice_is_playing() -> bool:
	return is_instance_valid(voice) and voice.playing


func apply_music_level() -> void:
	var duck := 6.0 if voice_is_playing() else 0.0
	music.volume_db = -11.3 + linear_to_db(maxf(0.0001, music_level / 100.0)) - duck


func apply_audio() -> void:
	apply_music_level()
	var effect_level_db := linear_to_db(maxf(0.0001, effects_level / 100.0))
	for effect: AudioStreamPlayer in effects.values():
		effect.volume_db = -9.9 + effect_level_db
	if is_instance_valid(voice):
		voice.volume_db = -6.5 + effect_level_db


func stop_audio() -> void:
	music.stop()
	for effect: AudioStreamPlayer in effects.values():
		effect.stop()
	stop_class_voice()


func stop_class_voice() -> void:
	pending_knockouts.clear()
	knockout_playing = false
	if voice_is_playing():
		voice.stop()
		apply_music_level()


func toggle_audio() -> void:
	muted = not muted
	if muted:
		stop_audio()
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
	if muted or quitting or DisplayServer.get_name() == "headless":
		return
	if effects.has(cue):
		var player: AudioStreamPlayer = effects[cue]
		player.play()


func play_voice(clip: VoiceClip) -> float:
	if clip == null or not voices_enabled or muted or quitting or DisplayServer.get_name() == "headless":
		return 0.0
	voice.stop()
	voice.stream = clip.stream
	voice.play()
	apply_music_level()
	return clip.stream.get_length()


func play_bout_voice(clip: VoiceClip, caption: String, knockout: bool = false) -> bool:
	var seconds := play_voice(clip)
	if seconds <= 0.0:
		return false
	last_bout_voice_at = bout.time
	knockout_playing = knockout
	view.show_spotlight(clip.fighter_id, maxf(seconds, 1.8), caption)
	return true


func play_class_voice(id: int) -> void:
	var clips: Array[VoiceClip] = fighter_voices[id]
	var index := int(next_voice_clip.get(id, 0))
	var caption := "Stimme %d/%d" % [index + 1, clips.size()] if clips.size() > 1 else "Stimme"
	var played := play_bout_voice(clips[index], caption) if screen == "bout" else play_voice(clips[index]) > 0.0
	if played:
		next_voice_clip[id] = (index + 1) % clips.size()


func refresh_match_voice_controls() -> void:
	match_voice_keys = keyboard.voice_shortcuts()
	match_voice_ids.clear()
	view.voice_hint = ""
	var local_slot := link.local_slot if bout.mode == "network" else 0
	for offset in bout.fighters.size():
		if match_voice_ids.size() >= match_voice_keys.size():
			break
		var slot := (local_slot + offset) % bout.fighters.size()
		var id: int = bout.fighters[slot].id
		if fighter_voices.has(id) and id not in match_voice_ids:
			match_voice_ids.append(id)
	var labels := PackedStringArray()
	for index in match_voice_ids.size():
		labels.append("%s  %s" % [keyboard.key_caption(match_voice_keys[index]),
			fighter_name(match_voice_ids[index])])
	view.voice_hint = "     ".join(labels)


func handle_voice_shortcut(key: int) -> bool:
	if screen != "bout" or paused or bout.winner != ArenaBout.ONGOING:
		return false
	var index := match_voice_keys.find(key)
	if index < 0 or index >= match_voice_ids.size():
		return false
	if not voices_enabled or muted:
		view.show_voice_status("Klassenstimmen sind aus." if not voices_enabled else "Ton ist stumm.")
		return true
	play_class_voice(match_voice_ids[index])
	return true


func play_bout_audio() -> void:
	var activity := false
	for cue in bout.audio_queue:
		play_sound(cue)
		if cue in ["hit", "combo", "special", "out", "boss", "success"]:
			activity = true
	bout.audio_queue.clear()
	var featured := -1
	for id in bout.spotlight_queue:
		if not paused and id in catalog.class_duel_fighters:
			featured = id
			if not voice_is_playing():
				view.show_spotlight(id, 1.8)
	bout.spotlight_queue.clear()
	if not paused and voices_enabled and not muted and not voice_clips.is_empty():
		pending_knockouts.append_array(bout.knockout_queue)
		play_automatic_voice(activity, featured)
	bout.knockout_queue.clear()


func play_automatic_voice(activity: bool, featured: int) -> void:
	if not pending_knockouts.is_empty():
		# A knockout can interrupt a comment. Simultaneous knockouts play in order.
		if not (knockout_playing and voice_is_playing()):
			var loser := catalog.fighters[pending_knockouts.pop_front()]
			var use_lukas := String(loser["id"]) == "figur-11" and voice_clips.has(VOICE_LUKAS_KNOCKOUT)
			var filename := VOICE_LUKAS_KNOCKOUT if use_lukas else VOICE_KNOCKOUT
			play_bout_voice(voice_clips.get(filename), "Ring-out" if use_lukas else "Knocked out", true)
		return
	if voice_is_playing() or bout.starts_in > 0.0 or bout.winner != ArenaBout.ONGOING \
			or (bout.mode == "training" and bout.tutorial_step == 5):
		return
	var gap := bout.time - last_bout_voice_at
	if gap < VOICE_ACTION_GAP or (not activity and featured < 0 and gap < VOICE_IDLE_GAP):
		return
	if featured >= 0 and prefer_event_voice:
		var profile: Dictionary = catalog.fighters[featured]["class_duel"]
		if play_bout_voice(voice_clips.get(profile.get("event_clip", "")), profile["callout"]):
			prefer_event_voice = false
			return
	if not ambient_voices.is_empty() and play_bout_voice(ambient_voices[next_ambient_voice], "Zwischenruf"):
		next_ambient_voice = (next_ambient_voice + 1) % ambient_voices.size()
		prefer_event_voice = true


func update_match_music() -> void:
	if track != "arena" or bout.mode in ["training", "practice"] or bout.winner != ArenaBout.ONGOING:
		return
	var contenders := 0
	var last_stocks := bout.max_stocks > 1
	for fighter in bout.fighters:
		contenders += int(fighter.stocks > 0)
		last_stocks = last_stocks and fighter.stocks <= 1
	last_stocks = last_stocks and contenders > 1
	var close_to_time := bout.time_limit >= 30.0 and bout.time >= bout.time_limit - 24.0
	if bout.starts_in == 0.0 and (last_stocks or close_to_time):
		change_music("pressure")


func _physics_process(delta: float) -> void:
	if screen != "bout" or bout == null:
		return
	var first := read_controls(0)
	if paused:
		if bout.mode != "network":
			return
		first = Vector2i.ZERO
	if bout.mode == "network":
		if link.hosting:
			var remote := link.consume_controls()
			bout.tick(delta, first.x, first.y, remote[0].x, remote[0].y, remote.slice(1))
			frame_serial += 1
			if frame_serial % 2 == 0:
				link.send_state(bout.snapshot())
		else:
			link.send_controls(first.x, first.y)
	else:
		var second := read_controls(1) if bout.mode == "local" else Vector2i.ZERO
		var extras: Array[Vector2i] = []
		for slot in range(2, bout.fighters.size()):
			extras.append(read_controls(slot))
		bout.tick(delta, first.x, first.y, second.x, second.y, extras)
	update_match_music()
	play_bout_audio()
	if bout.mode == "training" and bout.tutorial_step == 5 and not heard_lesson and not paused:
		heard_lesson = true
		show_tutorial_finish()
	if bout.winner != ArenaBout.ONGOING and not outcome_shown and not paused:
		outcome_shown = true
		show_result()


func read_controls(index: int) -> Vector2i:
	var held := poll_controls(index)
	var pressed := held & ~previous_keys[index]
	previous_keys[index] = held
	return Vector2i(held, pressed)


func poll_controls(index: int) -> int:
	var bindings: Array = keyboard.layouts[index]
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
		if key_capture.x >= 0:
			capture_binding(event.physical_keycode)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE and not option_is_open():
			go_back()
			get_viewport().set_input_as_handled()
		elif not (event.alt_pressed or event.ctrl_pressed or event.meta_pressed) \
				and handle_voice_shortcut(event.physical_keycode):
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
	if key_capture.x >= 0:
		cancel_binding()
		return
	match pause_page:
		"settings":
			show_pause()
			return
		"controls":
			show_settings(true)
			return
		"bindings":
			show_controls()
			return
		"moves":
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
		"bindings":
			show_controls()
		"rules":
			show_selection("versus", "Regeln")
		"arenas":
			leave_arena_picker()
		"moves":
			show_selection(selection_mode, "Moves ansehen")
		"select":
			if selection_mode == "class_duel":
				show_class_duels()
			else:
				show_home()
		"class_duels", "settings", "chapter", "tournament_board", "goals":
			show_home()


func make_ui() -> void:
	key_capture = Vector2i(-1, -1)
	fullscreen_button = null
	rematch_button = null
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.name = "Menü"
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_menu(name: String) -> void:
	stop_class_voice()
	if screen == "home" and name != "home":
		var focused := get_viewport().gui_get_focus_owner() as Button
		if is_instance_valid(focused):
			home_focus = focused.text
	bout = null
	view.bout = null
	view.menu_scene = name
	screen = name
	paused = false
	pause_page = ""
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
	button("Klassenduelle", Rect2(438, 375, 175, 56), show_class_duels)
	button("Turnier", Rect2(68, 441, 356, 46), func() -> void: show_selection("tournament"))
	button("Versus", Rect2(68, 497, 356, 46), func() -> void: show_selection("versus"))
	button("Netzwerk", Rect2(68, 553, 356, 46), func() -> void: show_selection("network"))
	button("Training", Rect2(438, 497, 175, 46), func() -> void: show_selection("practice"))
	button("Überleben", Rect2(438, 441, 175, 46), func() -> void: show_selection("survival"))
	if completed:
		label("Kampagne abgeschlossen", Rect2(69, 604, 420, 23), 15, BOLD, MINT)
	button("Einstellungen", Rect2(68, 650, 183, 42), show_settings)
	button("Tutorial", Rect2(264, 650, 140, 42), func() -> void: show_selection("training"))
	button("Ziele", Rect2(418, 650, 111, 42), show_goals)
	if completed:
		button("Bossprobe", Rect2(438, 553, 175, 46), func() -> void: show_selection("boss_practice"))
	label("F11  Vollbild", Rect2(1006, 651, 202, 42), 16, BOLD, DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	for item in ui.get_children():
		if item is Button and item.text == home_focus:
			item.grab_focus()
			return
	play.grab_focus()


func show_class_duels() -> void:
	set_menu("class_duels")
	var back := header("Klassenduelle", "Solo · 2 Versuche · 90 Sekunden", show_home)
	var first_duel: Button
	for slot in catalog.class_duel_fighters.size():
		var id := catalog.class_duel_fighters[slot]
		var fighter := catalog.fighters[id]
		var profile: Dictionary = fighter["class_duel"]
		var arena := catalog.arena_index(profile["arena"])
		var accent: Color = fighter["accent"]
		var x := 60 + 393 * slot
		style_panel(Rect2(x, 149, 374, 506), PANEL, EDGE)
		ribbon(Rect2(x, 149, 374, 3), accent)
		portrait(id, Rect2(x + 7, 182, 159, 202), ui)
		add_texture(catalog.backdrops[arena], Rect2(x + 172, 206, 186, 106), ui)
		label(arena_name(arena), Rect2(x + 172, 315, 181, 29), 15, BOLD, DIM)
		label(fighter_name(id), Rect2(x + 20, 367, 336, 55), 38, DISPLAY)
		label(fighter["ability"], Rect2(x + 20, 420, 334, 30), 18, BOLD, accent)
		label(profile["hint"], Rect2(x + 20, 453, 335, 61), 16, TEXT, PAPER,
			HORIZONTAL_ALIGNMENT_LEFT, null, true)
		if fighter_voices.has(id):
			var voice_button := button(voice_preview_caption(id), Rect2(x + 19, 544, 336, 37),
				play_class_voice.bind(id))
			voice_button.pressed.connect(func() -> void: voice_button.text = voice_preview_caption(id))
			voice_button.disabled = muted or not voices_enabled
			label(profile["voice_note"], Rect2(x + 20, 511, 334, 30), 13, TEXT, DIM)
		var duel := button("Gegen %s spielen" % fighter_name(id), Rect2(x + 19, 593, 336, 45),
			select_class_duel.bind(id), true)
		if slot == 0:
			first_duel = duel
	if is_instance_valid(first_duel):
		first_duel.grab_focus()
	else:
		back.grab_focus()


func voice_preview_caption(id: int) -> String:
	var total: int = fighter_voices[id].size()
	if total <= 1:
		return "Stimme anhören"
	return "Stimme %d/%d anhören" % [int(next_voice_clip.get(id, 0)) + 1, total]


func select_class_duel(opponent: int) -> void:
	class_duel_opponent = opponent
	show_selection("class_duel")


func start_class_duel() -> void:
	var profile: Dictionary = catalog.fighters[class_duel_opponent]["class_duel"]
	chapter = 0
	begin_bout(catalog.arena_index(profile["arena"]), selected.x, class_duel_opponent, "class_duel", 1, 2, 90.0)


func show_goals() -> void:
	set_menu("goals")
	header("Lokale Ziele", "Fortschritt auf diesem PC", show_home).grab_focus()
	var row := 0
	for id: String in GOALS:
		var achieved := id in local_goals
		match id:
			"tournament":
				achieved = tournament_wins > 0
			"campaign":
				achieved = completed
			"survival":
				achieved = survival_best == SURVIVAL_DIFFICULTIES.size()
		var y := 146 + row * 96
		style_panel(Rect2(60, y, 1160, 84), PANEL, EDGE)
		label(GOALS[id][0], Rect2(86, y + 8, 831, 32), 21, BOLD)
		label(GOALS[id][1], Rect2(86, y + 42, 831, 28), 16, TEXT, DIM)
		label("ERREICHT" if achieved else "OFFEN", Rect2(997, y + 22, 191, 39), 15, BOLD,
			MINT if achieved else DIM, HORIZONTAL_ALIGNMENT_RIGHT)
		row += 1


func unlock_goal(id: String) -> bool:
	if id in local_goals:
		return false
	local_goals.append(id)
	save_settings()
	return true


func preferences_page(page: String, from_pause: bool) -> void:
	if from_pause:
		make_ui()
		ribbon(Rect2(0, 0, 1280, 720), Color(0.035, 0.055, 0.105, 0.95))
		pause_page = page
	else:
		set_menu(page)


func show_settings(from_pause: bool = false) -> void:
	preferences_page("settings", from_pause)
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
	if is_instance_valid(voice):
		var voice_button := button(voices_caption(), Rect2(433, 537, 332, 54), toggle_voices)
		voice_button.pressed.connect(func() -> void: voice_button.text = voices_caption())
	slider.grab_focus()


func voices_caption() -> String:
	return "Klassenstimmen an" if voices_enabled else "Klassenstimmen aus"


func toggle_voices() -> void:
	voices_enabled = not voices_enabled
	if not voices_enabled:
		stop_class_voice()
	save_settings()


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
	var from_pause := not pause_page.is_empty()
	preferences_page("controls", from_pause)
	var back := header("Steuerung", "Tastatur und Controller", show_settings.bind(from_pause))
	style_panel(Rect2(61, 144, 1158, 427), PANEL, EDGE)
	var columns := [89, 378, 517, 656, 795, 966]
	for col in columns.size():
		label(["Aktion", "Spieler 1", "Spieler 2", "Spieler 3", "Spieler 4", "Controller"][col],
			Rect2(columns[col], 164, 130, 38), 17, BOLD, MINT)
	var actions := ["Laufen", "Springen / Doppelsprung", "Angreifen", "Spezialfähigkeit",
		"Ausweichen", "Plattform fallen lassen"]
	var pads := ["Stick / Steuerkreuz", "A", "X", "Y", "B / RB", "Stick / Steuerkreuz ↓"]
	for row in actions.size():
		var y := 213 + row * 54
		ribbon(Rect2(86, y - 5, 1108, 1), EDGE)
		label(actions[row], Rect2(columns[0], y, 266, 41), 18, BOLD)
		for player in 4:
			var aliases := keyboard.caption(player, row + 1)
			if row == 0:
				aliases = keyboard.caption(player, 0) + " / " + aliases
			label(aliases, Rect2(columns[player + 1], y, 137, 41), 15)
		label(pads[row], Rect2(columns[5], y, 227, 41), 17)
	label("Esc oder Start öffnet Pause. F11 schaltet Vollbild um.",
		Rect2(64, 589, 760, 35), 18, TEXT, DIM)
	if not fighter_voices.is_empty():
		var keys := keyboard.voice_shortcuts()
		var captions := PackedStringArray()
		for key in keys:
			captions.append(keyboard.key_caption(key))
		if not captions.is_empty():
			label("Stimmen im Kampf · " + " / ".join(captions),
				Rect2(64, 625, 760, 36), 17, TEXT, DIM)
	button("Tastenbelegung ändern", Rect2(858, 584, 361, 53), show_bindings)
	back.grab_focus()


func show_bindings(focus: Vector2i = Vector2i(-1, -1), hint: String = "") -> void:
	preferences_page("bindings", not pause_page.is_empty())
	var back := header("Tastenbelegung", "Vier Tastaturlayouts", show_controls)
	style_panel(Rect2(60, 151, 1160, 406), PANEL, EDGE)
	for player in 4:
		label("Spieler %d" % (player + 1), Rect2(370 + 207 * player, 162, 195, 31), 17, BOLD, MINT)
	for action in ArenaKeys.ACTION_NAMES.size():
		var y := 203 + action * 48
		label(ArenaKeys.ACTION_NAMES[action], Rect2(86, y, 270, 42), 17, BOLD)
		for player in 4:
			var target := Vector2i(player, action)
			var key_button := button(keyboard.caption(player, action), Rect2(370 + 207 * player, y, 195, 40),
				start_key_capture.bind(target))
			if target == focus:
				key_button.grab_focus()
	binding_message = label(hint if not hint.is_empty() else "Wähle eine Aktion und drücke die gewünschte Taste.",
		Rect2(63, 567, 1155, 44), 18, BOLD, MINT)
	button("Standard wiederherstellen", Rect2(62, 625, 315, 50), restore_bindings)
	button("Eingabe abbrechen", Rect2(391, 625, 255, 50), cancel_binding)
	if focus.x < 0:
		back.grab_focus()


func start_key_capture(target: Vector2i) -> void:
	key_capture = target
	binding_message.text = "Neue Taste für Spieler %d · %s drücken. Esc bricht ab." % [
		target.x + 1, ArenaKeys.ACTION_NAMES[target.y]]


func capture_binding(key: int) -> void:
	if key == KEY_ESCAPE:
		cancel_binding()
		return
	if not keyboard.valid_key(key):
		binding_message.text = "Diese Taste ist reserviert. Wähle eine andere Taste oder drücke Esc."
		return
	var conflict := keyboard.conflict(key, key_capture)
	if not conflict.is_empty():
		binding_message.text = "Bereits belegt für %s. Wähle eine andere Taste oder drücke Esc." % conflict
		return
	var target := key_capture
	keyboard.layouts[target.x][target.y] = [key]
	save_settings()
	show_bindings(target, "Taste gespeichert.")


func cancel_binding() -> void:
	if key_capture.x < 0:
		return
	key_capture = Vector2i(-1, -1)
	binding_message.text = "Eingabe abgebrochen."


func restore_bindings() -> void:
	keyboard.restore_defaults()
	save_settings()
	show_bindings(Vector2i(-1, -1), "Standardtasten wiederhergestellt.")


func show_selection(kind: String, focus_caption: String = "") -> void:
	if selection_mode != kind or screen == "home" or kind == "class_duel":
		picking = 0
	selection_mode = kind
	set_menu("select")
	var title := "Figur wählen" if kind != "versus" else "Versus"
	var details := {
		"campaign": "Solo-Kampagne",
		"tournament": "Turniersiege · %d" % tournament_wins if tournament_wins > 0 else "Turnier · Vier Duelle",
		"training": "Tutorial mit Herrn Haidenthaler",
		"practice": "Freies Training · Turnsaal",
		"survival": "Überleben · Bestwert %d / %d" % [survival_best, SURVIVAL_DIFFICULTIES.size()],
		"boss_practice": "Bossprobe · Bibliothek",
		"network": "Netzwerkduell",
		"versus": "Lokal am selben PC",
	}
	var detail: String
	if kind == "class_duel":
		detail = "Klassenduell · gegen %s" % fighter_name(class_duel_opponent)
	else:
		detail = details[kind]
	header(title, detail, show_class_duels if kind == "class_duel" else show_home)

	var lineup := PackedInt32Array([selected.x, selected.y, extra_picks.x, extra_picks.y])
	var chosen := lineup[picking]
	var selected_card: Button
	var two_fighters := kind == "versus" or kind == "practice"
	for i in ArenaCatalog.STUDENTS:
		var x := 59 + (i % 6) * 126
		var y := 139 + (i / 6) * 117
		var card := button("", Rect2(x, y, 115, 107), choose_fighter.bind(i), i == chosen)
		card.tooltip_text = String(catalog.fighters[i]["ability"])
		card.accessibility_name = "%02d %s" % [i + 1, catalog.fighters[i]["name"]]
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
		if kind == "versus" and versus_four:
			for slot in range(2, 4):
				if lineup[slot] == i:
					label(str(slot + 1), Rect2(83 + (slot - 3) * 42, 24, 23, 17), 12, BOLD,
						ink if i == chosen else ArenaView.PLAYER_COLORS[slot], HORIZONTAL_ALIGNMENT_RIGHT, card)

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
	button("Moves ansehen", Rect2(853, 565, 342, 35), show_move_list.bind(chosen, picking))

	if kind == "versus" and versus_four:
		for slot in 4:
			button("P%d" % (slot + 1), Rect2(59 + 83 * slot, 620, 74, 51), pick_player.bind(slot), picking == slot)
		button("Modus: 4 am PC", Rect2(391, 620, 169, 51), toggle_versus)
		button(arena_name(stage_pick) + "  ›", Rect2(572, 620, 177, 51), show_arena_picker)
		button("Regeln", Rect2(761, 620, 100, 51), show_versus_rules)
		button("Runde starten", Rect2(873, 618, 348, 53), start_versus, true)
		option_picker("Kampfart", FOUR_PLAYER_FORMATS, Rect2(59, 677, 338, 35), versus_team_partner,
			func(index: int) -> void: versus_team_partner = index)
	elif kind == "versus":
		button("Spieler 1", Rect2(59, 620, 119, 51), pick_player.bind(0), picking == 0)
		button("KI-Figur" if versus_bot else "Spieler 2", Rect2(189, 620, 120, 51),
			pick_player.bind(1), picking == 1)
		button("Modus: CPU" if versus_bot else "Modus: 2 am PC", Rect2(321, 620, 166, 51), toggle_versus)
		button(arena_name(stage_pick) + "  ›", Rect2(499, 620, 177, 51), show_arena_picker)
		button("Regeln", Rect2(687, 620, 115, 51), show_versus_rules)
		button("Runde starten", Rect2(829, 618, 392, 53), start_versus, true)
	elif kind == "practice":
		button("Spieler 1", Rect2(59, 620, 146, 51), pick_player.bind(0), picking == 0)
		button("Übungsgegner", Rect2(218, 620, 151, 51), pick_player.bind(1), picking == 1)
		option_picker("Gegnerverhalten", ArenaBout.PRACTICE_BEHAVIORS, Rect2(389, 620, 200, 51),
			practice_behavior, set_practice_behavior)
		button("Training starten", Rect2(829, 618, 392, 53), start_practice, true)
	elif kind == "survival":
		button(arena_name(survival_stage_pick) + "  ›", Rect2(59, 620, 223, 51), show_arena_picker.bind("survival"))
		label("3 Versuche für 5 Wellen", Rect2(307, 624, 410, 43), 17, BOLD, DIM)
		button("Überleben starten", Rect2(829, 618, 392, 53), begin_survival, true)
	elif kind == "class_duel":
		button("Duell starten", Rect2(829, 618, 392, 53), start_class_duel, true)
	elif kind == "boss_practice":
		button("Bossprobe starten", Rect2(829, 618, 392, 53), begin_boss_practice, true)
	elif kind == "network":
		button("Zur Lobby", Rect2(829, 618, 392, 53), show_lobby, true)
	elif kind == "tournament":
		option_picker("Turnierstufe", TOURNAMENT_LEVELS, Rect2(59, 620, 227, 51), tournament_level,
			func(index: int) -> void: tournament_level = index)
		option_picker("Arenareihenfolge", ["Zufällige Arenen", "Feste Route"], Rect2(301, 620, 251, 51),
			1 if tournament_fixed_route else 0, func(index: int) -> void: tournament_fixed_route = index == 1)
		button("Turnier starten", Rect2(829, 618, 392, 53), begin_tournament, true)
	else:
		button("Tutorial starten", Rect2(829, 618, 392, 53), begin_campaign, true)
	for item in ui.get_children():
		if item is Button and not focus_caption.is_empty() and item.text == focus_caption:
			item.grab_focus()
			return
	if is_instance_valid(selected_card):
		selected_card.grab_focus()


func show_move_list(id: int, player: int, from_pause: bool = false) -> void:
	preferences_page("moves", from_pause)
	var back_action := show_pause if from_pause else show_selection.bind(selection_mode, "Moves ansehen")
	header("Move-Liste", fighter_name(id), back_action).grab_focus()
	var profile := catalog.fighters[id]
	var accent: Color = profile["accent"]
	style_panel(Rect2(59, 148, 280, 462), PANEL, EDGE)
	portrait(id, Rect2(83, 168, 230, 268), ui)
	label("VERSTÄRKTER GRUNDANGRIFF", Rect2(83, 445, 230, 34), 14, BOLD, accent, HORIZONTAL_ALIGNMENT_CENTER)
	label(ArenaMoves.move_name(profile, profile["focus"]), Rect2(76, 483, 246, 42), 22, DISPLAY,
		PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label("+12 % Reichweite und Schaden", Rect2(75, 526, 249, 38), 13, TEXT, DIM,
		HORIZONTAL_ALIGNMENT_CENTER)
	var attack := keyboard.caption(player, 3)
	var special := keyboard.caption(player, 4)
	var commands := [attack + "  /  X", "Beim Laufen  " + attack + "  /  X",
		keyboard.caption(player, 6) + " + " + attack + "  /  ↓ + X",
		"In der Luft  " + attack + "  /  X", special + "  /  Y",
		"Nach Treffer  " + special + "  /  Y"]
	for row in ArenaMoves.KEYS.size():
		var move := ArenaMoves.KEYS[row]
		var y := 148 + row * 78
		style_panel(Rect2(361, y, 858, 70), PANEL, EDGE)
		if move == profile["focus"] or move == "finisher":
			ribbon(Rect2(361, y, 3, 70), accent)
		label(ArenaMoves.move_name(profile, move), Rect2(380, y + 3, 489, 34), 19, BOLD)
		label(commands[row], Rect2(868, y + 3, 331, 34), 16, BOLD, accent, HORIZONTAL_ALIGNMENT_RIGHT)
		var help := String(profile["description"] if move == "signature" else ArenaMoves.PURPOSE[move])
		label(help, Rect2(380, y + 37, 818, 27), 15, TEXT, DIM)
	label("Wechsle zwischen Angriffen. Wiederholte Treffer mit demselben Move werden schwächer.",
		Rect2(361, 625, 858, 32), 16, TEXT, DIM)


func choose_fighter(id: int) -> void:
	match picking:
		0: selected.x = id
		1: selected.y = id
		2: extra_picks.x = id
		3: extra_picks.y = id
	show_selection(selection_mode)


func pick_player(index: int) -> void:
	picking = index
	show_selection(selection_mode)


func toggle_versus() -> void:
	var was_four := versus_four
	versus_four = not versus_bot and not was_four
	versus_bot = was_four
	if not versus_four:
		picking = mini(picking, 1)
	show_selection(selection_mode)


func arena_name(index: int) -> String:
	return "Zufällige Arena" if index < 0 else String(catalog.arenas[index]["name"])


func show_arena_picker(source: String = "versus") -> void:
	arena_picker_source = source
	var detail := "Versus"
	var chosen := stage_pick
	if source == "network":
		remember_lobby_fields()
		detail = "Host wählt den Austragungsort"
		chosen = host_stage_pick
	elif source == "survival":
		detail = "Überleben"
		chosen = survival_stage_pick
	set_menu("arenas")
	var back := header("Arena wählen", detail, leave_arena_picker)
	var choices := range(1, catalog.arenas.size())
	if source != "network":
		choices.append(-1)
	var chosen_card: Button
	for i in choices.size():
		var index: int = choices[i]
		var x := 59 + (i % 4) * 294
		var y := 145 + (i / 4) * 252
		var card := button("", Rect2(x, y, 278, 232), choose_arena.bind(index), index == chosen)
		card.accessibility_name = arena_name(index)
		var ink := DARK if index == chosen else PAPER
		if index < 0:
			label("?", Rect2(9, 9, 260, 136), 85, DISPLAY, ink, HORIZONTAL_ALIGNMENT_CENTER, card)
		else:
			add_texture(catalog.backdrops[index], Rect2(9, 9, 260, 146), card)
		label(arena_name(index), Rect2(13, 160, 220, 30), 19, BOLD, ink,
			HORIZONTAL_ALIGNMENT_LEFT, card)
		if index == chosen:
			label("Gewählt", Rect2(194, 163, 71, 25), 12, BOLD, DARK, HORIZONTAL_ALIGNMENT_RIGHT, card)
			chosen_card = card
		var hint := "Lost eine von sieben Kampfarenen." if index < 0 else String(catalog.arenas[index]["description"])
		label(hint, Rect2(13, 189, 251, 35), 14, TEXT, ink, HORIZONTAL_ALIGNMENT_LEFT, card)
	if is_instance_valid(chosen_card):
		chosen_card.grab_focus()
	else:
		back.grab_focus()


func choose_arena(index: int) -> void:
	match arena_picker_source:
		"network":
			host_stage_pick = index
			link.choose_arena(index)
		"survival":
			survival_stage_pick = index
		_:
			stage_pick = index
	leave_arena_picker()


func leave_arena_picker() -> void:
	if arena_picker_source == "network":
		show_lobby()
	else:
		var index := stage_pick if arena_picker_source == "versus" else survival_stage_pick
		show_selection(arena_picker_source, arena_name(index) + "  ›")


func begin_campaign() -> void:
	chapter = 0
	begin_bout(0, selected.x, 0, "training")


func next_chapter() -> void:
	chapter += 1
	var arena := catalog.arena_index(CAMPAIGN_ARENAS[chapter - 1])
	var opponent: int = CAMPAIGN_OPPONENTS[chapter - 1]
	set_menu("chapter")
	header(arena_name(arena), "Kampagne · Duell %d / %d" % [chapter, CAMPAIGN_ARENAS.size()], show_home)
	add_texture(catalog.backdrops[arena], Rect2(60, 145, 726, 408), ui)
	style_panel(Rect2(813, 145, 407, 408), PANEL, EDGE)
	label("NÄCHSTES DUELL", Rect2(840, 161, 350, 30), 15, BOLD, MINT)
	portrait(selected.x, Rect2(838, 198, 152, 171), ui)
	portrait(opponent, Rect2(1038, 198, 152, 171), ui)
	label(fighter_name(selected.x), Rect2(840, 375, 148, 29), 17, BOLD, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label(fighter_name(opponent), Rect2(1014, 375, 179, 29), 17, BOLD, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label(CAMPAIGN_GOALS[chapter - 1], Rect2(838, 423, 355, 97), 17, TEXT, DIM,
		HORIZONTAL_ALIGNMENT_LEFT, null, true)
	button("Duell starten", Rect2(813, 575, 407, 58), play_chapter.bind(arena, opponent), true).grab_focus()


func play_chapter(arena: int, opponent: int) -> void:
	var finale := chapter == CAMPAIGN_ARENAS.size()
	begin_bout(arena, selected.x, opponent, "boss" if finale else "solo", mini(chapter - 1, 2))


func begin_tournament() -> void:
	var arena_indices := range(1, catalog.arenas.size())
	if tournament_fixed_route:
		arena_indices.clear()
		for id: String in FIXED_TOURNAMENT_ROUTE:
			arena_indices.append(catalog.arena_index(id))
	else:
		arena_indices.shuffle()
	var opponents := range(ArenaCatalog.STUDENTS)
	opponents.erase(selected.x)
	opponents.shuffle()
	tournament_matchups.clear()
	for round_index in TOURNAMENT_ROUNDS:
		tournament_matchups.append(Vector2i(arena_indices[round_index], opponents[round_index]))
	tournament_retries = 0
	tournament_round = 0
	show_tournament_board()


func show_tournament_board() -> void:
	set_menu("tournament_board")
	header("Turnier", "%s · %s" % [TOURNAMENT_LEVELS[tournament_level], fighter_name(selected.x)], show_home)
	for n in TOURNAMENT_ROUNDS:
		var matchup := tournament_matchups[n]
		var x := 59 + n * 294
		var active := n == tournament_round
		var passed := n < tournament_round
		style_panel(Rect2(x, 155, 278, 393), PANEL, MINT if active else EDGE)
		ribbon(Rect2(x, 155, 278, 3), MINT if active or passed else EDGE)
		add_texture(catalog.backdrops[matchup.x], Rect2(x + 10, 208, 258, 145), ui)
		portrait(matchup.y, Rect2(x + 12, 362, 87, 104), ui)
		label("RUNDE %d" % (n + 1), Rect2(x + 13, 167, 117, 35), 22, DISPLAY)
		var state := "GEWONNEN" if passed else "ALS NÄCHSTES" if active else "KOMMT NOCH"
		label(state, Rect2(x + 135, 170, 130, 31), 12, BOLD, MINT if active or passed else DIM,
			HORIZONTAL_ALIGNMENT_RIGHT)
		label(fighter_name(matchup.y), Rect2(x + 108, 365, 155, 40), 18, BOLD)
		label(arena_name(matchup.x), Rect2(x + 108, 410, 155, 32), 16, TEXT, DIM)
		label("CPU · " + CPU_LEVELS[tournament_bot_level(n)], Rect2(x + 13, 483, 246, 39), 15, TEXT, DIM)
	button("Duell starten", Rect2(860, 577, 359, 58), play_tournament_round, true).grab_focus()


func tournament_bot_level(round_index: int) -> int:
	return TOURNAMENT_BOTS[tournament_level][round_index]


func play_tournament_round() -> void:
	var matchup := tournament_matchups[tournament_round]
	begin_bout(matchup.x, selected.x, matchup.y, "tournament", tournament_bot_level(tournament_round))


func next_tournament_round() -> void:
	tournament_round += 1
	show_tournament_board()


func begin_survival() -> void:
	chapter = 0
	survival_arena = randi_range(1, catalog.arenas.size() - 1) if survival_stage_pick < 0 else survival_stage_pick
	var opponents := range(ArenaCatalog.STUDENTS)
	opponents.erase(selected.x)
	opponents.shuffle()
	survival_opponents.assign(opponents.slice(0, SURVIVAL_DIFFICULTIES.size()))
	survival_wave = 0
	play_survival_wave(ArenaBout.DEFAULT_STOCKS, 0.0)


func play_survival_wave(stocks: int, balance: float) -> void:
	begin_bout(survival_arena, selected.x, survival_opponents[survival_wave], "survival",
		SURVIVAL_DIFFICULTIES[survival_wave], ArenaBout.DEFAULT_STOCKS, 0.0)
	bout.fighters[0].stocks = stocks
	bout.fighters[0].balance = balance
	bout.fighters[1].stocks = 1


func next_survival_wave() -> void:
	survival_wave += 1
	play_survival_wave(bout.fighters[0].stocks, bout.fighters[0].balance)


func begin_boss_practice() -> void:
	chapter = 0
	begin_bout(catalog.arena_index("bibliothek"), selected.x, ArenaCatalog.BOSS, "boss")


func show_versus_rules() -> void:
	set_menu("rules")
	header("Versus-Regeln", "Lokales Duell", show_selection.bind("versus", "Regeln"))
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
		else "Im lokalen Duell steuern alle Personen selbst.",
		Rect2(91, 392, 1074, 41), 17, TEXT, DIM)
	label("Bei Zeitablauf entscheiden übrige Versuche, dann der niedrigere Rückstoßwert.",
		Rect2(91, 464, 1074, 40), 17, TEXT, DIM)
	button("Übernehmen", Rect2(872, 580, 348, 56), show_selection.bind("versus", "Regeln"), true)
	stocks.grab_focus()


func start_versus() -> void:
	chapter = 0
	var arena := randi_range(1, catalog.arenas.size() - 1) if stage_pick < 0 else stage_pick
	var extras := PackedInt32Array([extra_picks.x, extra_picks.y]) if versus_four else PackedInt32Array()
	begin_bout(arena, selected.x, selected.y, "solo" if versus_bot else "local",
		versus_difficulty, versus_stocks, versus_time, extras, versus_team_partner)


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
	header("Netzwerkduell", fighter_name(selected.x), go_back)
	style_panel(Rect2(59, 148, 564, 350), PANEL, EDGE)
	style_panel(Rect2(646, 148, 575, 350), PANEL, EDGE)
	label("SPIEL HOSTEN", Rect2(83, 169, 430, 57), 40, DISPLAY)
	label("SPIEL BEITRETEN", Rect2(670, 169, 451, 57), 40, DISPLAY)
	label("Gib deiner Gruppe die Adresse und den UDP-Port.",
		Rect2(85, 234, 504, 54), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	label("Nutze die Adresse der hostenden Person. Im Internet muss der Host erreichbar sein.",
		Rect2(670, 230, 501, 65), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	region = label("", Rect2(85, 279, 506, 39), 15, BOLD, MINT, HORIZONTAL_ALIGNMENT_LEFT, null, true)
	host_size_picker = option_picker("Gruppengröße", ["2 Personen", "3 Personen", "4 Personen"],
		Rect2(85, 320, 177, 35), host_size - 2, func(index: int) -> void:
			host_size = index + 2
			refresh_lobby())
	host_format_picker = option_picker("Kampfart", FOUR_PLAYER_FORMATS, Rect2(272, 320, 323, 35),
		host_team_partner, func(index: int) -> void:
			host_team_partner = index
			link.choose_team_partner(index))
	var arena_button := button(arena_name(host_stage_pick) + "  ›", Rect2(85, 365, 510, 49),
		show_arena_picker.bind("network"))
	arena_button.name = "ArenaChoice"
	host_button = button("Host starten", Rect2(85, 429, 510, 48), host_game, true)
	label("HOST-ADRESSE", Rect2(670, 300, 518, 28), 13, BOLD, DIM)
	address_box = field(Rect2(670, 331, 520, 45), last_address, "z. B. 192.168.1.42")
	address_box.text_submitted.connect(func(_value: String) -> void: join_game())
	label("UDP-PORT FÜR ALLE", Rect2(670, 383, 306, 31), 13, BOLD, DIM)
	port_box = field(Rect2(1028, 380, 162, 42), last_port, "24738")
	join_button = button("Verbinden", Rect2(670, 429, 520, 48), join_game, true)
	style_panel(Rect2(59, 518, 1162, 142), PANEL, EDGE)
	lobby_status = label("", Rect2(84, 527, 1104, 42), 18, BOLD, PAPER)
	lobby_matchup = label("", Rect2(235, 574, 675, 68), 16, BOLD, MINT,
		HORIZONTAL_ALIGNMENT_LEFT, null, true)
	end_connection_button = button("Trennen", Rect2(83, 597, 140, 44), disconnect_lobby)
	ready_button = button("Runde starten", Rect2(944, 587, 246, 53), start_network, true)
	refresh_lobby()
	arena_button.grab_focus()


func remember_lobby_fields() -> void:
	last_address = address_box.text.strip_edges()
	last_port = port_box.text.strip_edges()


func get_lobby_port() -> int:
	remember_lobby_fields()
	if not last_port.is_valid_int() or last_port.to_int() < 1 or last_port.to_int() > 65535:
		lobby_status.text = "Gib einen gültigen UDP-Port zwischen 1 und 65535 ein."
		return -1
	return last_port.to_int()


func host_game() -> void:
	var port := get_lobby_port()
	if port > 0:
		link.choose_arena(host_stage_pick)
		link.listen(port, selected.x, host_size, host_team_partner)


func join_game() -> void:
	var port := get_lobby_port()
	if port <= 0:
		return
	if not valid_host_address(last_address):
		lobby_status.text = "Gib eine IP-Adresse oder einen Hostnamen ohne Port ein."
		return
	link.join(last_address, port, selected.x)


func valid_host_address(value: String) -> bool:
	if value.is_valid_ip_address():
		return true
	if value.is_empty() or (value.contains(".") and value.replace(".", "").is_valid_int()):
		return false
	var dns := RegEx.create_from_string("^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*\\.?$")
	return dns.search(value.to_lower()) != null


func disconnect_lobby() -> void:
	link.close()
	refresh_lobby()


func refresh_lobby() -> void:
	if screen == "bout" and is_instance_valid(rematch_button):
		refresh_rematch()
	if screen != "network" or not is_instance_valid(lobby_status):
		return
	var status := link.status if not link.status.is_empty() else "Wähle Hosten oder Beitreten."
	lobby_status.text = "%s  ·  %s" % [link.phase, status]
	region.text = "Deine LAN-Adresse:  %s" % DuelLink.lan_addresses()
	host_button.disabled = link.peer != null
	host_size_picker.disabled = link.peer != null
	var capacity := host_size if link.peer == null else link.capacity
	var partner := host_team_partner if link.peer == null else link.team_partner
	host_size_picker.select(capacity - 2)
	host_format_picker.visible = capacity == 4
	host_format_picker.select(partner)
	host_format_picker.disabled = link.peer != null and not link.hosting
	join_button.disabled = link.peer != null
	end_connection_button.visible = link.peer != null
	ready_button.visible = link.hosting
	ready_button.disabled = not link.can_start()
	var chooser := ui.get_node("ArenaChoice") as Button
	chooser.disabled = link.peer != null and not link.hosting
	var arena := host_stage_pick if not chooser.disabled or link.preview_fighters.is_empty() else link.preview_arena
	chooser.text = arena_name(arena) + ("  ›" if not chooser.disabled else "")
	lobby_matchup.text = ""
	if not link.preview_fighters.is_empty():
		var names := PackedStringArray()
		var blues := PackedStringArray()
		var oranges := PackedStringArray()
		for slot in link.preview_fighters.size():
			var entry := "P%d %s" % [slot + 1, fighter_name(link.preview_fighters[slot])]
			names.append(entry)
			if ArenaBout.side_for(slot, partner) == 0:
				blues.append(entry)
			else:
				oranges.append(entry)
		var roster := "  /  ".join(names)
		if partner > 0:
			roster = "Blau · %s\nOrange · %s" % [" + ".join(blues), " + ".join(oranges)]
		lobby_matchup.text = "%d/%d  ·  %s" % [names.size(), link.capacity, roster]


func refresh_rematch() -> void:
	if link.hosting:
		rematch_button.disabled = not link.can_start()
		rematch_button.text = "Revanche starten" if link.can_start() else "Wartet auf die Gruppe"
	else:
		rematch_button.disabled = link.ready_sent
		rematch_button.text = "Bereit · Host startet" if link.ready_sent else "Für Revanche bereit"


func start_network() -> void:
	link.start_round(host_stage_pick)


func network_bout(arena: int, lineup: PackedInt32Array, partner: int) -> void:
	begin_bout(arena, lineup[0], lineup[1], "network", 1,
		ArenaBout.DEFAULT_STOCKS, ArenaBout.MAX_SECONDS, lineup.slice(2), partner)


func network_lost(_message: String) -> void:
	if screen == "bout" and bout != null and bout.mode == "network":
		show_lobby()


func receive_state(state: Dictionary) -> void:
	if screen == "bout" and bout != null and bout.mode == "network":
		bout.apply_snapshot(state)


func begin_bout(arena: int, one: int, two: int, mode: String, difficulty: int = 1,
		stocks: int = ArenaBout.DEFAULT_STOCKS, seconds: float = ArenaBout.MAX_SECONDS,
		extras := PackedInt32Array(), partner: int = 0) -> void:
	stop_class_voice()
	last_bout_voice_at = 0.0
	prefer_event_voice = true
	bout = ArenaBout.new(catalog, arena, one, two, mode, difficulty, stocks, seconds, extras, partner)
	if mode == "practice":
		bout.practice_behavior = practice_behavior
		bout.practice_damage = practice_damage
		bout.reset_position(1, false)
	view.bout = bout
	view.spotlight_id = -1
	view.voice_status_until = 0.0
	refresh_match_voice_controls()
	view.match_context = ""
	if mode == "survival":
		view.match_context = "ÜBERLEBEN · WELLE %d / %d" % [survival_wave + 1, SURVIVAL_DIFFICULTIES.size()]
	elif mode == "class_duel":
		view.match_context = "KLASSENDUELL · " + fighter_name(two).to_upper()
	elif mode == "tournament":
		view.match_context = "TURNIER · RUNDE %d / %d" % [tournament_round + 1, TOURNAMENT_ROUNDS]
	elif selection_mode == "campaign" and chapter > 0 and mode in ["solo", "boss"]:
		view.match_context = "KAMPAGNE · DUELL %d / %d" % [chapter, CAMPAIGN_ARENAS.size()]
	view.smooth_remote = mode == "network" and not link.hosting
	view.local_slot = link.local_slot if mode == "network" else -1
	if bout.fighters.size() > 2:
		view.match_context = "2 GEGEN 2" if bout.team_partner > 0 else "ALLE GEGEN ALLE · %d" % bout.fighters.size()
	screen = "bout"
	paused = false
	outcome_shown = false
	heard_lesson = false
	for slot in previous_keys.size():
		previous_keys[slot] = poll_controls(slot)
	frame_serial = 0
	make_ui()
	change_music("finale" if mode == "boss" else "arena")
	play_bout_voice(voice_clips.get(VOICE_GREETING), "Servas!")


func show_tutorial_finish() -> void:
	var first_clear := unlock_goal("tutorial")
	style_panel(Rect2(720, 157, 494, 239), Color("#17243a"), EDGE)
	ribbon(Rect2(720, 157, 494, 3), MINT)
	label("TUTORIAL GESCHAFFT", Rect2(743, 177, 449, 51), 38, DISPLAY)
	var practice := selection_mode == "training"
	var finish_text := "Du hast alle fünf Übungen geschafft." if practice else "Die Pausenglocke gibt den Start frei."
	if first_clear:
		finish_text = "Ziel erreicht · Trainingsstart"
	label(finish_text, Rect2(744, 238, 430, 30), 18, TEXT, DIM)
	button("Zum Hauptmenü" if practice else "Zum Pausenhof", Rect2(743, 292, 271, 58),
		show_home if practice else next_chapter, true).grab_focus()
	button("Wiederholen", Rect2(1025, 292, 166, 58), restart_bout)


func show_pause() -> void:
	stop_class_voice()
	view.spotlight_id = -1
	pause_page = ""
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
		button("Neuer Lauf" if bout.mode == "survival" else "Neu starten", Rect2(439, 397, 404, 50),
			begin_survival if bout.mode == "survival" else restart_bout)
	if online:
		button("Einstellungen", Rect2(439, 397, 197, 50), show_settings.bind(true))
		button("Zum Hauptmenü", Rect2(646, 397, 197, 50), show_home)
	else:
		button("Einstellungen", Rect2(408, 456, 146, 50), show_settings.bind(true))
		button("Moves", Rect2(564, 456, 140, 50), show_move_list.bind(bout.fighters[0].id, 0, true))
		button("Zum Hauptmenü", Rect2(714, 456, 158, 50), show_home)


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
	button("Figurenwahl", Rect2(377, 474, 164, 52), show_selection.bind("practice"))
	button("Moves", Rect2(556, 474, 165, 52), show_move_list.bind(bout.fighters[0].id, 0, true))
	button("Einstellungen", Rect2(736, 474, 164, 52), show_settings.bind(true))
	button("Zum Hauptmenü", Rect2(377, 546, 523, 48), show_home)


func resume_bout() -> void:
	pause_page = ""
	paused = false
	for slot in previous_keys.size():
		previous_keys[slot] = poll_controls(slot)
	refresh_match_voice_controls()
	make_ui()


func restart_bout() -> void:
	if bout.mode == "tournament":
		tournament_retries += 1
	var one := bout.fighters[0].id
	var two := bout.fighters[1].id if bout.fighters.size() > 1 else 0
	var extras := PackedInt32Array()
	for slot in range(2, bout.fighters.size()):
		extras.append(bout.fighters[slot].id)
	begin_bout(bout.stage_index, one, two, bout.mode, bout.difficulty, bout.max_stocks, bout.time_limit,
		extras, bout.team_partner)


func show_result() -> void:
	make_ui()
	overlay()
	var title := "UNENTSCHIEDEN"
	var title_color := PAPER
	var subtitle := String(bout.stage["name"])
	var victor := bout.winner
	if victor >= 0 and bout.team_partner > 0:
		title = "TEAM %s GEWINNT" % String(ArenaView.TEAM_NAMES[victor]).to_upper()
		title_color = ArenaView.TEAM_COLORS[victor]
		var teammates := PackedStringArray()
		for slot in bout.fighters.size():
			if ArenaBout.side_for(slot, bout.team_partner) == victor:
				teammates.append("P%d %s" % [slot + 1, fighter_name(bout.fighters[slot].id)])
		subtitle = " + ".join(teammates) + " · " + subtitle
	elif victor >= 0:
		var winner_fighter := bout.fighters[victor]
		title = "%s GEWINNT" % fighter_name(winner_fighter.id).to_upper()
		if bout.fighters.size() > 2:
			title = "P%d · %s" % [victor + 1, title]
	var primary := "Noch eine Runde"
	var next_action := restart_bout
	var enabled := true
	if bout.mode == "network":
		primary = "Revanche"
		next_action = start_network if link.hosting else link.request_rematch
		enabled = link.can_start() if link.hosting else not link.ready_sent
	elif bout.mode == "survival":
		var cleared := survival_wave + (1 if victor == 0 else 0)
		var best := cleared > survival_best
		if best:
			survival_best = cleared
			save_settings()
		if victor == 0 and cleared < SURVIVAL_DIFFICULTIES.size():
			title = "WELLE %d GESCHAFFT" % cleared
			var upcoming := fighter_name(survival_opponents[survival_wave + 1])
			subtitle = "Als Nächstes: %s · %d Versuche · %d%% Rückstoß" % [upcoming,
				bout.fighters[0].stocks, roundi(bout.fighters[0].balance)]
			primary = "Nächste Welle"
			next_action = next_survival_wave
		else:
			title = "ALLE WELLEN GESCHAFFT" if victor == 0 else "LAUF BEENDET"
			subtitle = "%d von %d Wellen · %s %d" % [cleared, SURVIVAL_DIFFICULTIES.size(),
				"Neuer Bestwert:" if best else "Bestwert:", survival_best]
			primary = "Neuer Lauf"
			next_action = begin_survival
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
			subtitle = "%s · %s  |  4 Siege  |  %d Wiederholungen" % [
				fighter_name(bout.fighters[0].id), TOURNAMENT_LEVELS[tournament_level], tournament_retries]
			primary = "Neues Turnier"
			next_action = begin_tournament
	elif selection_mode == "campaign" and chapter > 0:
		primary = "Erneut versuchen"
		if victor == 0 and chapter < CAMPAIGN_ARENAS.size():
			var next_arena_name := arena_name(catalog.arena_index(CAMPAIGN_ARENAS[chapter]))
			primary = "Weiter · " + next_arena_name
			next_action = next_chapter
		elif victor == 0:
			title = "FINALE GESCHAFFT"
			subtitle = "Du hast Herrn Grimmers Regalwelle überstanden."
			primary = "Kampagne erneut spielen"
			next_action = begin_campaign
			completed = true
			save_settings()
	elif selection_mode == "boss_practice":
		title = "BOSSPROBE GESCHAFFT" if victor == 0 else "BOSSPROBE BEENDET"
		primary = "Bossprobe wiederholen"
	elif selection_mode == "versus" and victor >= 0 and (bout.mode == "local" or victor == 0):
		if unlock_goal("duel"):
			subtitle += " · Ziel erreicht: Erstes Duell"
	label(title, Rect2(376, 202, 528, 91), 51 if title.length() < 18 else 40,
		DISPLAY, title_color, HORIZONTAL_ALIGNMENT_CENTER)
	label(subtitle, Rect2(379, 299, 523, 50), 17, TEXT, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	var action := button(primary, Rect2(422, 369, 436, 53), next_action, true)
	action.disabled = not enabled
	if bout.mode == "network":
		rematch_button = action
		refresh_rematch()
	var has_duel_list := bout.mode == "class_duel"
	if has_duel_list:
		button("Weitere Duelle", Rect2(422, 440, 212, 50), show_class_duels)
	var home_width := 212 if has_duel_list else 436
	var home := button("Zum Hauptmenü", Rect2(858 - home_width, 440, home_width, 50), show_home)
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
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.horizontal_alignment = alignment
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.clip_text = true
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.add_theme_font_override("font", font)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	(ui if parent == null else parent).add_child(item)
	item.position = area.position
	item.size = area.size
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
