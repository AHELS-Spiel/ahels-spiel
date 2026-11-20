extends SceneTree

class PlaythroughApp extends ArenaApp:
	var input_bits := 0

	func poll_controls(index: int) -> int:
		return input_bits if index == 0 else 0

const STEP := 1.0 / 60.0
var game: PlaythroughApp

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = PlaythroughApp.new()
	root.add_child(game)
	game.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	seed(8)
	var passed := false
	if "tournament" in args:
		passed = play_tournament()
	elif "survival" in args:
		passed = play_survival()
	else:
		passed = play_campaign()
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)


func play_campaign() -> bool:
	if not press("Solo-Kampagne"):
		return false
	game.choose_fighter(9)
	if not press("Tutorial starten"):
		return false
	if game.bout.fighters[0].profile["name"] != "Valentin":
		fail("Die gewählte Figur wird nicht geladen")
		return false
	advance(ArenaBout.RIGHT, 33)
	advance(ArenaBout.RIGHT | ArenaBout.JUMP)
	for frame in 110:
		if game.bout.fighters[0].p.x >= 866:
			break
		advance(ArenaBout.RIGHT)
	advance(0, 12)
	advance(ArenaBout.ATTACK)
	advance(0, 14)
	advance(ArenaBout.SPECIAL)
	advance(0, 36)
	advance(ArenaBout.DODGE)
	advance(0, 5)
	if not press("Zum Pausenhof"):
		return false
	print("OK Tutorial mit echten Spielaktionen beendet")
	var next_buttons := ["Weiter · Computerraum", "Weiter · Aula", "Weiter · Bibliothek", "Kampagne erneut spielen"]
	for chapter in range(1, 5):
		if not press("Duell starten"):
			return false
		game.bout.rng.seed = 134 + chapter
		var saw_warning := fight()
		if chapter == ArenaApp.CAMPAIGN_ARENAS.size() and not saw_warning:
			fail("Im Finale erschien keine Vorwarnung.")
			return false
		if game.bout.winner != 0:
			fail("Niederlage in Kapitel %d" % chapter)
			return false
		print("OK ", game.bout.stage["name"], " gewonnen in ", roundi(game.bout.time), " s")
		if not press(next_buttons[chapter - 1]):
			return false
	if not game.completed or game.bout.mode != "training":
		fail("Der Kampagnenabschluss fehlt")
		return false
	print("OK Finale abgeschlossen und Kampagne erneut gestartet")
	return true


func play_tournament() -> bool:
	if not press("Turnier"):
		return false
	game.choose_fighter(9)
	if not press("Turnier starten"):
		return false
	var seen_arenas: Array[int] = []
	var seen_fighters: Array[int] = []
	for round_index in ArenaApp.TOURNAMENT_ROUNDS:
		if not press("Duell starten"):
			return false
		var pairing := Vector2i(game.bout.stage_index, game.bout.fighters[1].id)
		var level := game.bout.difficulty
		if pairing.x in seen_arenas or pairing.y in seen_fighters or pairing.y == game.bout.fighters[0].id:
			fail("Turnier-Paarung doppelt: " + str(pairing))
			return false
		seen_arenas.append(pairing.x)
		seen_fighters.append(pairing.y)
		if round_index == 0:
			game.bout.starts_in = 0.0
			game.bout.fighters[0].stocks = 1
			game.bout.fighters[0].p.y = 1000
			advance(0)
			if game.bout.winner != 1 or not press("Runde wiederholen"):
				return false
			if pairing != Vector2i(game.bout.stage_index, game.bout.fighters[1].id) or level != game.bout.difficulty:
				fail("Paarung bei Wiederholung verändert")
				return false
		game.bout.rng.seed = 286 + round_index
		fight()
		if game.bout.winner != 0:
			fail("Turnierrunde %d verloren" % (round_index + 1))
			return false
		print("OK Turnierrunde ", round_index + 1, " · ", game.bout.stage["name"], " · ", roundi(game.bout.time), " s")
		if not press("Nächste Runde" if round_index < 3 else "Zum Hauptmenü"):
			return false
	var saved := ConfigFile.new()
	if game.tournament_wins != 1 or game.tournament_retries != 1 or saved.load(ArenaApp.SAVE_FILE) != OK \
			or saved.get_value("tournament", "wins", 0) != 1:
		fail("Turnierergebnis fehlt")
		return false
	return true


