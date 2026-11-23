extends SceneTree

const DT := 1.0 / 60.0
const STEFAN := 4
const VALENTIN := 9
const LUKAS := 10
class VoiceTestApp extends ArenaApp:
	var heard: Array[int] = []
	var played_files: Array[String] = []
	var channel_busy := false

	func load_voice_stream(filename: String) -> AudioStream:
		var stream := AudioStreamWAV.new()
		stream.resource_name = filename
		return stream

	func play_voice(clip: VoiceClip) -> float:
		if clip == null or muted or not voices_enabled:
			return 0.0
		heard.append(clip.fighter_id)
		played_files.append(clip.stream.resource_name)
		return 1.0

	func voice_is_playing() -> bool:
		return channel_busy

var app: VoiceTestApp
var errors := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)


func run() -> void:
	app = VoiceTestApp.new()
	root.add_child(app)
	app.set_physics_process(false)
	check(press("Klassenduelle"), "Klassenduelle aus dem Hauptmenü")
	for pair in [[STEFAN, "Stefan", "aula"], [LUKAS, "Lukas", "werkstatt"], [VALENTIN, "Valentin", "computerraum"]]:
		check(press("Gegen %s spielen" % pair[1]), "Gegnerkarte für " + pair[1])
		check(press("Duell starten"), "Eigenes Duell starten")
		check(app.bout.fighters[1].id == pair[0] and app.bout.stage["id"] == pair[2], "Passende Arena und Figur")
		check(app.bout.max_stocks == 2 and app.bout.time_limit == 90.0, "Duellregeln")
		app.bout.starts_in = 0.0
		app.bout.fighters[1].stocks = 1
		app.bout.fighters[1].p.y = 800
		app._physics_process(DT)
		check(press("Weitere Duelle"), "Vom Ergebnis zur Übersicht")
	check_ring_out()
	check_guard()
	check_projectile()
	check_automatic_voices()
	await check_voice_key()
	print("Klassenduelle, automatische Stimmen in allen Modi, Stimmtasten und Netzwerksynchronisierung geprüft.")
	app.queue_free()
	await process_frame
	quit(0 if errors == 0 else 1)


func press(text: String) -> bool:
	for node in app.ui.get_children():
		if node is Button and node.text == text and not node.disabled:
			node.pressed.emit()
			return true
	return false


func check_ring_out() -> void:
	var bout := ArenaBout.new(app.catalog, 6, STEFAN, LUKAS, "local")
	bout.ring_out(1)
	check(bout.spotlight_queue.is_empty(), "Selbststurz erzeugt keinen Stefan-Einwurf")
	bout.reset_position(1, false)
	bout.hit(1, 9.0, 1, Color.WHITE)
	bout.ring_out(1)
	check(bout.spotlight_queue == [STEFAN], "Stefan wird für seinen Ring-out eingeblendet")
	var guest := ArenaBout.new(app.catalog, 6, STEFAN, LUKAS, "network")
	var current := bout.snapshot()
	guest.apply_snapshot(current)
	guest.apply_snapshot(current)
	var older := current.duplicate(true)
	older["ci"] = 0
	older["cf"] = LUKAS
	guest.apply_snapshot(older)
	guest.apply_snapshot(current)
	check(guest.spotlight_queue == [STEFAN], "Netzwerk übernimmt den neuesten Einwurf genau einmal")
	check(guest.knockout_queue == [LUKAS], "Netzwerk erkennt den Lebensverlust ohne doppelte Wiedergabe")
	bout.reset_position(1, false)
	bout.hit(1, 9.0, 1, Color.WHITE)
	bout.time += 5.0
	bout.ring_out(1)
	check(bout.spotlight_queue == [STEFAN], "Zeitlich entfernter Treffer erzeugt keinen Einwurf")


func check_guard() -> void:
	var bout := ArenaBout.new(app.catalog, 4, STEFAN, LUKAS, "class_duel")
	bout.starts_in = 0.0
	bout.fighters[0].p.x = bout.fighters[1].p.x - 63.0
	bout.bot_clock = 0.23
	bout.tick(DT, 0, ArenaBout.ATTACK, 0, 0)
	for frame in 8:
		bout.tick(DT, 0, 0, 0, 0)
	check(bout.spotlight_queue == [LUKAS], "Lukas nutzt Schutzfeld und wird seinem Block zugeordnet")
	check(bout.fighters[1].balance == 0.0, "Der Block verhindert den gegnerischen Treffer")


func check_projectile() -> void:
	var bout := ArenaBout.new(app.catalog, 2, STEFAN, VALENTIN, "class_duel")
	bout.starts_in = 0.0
	bout.fighters[0].p.x = bout.fighters[1].p.x - 180.0
	for frame in 42:
		bout.tick(DT, 0, 0, 0, 0)
	check(bout.spotlight_queue == [VALENTIN], "Valentin setzt seine Impulslinie aus Abstand ein")
	check(bout.fighters[0].balance > 0.0, "Die Impulslinie hat getroffen")


