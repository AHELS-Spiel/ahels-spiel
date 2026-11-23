extends SceneTree
## Run separate processes: -- host|guest|host4|guest4-1|guest4-2|guest4-3|no_host|old_host [udp_port]

var app: ArenaApp
var role: String
var port := 24957
var deadline: int


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0]
	if args.size() > 1:
		port = int(args[1])
	call_deferred("run")


func run() -> void:
	app = preload("res://Main.tscn").instantiate()
	root.add_child(app)
	app.show_lobby()
	deadline = Time.get_ticks_msec() + 18000
	var passed := false
	if role == "host":
		passed = await play_host()
	elif role == "guest":
		passed = await play_guest()
	elif role == "host4":
		passed = await play_group_host()
	elif role.begins_with("guest4-"):
		passed = await play_group_guest(int(role.get_slice("-", 1)))
	else:
		passed = await check_join_error()
	app.link.close()
	app.queue_free()
	await process_frame
	quit(0 if passed else 1)


func press(caption: String) -> void:
	for item in app.ui.get_children():
		if item is Button and not item.disabled and (item.text == caption or item.accessibility_name == caption):
			item.pressed.emit()
			return
	push_error("Schaltfläche fehlt: " + caption)


func wait_until(condition: Callable) -> bool:
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return condition.call()


func play_host() -> bool:
	app.selected.x = 2
	app.port_box.text = str(port)
	press("Pausenhof  ›")
	press("Physiksaal")
	press("Host starten")
	if not await wait_until(app.link.can_start):
		push_error("Host wartet auf den Gast.")
		return false
	press("Runde starten")
	if not await wait_until(func() -> bool:
		return app.bout != null and app.bout.fighters[1].attack_kind == "sweep"
	):
		push_error("Beinfeger des Gasts hat den Host nicht erreicht.")
		return false
	print("OK Host: Beinfeger des Gasts übertragen")
	if not await wait_until(func() -> bool:
		return app.bout != null and app.bout.fighters[1].p.x < 805.0 and app.bout.fighters[1].cooldown > 0.0
	):
		push_error("Keine Bewegung und Spezialaktion des Gasts im Host-Match.")
		return false
	print("OK Host: Bewegung und Spezialaktion des Gasts auf Physiksaal")
	app.bout.fighters[1].stocks = 1
	app.bout.fighters[1].p.y = 900
	if not await wait_until(func() -> bool: return app.outcome_shown and app.link.can_start()):
		push_error("Revanche wurde nicht angefordert.")
		return false
	press("Revanche starten")
	if app.link.round_id != 2 or app.bout.fighters[1].stocks != 3 or app.bout.time > 0.0:
		push_error("Revanche hat einen alten Zustand geladen.")
		return false
	await create_timer(1.0).timeout
	print("OK Host: Revanche mit neuem Rundenzustand")
	return true


func play_guest() -> bool:
	app.selected.x = 16
	app.address_box.text = "127.0.0.1"
	app.port_box.text = str(port)
	press("Verbinden")
	if not await wait_until(func() -> bool: return app.bout != null and app.bout.starts_in == 0):
		push_error("Rundenstart des Hosts fehlt.")
		return false
	if app.bout.stage["id"] != "physiksaal" or app.bout.fighters[0].id != 2 or app.bout.fighters[1].id != 16:
		push_error("Arena oder Figuren stimmen nicht.")
		return false
	app.set_physics_process(false)
	while app.bout.fighters[1].p.x >= 805.0 and Time.get_ticks_msec() < deadline:
		app.link.send_controls(ArenaBout.LEFT, 0)
		await physics_frame
	app.link.send_controls(ArenaBout.DOWN, ArenaBout.DOWN | ArenaBout.ATTACK)
	if not await wait_until(func() -> bool: return app.bout.fighters[1].attack_kind == "sweep"):
		push_error("Gast erhielt keine Beinfeger-Animation.")
		return false
	await create_timer(0.36).timeout
	app.link.send_controls(0, ArenaBout.SPECIAL)
	app.set_physics_process(true)
	if not await wait_until(func() -> bool: return app.outcome_shown):
		push_error("Gast erhielt das Ergebnis nicht.")
		return false
	press("Für Revanche bereit")
	if not await wait_until(func() -> bool: return app.link.round_id == 2):
		push_error("Gast erhielt keine Revanche.")
		return false
	if not await wait_until(func() -> bool: return app.screen == "network"):
		push_error("Gast kehrte nach Trennung nicht in die Lobby zurück.")
		return false
	print("OK Gast: Arena, Ergebnis, Revanche und Rückkehr in die Lobby")
	return true


