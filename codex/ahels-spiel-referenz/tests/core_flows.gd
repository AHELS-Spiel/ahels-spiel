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
	check(app.settings_from_pause and not app.controls_from_pause, "Zurück aus Steuerungsübersicht")
	app.go_back()
	press("Zum Hauptmenü")
	press("Solo-Kampagne")
	press("Tutorial starten")
	check(app.bout.mode == "training" and app.bout.fighters.size() == 1, "Geführtes Tutorial getrennt")
	app.next_chapter()
	press("Duell starten")
	check(app.bout.max_stocks == 3 and app.bout.time_limit == 150.0, "Kampagne behält Standardregeln")
	app.queue_free()
	await process_frame
	print("Einstellungen, Versus und Training geprüft.")
	quit(int(failed))