func play_survival() -> bool:
	if not press("Überleben"):
		return false
	game.choose_fighter(9)
	if not press("Überleben starten"):
		return false
	for wave in ArenaApp.SURVIVAL_DIFFICULTIES.size():
		game.bout.rng.seed = 188 + wave
		fight()
		if game.bout.winner != 0:
			fail("Überleben · Niederlage in Welle %d" % (wave + 1))
			return false
		print("OK Überleben · Welle ", wave + 1, " · Restversuche ", game.bout.fighters[0].stocks)
		if not press("Nächste Welle" if wave < 4 else "Zum Hauptmenü"):
			return false
	return game.survival_best == ArenaApp.SURVIVAL_DIFFICULTIES.size()


func advance(keys: int, frames: int = 1) -> void:
	game.input_bits = keys
	for _frame in frames:
		game._physics_process(STEP)

func press(button_text: String) -> bool:
	for item in game.ui.get_children():
		if item is Button and item.text == button_text and not item.disabled:
			item.pressed.emit()
			return true
	fail("Schaltfläche fehlt: " + button_text)
	return false

func fight() -> bool:
	var bout := game.bout
	var hero := bout.fighters[0]
	var rival := bout.fighters[1]
	var ground: Rect2 = bout.stage["surfaces"][0]
	advance(0, 135)
	var saw_warning := false
	for frame in 9001:
		if bout.winner != ArenaBout.ONGOING:
			break
		saw_warning = saw_warning or bout.boss_warning > 0.0
		var dx := rival.p.x - hero.p.x
		var dy := rival.p.y - hero.p.y
		var target_side := ArenaBout.RIGHT if dx > 0 else ArenaBout.LEFT
		var safe_x := clampf(rival.p.x, ground.position.x + 30, ground.end.x - 30)
		var keys := 0
		if absf(safe_x - hero.p.x) > 45 or hero.facing * dx < -5:
			keys = ArenaBout.RIGHT if safe_x > hero.p.x else ArenaBout.LEFT
		if hero.p.y > ground.position.y + 10:
			keys = ArenaBout.RIGHT if hero.p.x < ground.get_center().x else ArenaBout.LEFT
			if hero.jumps > 0 and hero.v.y > -80:
				keys |= ArenaBout.JUMP
		elif dy > 62 and hero.standing and absf(dx) < 80:
			keys |= ArenaBout.DOWN
		elif dy < -72 and hero.standing and absf(dx) < 250:
			keys |= ArenaBout.JUMP
		var danger := false
		for shot in bout.shots:
			if shot.owner == 1 and shot.low and absf(shot.p.x - hero.p.x) < 130 and absf(shot.p.y - hero.p.y) < 66:
				danger = true
		if danger and hero.standing:
			keys |= ArenaBout.JUMP
		if dx * hero.facing >= -8 and not danger and hero.attack_time <= 0.001:
			if hero.cooldown <= 0 and absf(dy) < 55 and absf(dx) > 32 and absf(dx) < 280:
				keys |= ArenaBout.SPECIAL
			elif absf(dy) < 40 and absf(dx) < 78:
				keys |= ArenaBout.ATTACK
		# Release action buttons on alternating frames, like individual key presses.
		if frame % 2 == 0:
			keys &= ~(ArenaBout.ATTACK | ArenaBout.SPECIAL | ArenaBout.JUMP | ArenaBout.DOWN)
		advance(keys)
	return saw_warning

func fail(message: String) -> void:
	push_error(message)
	quit(1)
