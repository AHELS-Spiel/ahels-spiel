extends SceneTree
## With a disposable XDG_DATA_HOME: godot --headless --script res://tests/core_flows.gd

var app: ArenaApp
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func press(caption: String) -> void:
	for item in app.ui.get_children():
		if item is Button and item.text == caption and not item.disabled:
			item.pressed.emit()
			return
	check(false, "Schaltfläche fehlt: " + caption)


func choose(caption: String, index: int) -> void:
	for item in app.ui.get_children():
		if item is OptionButton and item.tooltip_text == caption and not item.disabled:
			item.select(index)
			item.item_selected.emit(index)
			return
	check(false, "Option fehlt: " + caption)


func add_app() -> void:
	app = ArenaApp.new()
	root.add_child(app)
	app.set_physics_process(false)


func run() -> void:
	if FileAccess.file_exists(ArenaApp.SAVE_FILE):
		push_error("Der Test benötigt ein frisches Profil.")
		quit(1)
		return
	add_app()
	check(not app.muted and app.music_level == ArenaApp.MUSIC_DEFAULT, "Standardwerte beim frischen Start")
	app.free()

	var legacy := ConfigFile.new()
	legacy.set_value("audio", "muted", true)
	legacy.set_value("campaign", "finished", true)
	legacy.set_value("tournament", "wins", 7)
	legacy.set_value("unrelated", "keep", 42)
	check(legacy.save(ArenaApp.SAVE_FILE) == OK, "Altes Profil gespeichert")
	add_app()
	check(app.muted and app.completed and app.tournament_wins == 7, "V3-Profil geladen")
	press("Einstellungen")
	var sliders: Array[HSlider] = []
	for item in app.ui.get_children():
		if item is HSlider:
			sliders.append(item)
	if sliders.size() == 2:
		sliders[0].value = 36
		sliders[1].value = 82
	else:
		check(false, "Beide Lautstärkeregler vorhanden")
	press("Ton einschalten")
	press("Ton stummschalten")
	press("Ton einschalten")
	press("Reduzierte Effekte: Aus")
	press("Fenster (F11)")
	check(app.fullscreen and app.view.reduced_effects, "Anzeigeoptionen sofort angewendet")
	app.free()
	add_app()
	check(app.music_level == 36 and app.effects_level == 82 and not app.muted, "Audio beim Neustart geladen")
	check(app.fullscreen and app.reduced_effects and app.completed and app.tournament_wins == 7, "Anzeige und Fortschritt geladen")
	check(legacy.load(ArenaApp.SAVE_FILE) == OK and legacy.get_value("unrelated", "keep") == 42, "Andere Daten erhalten")
	press("Einstellungen")
	press("Steuerungsübersicht")
	press("Tastenbelegung ändern")
	press("F")
	app.capture_binding(KEY_J)
	check(app.keyboard.caption(0, 3) == "F" and "Spieler 2" in app.binding_message.text, "Konflikt abgefangen")
	app.capture_binding(KEY_ESCAPE)
	check(app.key_capture.x == -1, "Tasteneingabe abgebrochen")
	press("F")
	app.capture_binding(KEY_H)
	check(app.keyboard.caption(0, 3) == "H" and "H." in app.view.keyboard_lesson(2), "Tafel zeigt Änderung")
	app.free()
	add_app()
	check(app.keyboard.caption(0, 3) == "H", "Tastenbelegung erneut geladen")
	press("Einstellungen")
	press("Steuerungsübersicht")
	press("Tastenbelegung ändern")
	press("Standard wiederherstellen")
	check(app.keyboard.caption(0, 3) == "F", "Tastaturstandard wiederhergestellt")
	app.go_back()
	app.go_back()
	app.go_back()
	press("Versus")
	check(app.fighter_name(7) == "Felix · 08" and app.fighter_name(15) == "Felix · 16", "Doppelnamen")
	app.choose_fighter(7)
	press("KI-Figur")
	app.choose_fighter(15)
	press("Modus: CPU")
	press("Regeln")
	choose("Versuche", 0)
	choose("Zeitlimit", 0)
	press("Übernehmen")
	press("Runde starten")
	check(app.bout.mode == "local" and app.bout.time_limit == 30.0, "Lokale Regeln angewendet")
	check(app.bout.fighters[0].id == 7 and app.bout.fighters[1].id == 15, "Zwei Figuren gewählt")
	app.bout.starts_in = 0.0
	app.bout.fighters[1].p.y = 800
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == 0, "Ein Ring-out beendet das Match")
	press("Noch eine Runde")
	check(app.bout.fighters[0].stocks == 1 and app.bout.time_limit == 30.0, "Revanche behält Regeln")
	app.bout.starts_in = 0.0
	app.bout.time = 29.99
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == ArenaBout.DRAW, "Zeitablauf bei Gleichstand")
	press("Zum Hauptmenü")
	press("Versus")
	press("Modus: 2 am PC")
	press("P3")
	app.choose_fighter(9)
	press("P4")
	app.choose_fighter(10)
	press("Runde starten")
	check(app.bout.fighters.size() == 4 and app.bout.fighters[2].id == 9 and app.bout.fighters[3].id == 10,
		"Vier Personen wählen ihre Figuren")
	app.bout.starts_in = 0.0
	var move_keys := [KEY_A, KEY_RIGHT, KEY_T, KEY_KP_6]
	for key in move_keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = true
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	app._physics_process(1.0 / 60.0)
	for i in 4:
		check(app.bout.fighters[i].v.x * (-1 if i % 2 == 0 else 1) > 0.0, "Eigene Steuerung für P%d" % (i + 1))
		var release := InputEventKey.new()
		release.physical_keycode = move_keys[i]
		release.keycode = move_keys[i]
		release.pressed = false
		Input.parse_input_event(release)
	app.bout.fighters[0].p.y = 800.0
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == ArenaBout.ONGOING, "Drei übrige Figuren spielen weiter")
	app.bout.fighters[1].p.y = 800.0
	app.bout.fighters[2].p.y = 800.0
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == 3, "Vierter Spieler kann gewinnen")
	press("Noch eine Runde")
	check(app.bout.fighters.size() == 4, "Revanche behält alle Figuren")
	app.bout.fighters[3].p = Vector2(600, 535)
	app.bout.fighters[3].facing = 1
	app.bout.fighters[0].p = Vector2(640, 535)
	app.bout.fighters[2].p = Vector2(648, 535)
	app.bout.resolve_openers_and_finisher(3, "normal")
	check(app.bout.fighters[0].last_attacker == 3 and app.bout.fighters[2].last_attacker == 3,
		"Ein Angriff von P4 kann zwei Gegner treffen")
	app.bout.starts_in = 0.0
	app.bout.time = 29.99
	app.bout.fighters[0].balance = 0.0
	for i in range(1, 4):
		app.bout.fighters[i].balance = 20.0
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == 0, "Zeitablauf findet besten Wert über vier Spieler")
	press("Zum Hauptmenü")
	press("Versus")
	choose("Kampfart", 2)
	press("Runde starten")
	var team_bout := app.bout
	check(team_bout.team_partner == 2 and app.view.match_context == "2 GEGEN 2", "Teamwahl P1 und P3 im lokalen Menü")
	check(team_bout.fighters[0].p.x < team_bout.fighters[2].p.x
		and team_bout.fighters[2].p.x < team_bout.fighters[1].p.x, "Teams starten nebeneinander")
	team_bout.fighters[0].p = Vector2(600, 535)
	team_bout.fighters[2].p = Vector2(626, 535)
	team_bout.fighters[1].p = Vector2(650, 535)
	team_bout.fighters[3].p = Vector2(900, 535)
	team_bout.resolve_openers_and_finisher(0, "normal")
	check(team_bout.fighters[2].balance == 0.0 and team_bout.fighters[1].balance > 0.0, "Nahkampf trifft nur Gegner")
	team_bout.fighters[1].balance = 0.0
	team_bout.fighters[1].invulnerable = 0.0
	team_bout.shots.append(ArenaBout.Shot.new(Vector2(627, 502), Vector2.ZERO, 0, 1.0, 10.0, Color.WHITE))
	team_bout.update_shots(0.0)
	check(team_bout.fighters[2].balance == 0.0 and team_bout.fighters[1].balance > 0.0,
		"Projektil fliegt durch den Partner bis zum Gegner")
	for fighter in team_bout.fighters:
		fighter.balance = 0.0
	check(team_bout.timer_winner() == ArenaBout.DRAW, "Zeitablauf bei Gleichstand beider Teams")
	team_bout.fighters[2].balance = 5.0
	check(team_bout.timer_winner() == 1, "Bei gleichen Versuchen entscheidet der Team-Rückstoß")
	team_bout.fighters[0].stocks = 2
	check(team_bout.timer_winner() == 0, "Die Summe der Team-Versuche hat Vorrang")
	team_bout.fighters[0].stocks = 1
	team_bout.starts_in = 0.0
	for slot in [0, 1]:
		team_bout.fighters[slot].p.y = 800.0
	app._physics_process(1.0 / 60.0)
	check(team_bout.winner == ArenaBout.ONGOING, "Je ein Teammitglied darf weiterspielen")
	team_bout.fighters[3].p.y = 800.0
	app._physics_process(1.0 / 60.0)
	check(team_bout.winner == 0, "P3 sichert den Sieg für Team Blau")
	press("Noch eine Runde")
	check(app.bout.team_partner == 2, "Teamaufteilung bleibt in der Revanche")
	app.show_pause()
	press("Zum Hauptmenü")
	press("Versus")
	press("Modus: 4 am PC")
	press("Regeln")
	choose("Versuche", 4)
	choose("Zeitlimit", 4)
	choose("CPU-Schwierigkeit", 3)
	press("Übernehmen")
	press("Runde starten")
	check(app.bout.time_limit == 240.0 and app.bout.max_stocks == 5 and app.bout.difficulty == 3, "Längste CPU-Regel")
	app.bout.starts_in = 0.0
	app.bout.time = 239.99
	app.bout.fighters[1].balance = 10.0
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == 0, "Zeitablauf mit eindeutigem Sieger")
	press("Zum Hauptmenü")
	press("Versus")
	press("Regeln")
	choose("Zeitlimit", 5)
	press("Übernehmen")
	press("Runde starten")
	app.bout.starts_in = 0.0
	app.bout.time = 500.0
	app._physics_process(1.0 / 60.0)
	check(app.bout.winner == ArenaBout.ONGOING, "Ohne Zeitlimit")
	app.show_pause()
	press("Zum Hauptmenü")

	press("Training")
	app.choose_fighter(9)
	press("Training starten")
	check(app.bout.mode == "practice" and app.bout.starts_in == 0.0, "Training beginnt direkt")
	app.show_pause()
	choose("Gegnerverhalten", 1)
	choose("Start-Rückstoß", 2)
	press("Zurücksetzen")
	check(app.bout.practice_behavior == 1 and app.bout.fighters[1].balance == 100, "Reset übernimmt Optionen")
	app._physics_process(1.0 / 60.0)
	check(app.bout.fighters[1].v.y < 0.0, "Gegner springt")
	var trainee := app.bout.fighters[0]
	trainee.balance = 222
	trainee.p.x = -100
	app._physics_process(1.0 / 60.0)
	check(trainee.stocks == 3 and trainee.balance == 0 and trainee.p.x > 0.0, "Training respawnt links")
	app.bout.fighters[1].p.x = 1420
	app._physics_process(1.0 / 60.0)
	check(app.bout.fighters[1].balance == 100 and app.bout.winner == ArenaBout.ONGOING, "Gegner respawnt rechts")
	app.show_pause()
	press("Einstellungen")
	press("Steuerungsübersicht")
	app.go_back()
	check(app.pause_page == "settings", "Zurück aus Steuerungsübersicht")
	app.go_back()
	press("Zum Hauptmenü")
	press("Solo-Kampagne")
	press("Tutorial starten")
	check(app.bout.mode == "training" and app.bout.fighters.size() == 1, "Geführtes Tutorial getrennt")
	app.next_chapter()
	press("Duell starten")
	check(app.bout.max_stocks == 3 and app.bout.time_limit == 150.0, "Kampagne behält Standardregeln")
	app.show_home()
	press("Versus")
	app.show_arena_picker()
	app.choose_arena(-1)
	press("Runde starten")
	var random_arena := app.bout.stage_index
	check(random_arena > 0 and random_arena < app.catalog.arenas.size(), "Zufall wählt eine Kampfarena")
	app.restart_bout()
	check(app.bout.stage_index == random_arena, "Revanche behält die ausgeloste Arena")
	app.free()
	check(legacy.load(ArenaApp.SAVE_FILE) == OK, "Profil für ungültige Werte geladen")
	legacy.set_value("audio", "music", "falsch")
	legacy.set_value("audio", "effects", 999)
	legacy.set_value("display", "fullscreen", ["falsch"])
	legacy.set_value("controls", "keyboard", [[1234]])
	check(legacy.save(ArenaApp.SAVE_FILE) == OK, "Testprofil mit ungültigen Werten gespeichert")
	add_app()
	check(app.music_level == ArenaApp.MUSIC_DEFAULT and app.effects_level == 100 and not app.fullscreen,
		"Ungültige Einstellungen werden abgefangen")
	check(app.keyboard.caption(0, 3) == "F" and app.completed and app.tournament_wins == 7,
		"Beschädigte Tastaturbelegung hat keinen Einfluss auf Fortschritt")
	app.queue_free()
	await process_frame
	print("Einstellungen, Versus und Training geprüft.")
	quit(int(failed))
