extends SceneTree

const DT := 1.0 / 60.0
const STEFAN := 4
const VALENTIN := 9
const LUKAS := 10
var app: ArenaApp
var errors := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)


func run() -> void:
	app = ArenaApp.new()
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
	print("Klassenduelle, Zuordnung und Netzwerksynchronisierung geprüft.")
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
	guest.apply_snapshot(bout.snapshot())
	guest.apply_snapshot(bout.snapshot())
	check(guest.spotlight_queue == [STEFAN], "Netzwerk übernimmt den Einwurf genau einmal")
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
