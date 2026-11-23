extends SceneTree

const DT := 1.0 / 60.0
var catalog: ArenaCatalog
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func run() -> void:
	catalog = ArenaCatalog.new()
	for id in ArenaCatalog.STUDENTS:
		check_move_set(id)
	check_repetition()
	check_escape()
	check_online_snapshot()
	await check_ui_and_music()
	print("Geprüft: sechs ausführbare Moves je Schülerfigur, Finisher-Treffer, Wiederholungen und Druckmusik.")
	quit(0 if failures == 0 else 1)


func bout_for(id: int, mode: String = "practice") -> ArenaBout:
	var arena := 0 if mode == "practice" else 1
	var bout := ArenaBout.new(catalog, arena, id, 10, mode)
	bout.starts_in = 0.0
	bout.fighters[1].p.x = bout.fighters[0].p.x + 53.0
	return bout


func advance(bout: ArenaBout, frames: int) -> void:
	for tick in frames:
		bout.tick(DT, 0, 0, 0, 0)


func check_move_set(id: int) -> void:
	var profile := catalog.fighters[id]
	var names := {}
	for move in ArenaMoves.KEYS:
		var label := ArenaMoves.move_name(profile, move)
		check(not label.is_empty() and not names.has(label), "%s · benannter Move %s" % [profile["name"], move])
		names[label] = true
	for move in ArenaMoves.OPENERS:
		var bout := bout_for(id)
		var hero := bout.fighters[0]
		var rival := bout.fighters[1]
		var held := 0
		match move:
			"rush":
				hero.v.x = 318.0 * float(profile["speed"])
				rival.p.x = hero.p.x + 90.0
				held = ArenaBout.RIGHT
			"sweep":
				held = ArenaBout.DOWN
			"air":
				hero.p.y -= 36.0
				hero.standing = false
		bout.tick(DT, held, ArenaBout.ATTACK, 0, 0)
		check(hero.attack_kind == move, "%s · falscher Move für %s" % [profile["name"], move])
		advance(bout, 10)
		check(rival.balance > 0.0 and hero.combo_window > 0.0, "%s · Treffer mit %s" % [profile["name"], move])
		if move == "normal":
			var damage := rival.balance
			bout.tick(DT, 0, ArenaBout.SPECIAL, 0, 0)
			check(hero.attack_kind == "finisher" and hero.combo_window == 0.0 and hero.cooldown > 0.0,
				"%s · Spezialtaste wechselt zum Finisher" % profile["name"])
			advance(bout, 7)
			check(rival.balance > damage + 10.0, "%s · Finisher trifft als zweiter Move" % profile["name"])
	var signature := bout_for(id)
	signature.tick(DT, 0, ArenaBout.SPECIAL, 0, 0)
	check(signature.fighters[0].attack_kind == profile["kind"], "%s · reguläre Spezialfähigkeit" % profile["name"])


func check_repetition() -> void:
	var bout := bout_for(4)
	var hero := bout.fighters[0]
	var first_damage := 0.0
	for repetition in 3:
		bout.reset_position(1, false)
		var target := bout.fighters[1]
		target.p.x = hero.p.x + 45.0
		bout.tick(DT, 0, ArenaBout.ATTACK, 0, 0)
		advance(bout, 18)
		if repetition == 0:
			first_damage = target.balance
		else:
			check(target.balance < first_damage * 0.89, "Wiederholter Treffer verliert Schaden")
		check(hero.repeated_hits == repetition + 1, "Wiederholungen zählen getroffene Angriffe")
	bout.reset_position(1, false)
	bout.fighters[1].p.x = hero.p.x + 45.0
	bout.tick(DT, ArenaBout.DOWN, ArenaBout.ATTACK | ArenaBout.DOWN, 0, 0)
	advance(bout, 18)
	check(hero.repeated_hits == 1 and hero.last_opener == "sweep", "Wechsel zum Beinfeger hebt Abschlag auf")


func check_escape() -> void:
	var bout := bout_for(9, "local")
	var hero := bout.fighters[0]
	bout.fighters[1].shield = 0.6
	bout.tick(DT, 0, ArenaBout.ATTACK, 0, 0)
	advance(bout, 18)
	check(hero.combo_window == 0.0 and bout.fighters[1].balance == 0.0, "Geblockter Angriff öffnet keinen Finisher")
	bout.tick(DT, 0, ArenaBout.DODGE, 0, 0)
	advance(bout, 17)
	bout.tick(DT, 0, ArenaBout.DODGE, 0, 0)
	check(hero.dodge_time == 0.0 and hero.dodge_recovery > 0.0, "Ausweichen hat eine konterbare Pause")


func check_online_snapshot() -> void:
	var host := bout_for(4, "network")
	var guest := bout_for(4, "network")
	host.tick(DT, 0, ArenaBout.ATTACK, 0, 0)
	guest.apply_snapshot(host.snapshot())
	check(guest.fighters[0].pending, "Host sendet die Angriffsvorwarnung")
	advance(host, 10)
	guest.apply_snapshot(host.snapshot())
	check(guest.fighters[0].combo_window > 0.0 and guest.fighters[1].balance > 0.0,
		"Host sendet Treffer und Finisher-Fenster")


func check_ui_and_music() -> void:
	var app := ArenaApp.new()
	root.add_child(app)
	app.set_physics_process(false)
	check(app.music.stream is AudioStreamOggVorbis and app.track == "lobby" and app.music.stream.loop,
		"Die Menümusik lädt als Loop")
	app.show_selection("practice")
	for item in app.ui.get_children():
		if item is Button and item.text == "Moves ansehen":
			item.pressed.emit()
			break
	check(app.screen == "moves", "Move-Liste aus der Figurenwahl erreichbar")
	app.go_back()
	check(app.screen == "select", "Rückkehr aus der Move-Liste")
	app.begin_bout(1, 4, 9, "local")
	app.bout.starts_in = 0.0
	app.bout.fighters[0].stocks = 1
	app.bout.fighters[1].stocks = 1
	app.update_match_music()
	check(app.track == "pressure", "Druckmusik bei einem verbleibenden Versuch pro Spieler")
	app.start_practice()
	app.show_pause()
	app.show_move_list(app.bout.fighters[0].id, 0, true)
	app.go_back()
	check(app.paused and app.pause_page.is_empty() and app.bout.mode == "practice", "Move-Liste pausiert Training")
	app.queue_free()
	await process_frame