func check_automatic_voices() -> void:
	for mode in ["training", "practice", "local", "solo", "boss", "tournament", "survival", "class_duel", "network"]:
		app.played_files.clear()
		app.begin_bout(0 if mode in ["training", "practice"] else 1, 0, 1, mode)
		app.play_bout_audio()
		check(app.played_files == [ArenaApp.VOICE_GREETING] and app.view.spotlight_caption == "Servas!",
			"Jede Runde startet mit Servas: " + mode)

	app.selection_mode = "versus"
	app.begin_bout(1, 0, 1, "local")
	app.played_files.clear()
	app.bout.starts_in = 0.0
	app.bout.time = ArenaApp.VOICE_ACTION_GAP - 0.1
	app.bout.sound("combo")
	app.play_bout_audio()
	check(app.played_files.is_empty(), "Trefferwiederholungen überlagern keine Einwürfe")
	app.bout.time = ArenaApp.VOICE_ACTION_GAP
	app.bout.sound("combo")
	app.play_bout_audio()
	check(app.played_files.size() == 1, "Ein Treffer zieht den nächsten Einwurf vor")
	for index in range(1, 6):
		app.bout.time += ArenaApp.VOICE_IDLE_GAP
		app.play_bout_audio()
		check(app.played_files.size() == index + 1, "Einwürfe auch zwischen Aktionen")
	var rotated := app.played_files.duplicate()
	rotated.sort()
	check(rotated == ["lukas-02.ogg", "lukas-06.ogg", "lukas-08.ogg", "valentin-05.ogg", "valentin-07.ogg",
		"valentin-09.ogg"], "Alle sechs Zwischenrufe kommen einmal an die Reihe")

	app.begin_bout(1, LUKAS, 0, "local", 1, 1)
	app.played_files.clear()
	app.channel_busy = true
	app.bout.starts_in = 0.0
	for fighter in app.bout.fighters:
		fighter.p.y = 900.0
	app._physics_process(DT)
	check(app.bout.winner == ArenaBout.DRAW and app.played_files == [ArenaApp.VOICE_LUKAS_KNOCKOUT],
		"Lukas' letzter Sturz unterbricht einen gewöhnlichen Zwischenruf")
	app._physics_process(DT)
	check(app.played_files.size() == 1, "Gleichzeitige Ring-outs überlagern einander nicht")
	app.channel_busy = false
	app._physics_process(DT)
	check(app.played_files == [ArenaApp.VOICE_LUKAS_KNOCKOUT, ArenaApp.VOICE_KNOCKOUT],
		"Stefan reagiert auch nach Erreichen des Ergebnisbildschirms")

	app.begin_bout(0, 0, 1, "training")
	app.played_files.clear()
	app.bout.fighters[0].p.y = 900.0
	app._physics_process(DT)
	check(app.played_files == [ArenaApp.VOICE_KNOCKOUT] and app.bout.fighters[0].stocks == ArenaBout.DEFAULT_STOCKS,
		"Trainingssturz löst eine Stimme aus und kostet keinen Versuch")
	app.begin_bout(3, 0, ArenaCatalog.BOSS, "boss")
	app.played_files.clear()
	app.bout.starts_in = 0.0
	app.bout.fighters[1].balance = 135.0
	app._physics_process(DT)
	check(app.bout.winner == 0 and app.played_files == [ArenaApp.VOICE_KNOCKOUT],
		"Knockout beim Boss funktioniert auch ohne Sturz")

	app.voices_enabled = false
	app.played_files.clear()
	app.begin_bout(1, 0, LUKAS, "local")
	app.bout.ring_out(1)
	app.play_bout_audio()
	app.voices_enabled = true
	app.play_bout_audio()
	check(app.played_files.is_empty(), "Ausgeschaltete Stimmen lassen keine alten Knockouts in der Warteschlange")


func check_voice_key() -> void:
	app.begin_bout(4, 0, LUKAS, "class_duel")
	app.heard.clear()

	check(app.match_voice_keys[0] == KEY_F3 and app.match_voice_ids == [LUKAS], "F3 findet die Stimme des Gegners")
	await key_press(KEY_F3)
	check(app.heard == [LUKAS] and app.view.spotlight_caption == "Stimme 1/4", "F3 löst Lukas' Stimme aus")
	await key_press(KEY_F3, true)
	check(app.heard == [LUKAS], "Tastenwiederholung startet keine Stimme")

	app.begin_bout(6, STEFAN, VALENTIN, "local")
	app.heard.clear()
	await key_press(KEY_F3)
	await key_press(KEY_F4)
	check(app.heard == [STEFAN, VALENTIN], "Zwei Stimmen auf F3 und F4")

	app.voices_enabled = false
	await key_press(KEY_F3)
	check(app.heard.size() == 2 and app.view.voice_status == "Klassenstimmen sind aus.", "Deaktivierte Stimmen")
	app.voices_enabled = true
	app.muted = true
	await key_press(KEY_F3)
	check(app.heard.size() == 2 and app.view.voice_status == "Ton ist stumm.", "Stummschaltung")
	app.muted = false

	app.show_pause()
	await key_press(KEY_F3)
	check(app.heard.size() == 2, "Tasten sind in der Pause inaktiv")
	var layout := ArenaKeys.DEFAULTS.duplicate(true)
	layout[0][3] = [KEY_F3]
	app.keyboard.load_layouts(layout)
	app.resume_bout()
	check(app.keyboard.layouts[0][3] == [KEY_F3] and app.match_voice_keys == [KEY_F4, KEY_F5],
		"Vorhandene Angriffsbelegung bleibt erhalten")
	await key_press(KEY_F3)
	await key_press(KEY_F4)
	check(app.heard == [STEFAN, VALENTIN, STEFAN], "Nur die neue Stimmtaste löst aus")
	app.keyboard.restore_defaults()

	app.begin_bout(6, STEFAN, VALENTIN, "network")
	check(app.match_voice_ids == [VALENTIN, STEFAN], "Gast hört zuerst seine eigene Figur")
	app.heard.clear()
	app.bout.winner = 0
	await key_press(KEY_F3)
	check(app.heard.is_empty(), "Rundenende deaktiviert die Stimmtaste")


func key_press(key: int, echo: bool = false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = pressed
		event.echo = echo
		Input.parse_input_event(event)
		await process_frame