func check_join_error() -> bool:
	app.address_box.text = "127.0.0.1"
	app.port_box.text = str(port)
	press("Verbinden")
	if not await wait_until(func() -> bool: return app.link.peer == null):
		push_error("Fehlerhafte Verbindung bleibt bestehen.")
		return false
	var expected := "Andere Spielversion" if role == "old_host" else "Kein Host erreichbar"
	if expected not in app.lobby_status.text:
		push_error(app.lobby_status.text)
		return false
	print("OK Lobby: ", expected)
	return true


func play_group_host() -> bool:
	app.host_size_picker.select(2)
	app.host_size_picker.item_selected.emit(2)
	app.port_box.text = str(port)
	press("Host starten")
	if not await wait_until(app.link.can_start) or app.link.preview_fighters.size() != 4:
		push_error("Vier Personen wurden nicht startbereit.")
		return false
	press("Runde starten")
	if not await wait_until(func() -> bool:
		for slot in range(1, 4):
			if app.bout.fighters[slot].attack_kind.is_empty() or absf(app.bout.fighters[slot].v.x) < 30.0:
				return false
		return true
	):
		push_error("Unabhängige Eingaben der drei Gäste fehlen.")
		return false
	for slot in range(3):
		app.bout.fighters[slot].stocks = 1
		app.bout.fighters[slot].p.y = 900.0
	if not await wait_until(func() -> bool: return app.outcome_shown and app.link.can_start()):
		push_error("Ergebnis oder Bereitschaft der drei Gäste fehlt.")
		return false
	if app.bout.winner != 3:
		push_error("P4 muss nach den drei Ring-outs gewinnen.")
		return false
	press("Revanche starten")
	if app.link.round_id != 2 or app.bout.fighters.size() != 4:
		push_error("Revanche mit vier Personen fehlt.")
		return false
	if not await wait_until(func() -> bool: return app.screen == "network" and app.link.seats.size() == 2):
		push_error("Abbruch eines Gasts führt nicht zurück in die Lobby.")
		return false
	if app.link.can_start():
		push_error("Die Lobby muss auf einen Ersatz warten.")
		return false
	await create_timer(0.7).timeout
	print("OK Host: drei Gäste, getrennte Eingaben, P4 gewinnt, Revanche und Rückkehr")
	return true


func play_group_guest(guest_number: int) -> bool:
	app.selected.x = 7 + guest_number
	app.address_box.text = "127.0.0.1"
	app.port_box.text = str(port)
	press("Verbinden")
	if not await wait_until(func() -> bool: return app.bout != null and app.bout.starts_in == 0.0):
		push_error("Start für den Gast fehlt.")
		return false
	var slot := app.link.local_slot
	if app.bout.fighters.size() != 4 or app.bout.fighters[slot].id != app.selected.x or app.view.local_slot != slot:
		push_error("Gast bekommt den falschen Platz.")
		return false
	app.set_physics_process(false)
	var direction := ArenaBout.LEFT if slot % 2 == 1 else ArenaBout.RIGHT
	app.link.send_controls(direction, ArenaBout.ATTACK)
	while app.bout.winner == ArenaBout.ONGOING and Time.get_ticks_msec() < deadline:
		app.link.send_controls(direction, 0)
		await physics_frame
	app.set_physics_process(true)
	if not await wait_until(func() -> bool: return app.outcome_shown and app.bout.winner == 3):
		push_error("Gast sieht das falsche Ergebnis.")
		return false
	press("Für Revanche bereit")
	if not await wait_until(func() -> bool: return app.link.round_id == 2):
		push_error("Gast erhält keine Revanche.")
		return false
	if guest_number == 3:
		await create_timer(0.35).timeout
		app.show_home()
	elif not await wait_until(func() -> bool: return app.screen == "network" and app.link.peer != null):
		push_error("Die verbleibenden Gäste müssen verbunden in der Lobby landen.")
		return false
	print("OK Gast %d: eigener Platz, Ergebnis und Revanche" % guest_number)
	return true
