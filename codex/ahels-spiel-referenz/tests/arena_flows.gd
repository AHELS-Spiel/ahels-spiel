extends SceneTree
## Isolate XDG_DATA_HOME when running tests that advance local goals.

const STEP := 1.0 / 60.0
var app: ArenaApp
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func run() -> void:
	app = ArenaApp.new()
	root.add_child(app)
	app.set_physics_process(false)
	for id: String in ["werkstatt", "dachterrasse", "aula", "physiksaal"]:
		check_arena(id)
	check_practice(9, "bolt")
	check_practice(2, "rise")
	check_practice(4, "burst")
	check_survival()
	check_boss()
	check_levels()
	app.queue_free()
	await process_frame
	print("Arenen, Spezialfähigkeiten, Überleben und Bossprobe geprüft.")
	quit(int(failed))


func check_arena(id: String) -> void:
	var index := app.catalog.arena_index(id)
	check(index >= 0 and app.catalog.backdrops[index] != null, id + " mit Hintergrund geladen")
	var round := ArenaBout.new(app.catalog, index, 9, 12, "local")
	var floor_surface: Rect2 = round.stage["surfaces"][0]
	var ledge: Rect2 = round.stage["surfaces"][1]
	for fighter in round.fighters:
		check(fighter.p.y == floor_surface.position.y and floor_surface.grow(0.1).has_point(fighter.p), id + " mit sicheren Spawns")
	round.starts_in = 0.0
	var hero := round.fighters[0]
	hero.p.x = (maxf(floor_surface.position.x, ledge.position.x) + minf(floor_surface.end.x, ledge.end.x)) * 0.5
	round.tick(STEP, 0, ArenaBout.JUMP, 0, 0)
	for frame in 24:
		round.tick(STEP, 0, 0, 0, 0)
	round.tick(STEP, 0, ArenaBout.JUMP, 0, 0)
	for frame in 55:
		round.tick(STEP, 0, 0, 0, 0)
	check(hero.standing and hero.p.y == ledge.position.y, id + " erreichbare Plattform")
	round.tick(STEP, 0, ArenaBout.DOWN, 0, 0)
	for frame in 70:
		round.tick(STEP, 0, 0, 0, 0)
	check(hero.standing and hero.p.y == floor_surface.position.y, id + " Plattform durchlassen")
	for frame in 245:
		round.tick(STEP, ArenaBout.LEFT, 0, 0, 0)
		if hero.stocks == 2:
			break
	check(hero.stocks == 2 and hero.p.x == float(round.stage["spawns"][0]), id + " Ring-out und Wiedereinstieg")


func check_practice(id: int, kind: String) -> void:
	var round := ArenaBout.new(app.catalog, 0, id, 0, "practice")
	var hero := round.fighters[0]
	var rival := round.fighters[1]
	rival.p.x = hero.p.x + (245 if kind == "bolt" else 66)
	round.tick(STEP, 0, ArenaBout.SPECIAL, 0, 0)
	check(hero.cooldown > 0.0 and hero.attack_kind == kind, kind + " aus Steuerungsaktion gestartet")
	if kind == "rise":
		check(hero.v.y < -500.0, "Sprungfeder hebt Figur an")
	else:
		for frame in 42:
			round.tick(STEP, 0, 0, 0, 0)
		check(rival.balance > 0.0, kind + " trifft Gegner")


func check_survival() -> void:
	app.show_selection("survival")
	press("Überleben starten")
	check(app.bout.mode == "survival" and app.bout.fighters[1].stocks == 1, "Überleben startet mit fünf Wellen")
	app.bout.fighters[0].stocks = 2
	app.bout.fighters[0].balance = 75
	var seen := []
	for wave in 5:
		seen.append(app.bout.fighters[1].id)
		app.bout.starts_in = 0.0
		app.bout.fighters[1].p.y = 820
		app._physics_process(STEP)
		if wave < 4:
			press("Nächste Welle")
			check(app.bout.fighters[0].stocks == 2 and app.bout.fighters[0].balance == 75.0, "Zustand geht in nächste Welle")
		check(app.survival_best == wave + 1, "Bestwert zählt gewonnene Wellen")
	check(app.bout.winner == 0 and seen == app.survival_opponents, "Fünf Gegner besiegt")
	press("Neuer Lauf")
	check(app.bout.fighters[0].stocks == 3 and app.bout.fighters[0].balance == 0, "Frischer Lauf")
	app.bout.starts_in = 0.0
	app.bout.fighters[0].stocks = 1
	app.bout.fighters[0].p.y = 820
	app._physics_process(STEP)
	check(app.bout.winner == 1 and app.survival_best == 5, "Niederlage lässt Bestwert bestehen")
	press("Zum Hauptmenü")


func check_boss() -> void:
	app.completed = true
	app.show_home()
	press("Bossprobe")
	press("Bossprobe starten")
	var round := app.bout
	round.starts_in = 0.0
	round.boss_clock = 0.0
	round.tick(STEP, 0, 0, 0, 0)
	check(round.boss_warning > 0.0 and not round.boss_chalk, "Phase 1 kündigt Regalwelle an")
	while round.boss_warning > 0.0:
		round.tick(STEP, 0, 0, 0, 0)
	check(round.shots.size() == 2 and round.shots[0].low and round.boss_recovery > 0, "Regalwelle und Öffnung")
	round = ArenaBout.new(app.catalog, app.catalog.arena_index("bibliothek"), 9, ArenaCatalog.BOSS, "boss")
	round.starts_in = 0.0
	round.boss_clock = 0.0
	round.fighters[1].balance = 60.0
	round.tick(STEP, 0, 0, 0, 0)
	check(round.boss_warning > 0.0 and round.boss_chalk, "Phase 2 kündigt Kreidebogen an")
	while round.boss_warning > 0.0:
		round.tick(STEP, 0, 0, 0, 0)
	check(round.shots.size() == 2 and not round.shots[0].low and round.shots[0].v.y > 0.0, "Kreidebogen folgt der Warnlinie")
	app.bout.fighters[0].stocks = 1
	app.bout.fighters[0].p.y = 900
	app._physics_process(STEP)
	press("Bossprobe wiederholen")
	check(app.bout.fighters[0].stocks == 3 and app.bout.boss_warning == 0 and app.bout.shots.is_empty(), "Bossprobe startet sauber neu")


func check_levels() -> void:
	app.show_home()
	press("Turnier")
	app.tournament_fixed_route = true
	for level in ArenaApp.TOURNAMENT_LEVELS.size():
		app.tournament_level = level
		app.begin_tournament()
		press("Duell starten")
		check(app.bout.stage["id"] == "pausenhof" and app.bout.difficulty == ArenaApp.TOURNAMENT_BOTS[level][0],
			"Route und Schwierigkeit der laufenden Runde")
		check(app.catalog.arenas[app.tournament_matchups[-1].x]["id"] == "dachterrasse", "Festes Finale")


func press(caption: String) -> void:
	for item in app.ui.get_children():
		if item is Button and item.text == caption and not item.disabled:
			item.pressed.emit()
			return
	check(false, "Schaltfläche fehlt: " + caption)
