class_name ArenaBout
extends RefCounted

const LEFT := 1
const RIGHT := 2
const JUMP := 4
const ATTACK := 8
const SPECIAL := 16
const DODGE := 32
const DOWN := 64
const FIGHT_ACTIONS := ATTACK | SPECIAL | DODGE
const ACTIONS := JUMP | FIGHT_ACTIONS | DOWN
const ONGOING := -2
const DRAW := -1
const MAX_SECONDS := 150.0
const DEFAULT_STOCKS := 3
const PRACTICE_BEHAVIORS: Array[String] = ["Still", "Springt", "CPU"]
const GRAVITY := 1140.0
const NORMAL_LOCK := 0.25
const STUDENT_CAP := 300.0

class Fighter:
	var id: int
	var profile: Dictionary
	var p := Vector2.ZERO
	var v := Vector2.ZERO
	var facing := 1
	var balance := 0.0
	var stocks := 3
	var standing := false
	var jumps := 2
	var coyote := 0.0
	var jump_buffer := 0.0
	var buffered_action := 0
	var action_time := 0.0
	var dodge_ready := true
	var dodge_time := 0.0
	var stun := 0.0
	var shield := 0.0
	var cooldown := 0.0
	var invulnerable := 0.0
	var drop := 0.0
	var attack_time := 0.0
	var attack_kind := ""
	var pending := false
	var run_cycle := 0.0
	var respawn := 0.0

	func _init(fighter_id: int, fighter_profile: Dictionary) -> void:
		id = fighter_id
		profile = fighter_profile


class Shot:
	var p: Vector2
	var v: Vector2
	var owner: int
	var life: float
	var power: float
	var tint: Color
	var low: bool

	func _init(at: Vector2, velocity: Vector2, who: int, duration: float,
			strength: float, color: Color, ground_wave: bool = false) -> void:
		p = at
		v = velocity
		owner = who
		life = duration
		power = strength
		tint = color
		low = ground_wave


var stage_index: int
var mode: String
var stage: Dictionary
var fighters: Array[Fighter] = []
var shots: Array[Shot] = []
var flashes: Array[Dictionary] = []
var time := 0.0
var time_limit: float
var max_stocks: int
var practice_behavior := 0
var practice_damage := 0
var starts_in := 2.15
var winner := ONGOING
var tutorial_step := 0
var lesson_time := 0.0
var lesson_origin := 0.0
var boss_phase := 1
var boss_warning := 0.0
var boss_recovery := 0.0
var boss_clock := 4.0
var boss_chalk := false
var last_boss_was_chalk := false
var bot_clock := 0.0
var bot_direction := 0
var sound_id := 0
var last_sound := ""
var audio_queue: Array[String] = []
var difficulty := 1
var rng := RandomNumberGenerator.new()


func _init(catalog: ArenaCatalog, arena: int, one: int, two: int, game_mode: String,
		bot_level: int = 1, stocks: int = DEFAULT_STOCKS, seconds: float = MAX_SECONDS) -> void:
	stage_index = arena
	max_stocks = clampi(stocks, 1, 5)
	time_limit = maxf(seconds, 0.0)
	mode = game_mode
	stage = catalog.arenas[arena]
	difficulty = bot_level
	fighters.append(Fighter.new(one, catalog.fighters[one]))
	if mode != "training":
		fighters.append(Fighter.new(two, catalog.fighters[two]))
	if mode == "training" or mode == "practice":
		starts_in = 0.0
	for i in fighters.size():
		fighters[i].stocks = max_stocks
		reset_position(i, false)
	if mode == "training":
		lesson_origin = fighters[0].p.x
	if mode == "boss":
		fighters[1].stocks = 1
	rng.randomize()


func reset_position(index: int, show_flash: bool = true) -> void:
	var fighter := fighters[index]
	var ground: Rect2 = stage["surfaces"][0]
	fighter.p = Vector2(float(stage["spawns"][index]), ground.position.y - (115.0 if show_flash else 0.0))
	fighter.v = Vector2.ZERO
	fighter.facing = 1 if index == 0 else -1
	fighter.balance = float(practice_damage) if mode == "practice" and index == 1 else 0.0
	fighter.stun = 0.0
	fighter.dodge_time = 0.0
	fighter.shield = 0.0
	fighter.attack_time = 0.0
	fighter.attack_kind = ""
	fighter.pending = false
	fighter.standing = not show_flash
	fighter.jumps = 2
	fighter.coyote = 0.0
	fighter.jump_buffer = 0.0
	fighter.buffered_action = 0
	fighter.action_time = 0.0
	fighter.dodge_ready = true
	fighter.cooldown = 0.0
	fighter.drop = 0.0
	fighter.invulnerable = 1.25 if show_flash else 0.0
	fighter.respawn = 0.42 if show_flash else 0.0
	if show_flash:
		flash(fighter.p, fighter.profile["accent"], "spawn")


func tick(delta: float, first: int, first_edge: int, second: int, second_edge: int) -> void:
	update_flashes(delta)
	if winner != ONGOING:
		return
	if starts_in > 0.0:
		starts_in = maxf(0.0, starts_in - delta)
		if starts_in == 0.0:
			sound("success")
		return
	time += delta
	if mode == "training":
		lesson_time += delta
	if mode in ["solo", "boss", "tournament", "survival"]:
		var bot := bot_input(delta)
		second = bot_direction
		second_edge = bot
	elif mode == "practice":
		match practice_behavior:
			1:
				bot_clock = maxf(0.0, bot_clock - delta)
				if fighters[1].standing and bot_clock == 0.0:
					second_edge = JUMP
					bot_clock = 1.35
			2:
				second_edge = bot_input(delta)
				second = bot_direction
	update_fighter(0, delta, first, first_edge)
	if fighters.size() == 2:
		update_fighter(1, delta, second, second_edge)
	update_shots(delta)
	if fighters.size() == 2:
		for i in fighters.size():
			if fighters[i].stocks > 0 and outside(fighters[i].p):
				ring_out(i)
		check_end()
	else:
		if outside(fighters[0].p):
			reset_position(0)
		if tutorial_step == 0 and absf(fighters[0].p.x - lesson_origin) >= 120.0:
			next_lesson()


func outside(p: Vector2) -> bool:
	return p.y > 760.0 or p.x < -90.0 or p.x > ArenaCatalog.FIELD_SIZE.x + 90.0


func update_fighter(index: int, delta: float, held: int, edge: int) -> void:
	var f := fighters[index]
	if f.stocks <= 0:
		return
	f.cooldown = maxf(0.0, f.cooldown - delta)
	f.dodge_time = maxf(0.0, f.dodge_time - delta)
	f.shield = maxf(0.0, f.shield - delta)
	f.invulnerable = maxf(0.0, f.invulnerable - delta)
	f.respawn = maxf(0.0, f.respawn - delta)
	f.stun = maxf(0.0, f.stun - delta)
	f.drop = maxf(0.0, f.drop - delta)
	var facing_input := (1 if (held & RIGHT) != 0 else 0) - (1 if (held & LEFT) != 0 else 0)
	if (edge & JUMP) != 0:
		f.jump_buffer = 0.10
	else:
		f.jump_buffer = maxf(0.0, f.jump_buffer - delta)
	if (edge & FIGHT_ACTIONS) != 0:
		f.buffered_action = edge & FIGHT_ACTIONS
		f.action_time = 0.14
	else:
		f.action_time = maxf(0.0, f.action_time - delta)
		if f.action_time == 0.0:
			f.buffered_action = 0

	if f.attack_time > 0.0:
		f.attack_time = maxf(0.0, f.attack_time - delta)
		var threshold := 0.15 if f.attack_kind == "normal" else 0.34
		if f.pending and f.attack_time <= threshold:
			f.pending = false
			resolve_attack(index)
		if f.attack_time == 0.0:
			f.attack_kind = ""

	if f.standing:
		f.coyote = 0.095
	else:
		f.coyote = maxf(0.0, f.coyote - delta)
	if f.stun <= 0.0 and f.dodge_time <= 0.0 and f.respawn <= 0.0:
		move_fighter(f, delta, edge, facing_input)
	else:
		f.v.x = move_toward(f.v.x, 0.0, delta * (140.0 if f.stun > 0.0 else 55.0))
	integrate(f, delta)


func move_fighter(f: Fighter, delta: float, edge: int, steering: int) -> void:
	var stats := f.profile
	var dodge := (f.buffered_action & DODGE) != 0 and f.dodge_ready and f.attack_time <= 0.0
	if dodge:
		f.dodge_ready = false
		f.buffered_action = 0
		f.dodge_time = 0.24
		f.invulnerable = maxf(f.invulnerable, 0.19)
		f.v = Vector2((steering if steering != 0 else f.facing) * 480.0, f.v.y * 0.25)
		flash(f.p - Vector2(0, 37), stats["accent"], "dodge")
		sound("select")
		if mode == "training" and tutorial_step == 4:
			next_lesson()
		return

	if steering != 0 and f.attack_time <= 0.04:
		f.facing = steering
	var move_speed := 318.0 * float(stats["speed"])
	var acceleration := 2600.0 if f.standing else 1350.0
	if f.attack_time > 0.03:
		f.v.x = move_toward(f.v.x, float(steering) * move_speed * 0.40, delta * acceleration * 0.38)
	else:
		f.v.x = move_toward(f.v.x, float(steering) * move_speed, delta * acceleration)

	if f.jump_buffer > 0.0 and (f.jumps > 0 or f.coyote > 0.0):
		f.v.y = -516.0 * float(stats["jump"]) if f.standing or f.coyote > 0.0 else -468.0 * float(stats["jump"])
		f.jumps = 1 if f.standing or f.coyote > 0.0 else f.jumps - 1
		f.standing = false
		f.coyote = 0.0
		f.jump_buffer = 0.0
		sound("jump")
		if mode == "training" and tutorial_step == 1:
			next_lesson()
	if (edge & DOWN) != 0:
		f.drop = 0.18
		if not f.standing:
			f.v.y = maxf(f.v.y, 390.0)
	if f.attack_time <= 0.0:
		if (f.buffered_action & SPECIAL) != 0 and f.cooldown <= 0.0:
			f.buffered_action = 0
			begin_special(f)
		elif (f.buffered_action & ATTACK) != 0:
			f.buffered_action = 0
			f.attack_kind = "normal"
			f.attack_time = NORMAL_LOCK
			f.pending = true
			sound("swing")


func integrate(f: Fighter, delta: float) -> void:
	var previous_y := f.p.y
	var was_standing := f.standing
	f.v.y = minf(f.v.y + GRAVITY * delta, 1120.0)
	f.p += f.v * delta
	f.standing = false
	if f.v.y >= 0.0:
		for i in stage["surfaces"].size():
			var surface: Rect2 = stage["surfaces"][i]
			if i > 0 and f.drop > 0.0:
				continue
			if previous_y <= surface.position.y + 0.5 and f.p.y >= surface.position.y and 					f.p.x >= surface.position.x - 12.0 and f.p.x <= surface.end.x + 12.0:
				f.p.y = surface.position.y
				f.v.y = 0.0
				f.standing = true
				f.jumps = 2
				if f.dodge_time <= 0.04:
					f.dodge_ready = true
				if not was_standing:
					flash(f.p, Color("#e5d0b5"), "dust")
				break
	if was_standing and not f.standing and f.v.y >= 0.0:
		f.jumps = mini(f.jumps, 1)
	if f.standing and absf(f.v.x) > 24.0:
		f.run_cycle += absf(f.v.x) * delta / 31.0
	else:
		f.run_cycle = 0.0


func begin_special(f: Fighter) -> void:
	f.attack_kind = String(f.profile["kind"])
	f.attack_time = 0.47
	f.cooldown = float(f.profile["cooldown"])
	f.pending = true
	match f.attack_kind:
		"dash":
			f.v.x = f.facing * 610.0
		"rise":
			f.v.y = -590.0
			f.standing = false
		"guard":
			f.shield = 0.49
		"anchor":
			f.v.x *= 0.06
			f.v.y = maxf(320.0, f.v.y) if not f.standing else 0.0
			f.shield = 0.23
	sound("special")
	if mode == "training" and tutorial_step == 3:
		next_lesson()


func resolve_attack(index: int) -> void:
	var f := fighters[index]
	var kind := f.attack_kind
	var visual: Color = f.profile["accent"]
	var at := f.p - Vector2(0, 34)
	var reach := 85.0
	var power := 9.0
	var strength := 1.0 if kind == "normal" else float(f.profile["power"])
	var vertical := 53.0
	var forward_only := true
	match kind:
		"dash":
			reach = 120.0
			power = 15.0
		"rise":
			reach = 69.0
			vertical = 92.0
			power = 14.0
			forward_only = false
		"guard":
			reach = 67.0
			power = 12.0
			forward_only = false
		"burst", "anchor":
			reach = 111.0
			power = 17.0
			forward_only = false
		"long":
			reach = 155.0
			power = 15.0
		"bolt", "echo":
			shots.append(Shot.new(at + Vector2(f.facing * 29, 0), Vector2(f.facing * 455, 0),
				index, 1.28, strength * (11.0 if kind == "bolt" else 8.0), visual))
			if kind == "echo":
				shots.append(Shot.new(at + Vector2(f.facing * 24, -36), Vector2(f.facing * 378, -20),
					index, 1.18, strength * 7.0, visual))
			flash(at, visual, "burst")
			return
	flash(at + Vector2(f.facing * 33 if forward_only else 0, 0), visual,
		"slash" if forward_only else "burst", f.facing)
	if mode == "training":
		if tutorial_step == 2 and kind == "normal" and in_reach(f, Vector2(930, 560), reach, vertical, true):
			flash(Vector2(930, 523), visual, "hit")
			sound("hit")
			next_lesson()
	else:
		var target := fighters[1 - index]
		if target.stocks > 0 and in_reach(f, target.p, reach, vertical, forward_only):
			hit(target, power * strength, f.facing if forward_only else direction(f.p.x, target.p.x), visual)


func in_reach(f: Fighter, target: Vector2, reach: float, vertical: float, forward: bool) -> bool:
	var gap := target - f.p
	return absf(gap.x) <= reach and absf(gap.y) <= vertical and (not forward or gap.x * f.facing >= -20.0)


func hit(f: Fighter, power: float, side: int, tint: Color) -> void:
	if f.invulnerable > 0.0 or f.stocks <= 0:
		return
	if f.shield > 0.0:
		f.shield = 0.0
		f.invulnerable = 0.14
		flash(f.p - Vector2(0, 32), Color("#a8ecf0"), "burst")
		sound("select")
		return
	var is_boss := mode == "boss" and f == fighters[1]
	var weight := float(f.profile["weight"]) * (1.55 if is_boss else 1.0)
	f.balance = minf(STUDENT_CAP, f.balance + power)
	var push := (178.0 + power * 9.0 + f.balance * 3.6) / weight
	f.v = Vector2(side * push, -maxf(155.0, push * 0.43))
	f.stun = clampf(push / 1560.0, 0.16, 0.56)
	f.invulnerable = 0.075
	f.standing = false
	f.attack_time = 0.0
	f.pending = false
	flash(f.p - Vector2(0, 36), tint, "hit", side)
	sound("hit")


func update_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		shot.life -= delta
		shot.p += shot.v * delta
		if shot.life <= 0.0 or shot.p.x < -50.0 or shot.p.x > 1330.0:
			shots.remove_at(i)
			continue
		if fighters.size() < 2:
			continue
		var target := fighters[1 - shot.owner]
		var diff := shot.p - (target.p - Vector2(0, 33))
		var hit_target := absf(diff.x) < (39.0 if shot.low else 34.0) and absf(diff.y) < (28.0 if shot.low else 39.0)
		if hit_target and target.stocks > 0:
			hit(target, shot.power, 1 if shot.v.x >= 0 else -1, shot.tint)
			shots.remove_at(i)


func bot_input(delta: float) -> int:
	var f := fighters[1]
	var player := fighters[0]
	var floor_surface: Rect2 = stage["surfaces"][0]
	var target_x := clampf(player.p.x + player.v.x * 0.12,
		floor_surface.position.x + 42.0, floor_surface.end.x - 42.0)
	var gap := target_x - f.p.x
	bot_direction = 0 if absf(gap) < (43.0 if mode == "boss" else 53.0) else (LEFT if gap < 0.0 else RIGHT)
	bot_clock -= delta
	if mode == "boss":
		boss_phase = 2 if f.balance >= 60 else 1
		boss_clock -= delta
		if boss_warning > 0.0:
			boss_warning = maxf(0.0, boss_warning - delta)
			bot_direction = 0
			if boss_warning == 0.0:
				release_boss_attack(f, floor_surface)
			return 0
		if boss_recovery > 0.0:
			boss_recovery = maxf(0.0, boss_recovery - delta)
			bot_direction = 0
			return 0
		if boss_clock <= 0.0 and f.standing and f.stun <= 0.0 and f.attack_time <= 0.0:
			boss_chalk = boss_phase == 2 and not last_boss_was_chalk
			boss_warning = 0.95 if boss_chalk else 0.90 if boss_phase == 1 else 0.73
			boss_clock = 5.1 if boss_phase == 1 else 3.9
			return 0
	# Retten und dem Gegner erst danach nachsetzen.
	if f.p.y > floor_surface.position.y + 17.0 or f.p.x < floor_surface.position.x + 11.0 			or f.p.x > floor_surface.end.x - 11.0:
		bot_direction = LEFT if f.p.x > floor_surface.get_center().x else RIGHT
		if f.jumps > 0 and not f.standing and f.v.y > -130.0 and bot_clock <= 0.0:
			bot_clock = 0.28
			return JUMP
	if bot_clock > 0.0 or f.stun > 0.0 or f.respawn > 0.0:
		return 0
	bot_clock = rng.randf_range(0.16, 0.36) + (0.13 if difficulty == 0 else 0.0)
	if difficulty > 1:
		bot_clock *= 1.0 - 0.12 * (difficulty - 1)
	if absf(gap) < 179.0 and player.p.y < f.p.y - 65.0 and f.jumps > 0 and f.v.y > -25.0:
		return JUMP
	if absf(gap) < 87.0 and absf(player.p.y - f.p.y) < 54.0:
		if mode == "boss":
			return SPECIAL if f.cooldown <= 0.0 and rng.randf() < 0.38 else ATTACK
		return SPECIAL if f.cooldown <= 0.0 and rng.randf() < (0.18 + difficulty * 0.12) else ATTACK
	return 0


func release_boss_attack(f: Fighter, floor_surface: Rect2) -> void:
	var tint := Color("#93ecff") if boss_chalk else Color("#ffd084") if boss_phase == 1 else Color("#ff7489")
	var point := Vector2(f.p.x, floor_surface.position.y - (130.0 if boss_chalk else 17.0))
	var speed := 410.0 if boss_chalk else 475.0 if boss_phase == 1 else 620.0
	var descent := Vector2(0, 130.0 if boss_chalk else 0.0)
	var duration := 1.0 if boss_chalk else 2.6
	var power := 16.0 if boss_chalk else 19.0
	for side in [-1, 1]:
		shots.append(Shot.new(point, Vector2(side * speed, 0) + descent, 1, duration, power, tint, not boss_chalk))
	last_boss_was_chalk = boss_chalk
	boss_recovery = 1.25 if boss_chalk else 1.02
	flash(point, tint, "burst")
	sound("boss")


func ring_out(index: int) -> void:
	var fighter := fighters[index]
	if mode != "practice":
		fighter.stocks -= 1
	sound("out")
	flash(Vector2(clampf(fighter.p.x, 22.0, 1258.0), clampf(fighter.p.y, 135.0, 630.0)),
		fighter.profile["accent"], "out")
	if fighter.stocks > 0:
		reset_position(index)


func check_end() -> void:
	if mode == "practice":
		return
	if mode == "boss" and fighters[1].balance >= 131.0:
		fighters[1].stocks = 0
		flash(fighters[1].p - Vector2(0, 42), Color("#ffcf9b"), "out")
	if fighters[0].stocks == 0 or fighters[1].stocks == 0:
		if fighters[0].stocks == fighters[1].stocks:
			winner = DRAW
		else:
			winner = 0 if fighters[0].stocks > 0 else 1
	elif time_limit > 0.0 and time >= time_limit:
		var one := fighters[0]
		var two := fighters[1]
		if mode == "boss":
			winner = 1
		elif one.stocks != two.stocks:
			winner = 0 if one.stocks > two.stocks else 1
		elif is_equal_approx(one.balance, two.balance):
			winner = DRAW
		else:
			winner = 0 if one.balance < two.balance else 1
	if winner != ONGOING:
		sound("success")


func next_lesson() -> void:
	tutorial_step = mini(tutorial_step + 1, 5)
	lesson_time = 0.0
	sound("success")


func direction(from_x: float, to_x: float) -> int:
	return -1 if to_x < from_x else 1


func flash(at: Vector2, tint: Color, kind: String, facing: int = 1) -> void:
	var life := 0.52 if kind in ["spawn", "out"] else 0.26
	flashes.append({"p": at, "c": tint, "k": kind, "v": facing, "life": life, "max": life})


func update_flashes(delta: float) -> void:
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i]["life"] -= delta
		if flashes[i]["life"] <= 0.0:
			flashes.remove_at(i)


func sound(cue: String) -> void:
	last_sound = cue
	sound_id += 1
	audio_queue.append(cue)


func snapshot() -> Dictionary:
	var actors: Array = []
	var objects: Array = []
	for f in fighters:
		actors.append([f.p, f.v, f.facing, f.balance, f.stocks, f.standing, f.attack_time,
			f.attack_kind, f.run_cycle, f.stun, f.invulnerable, f.dodge_time, f.shield, f.cooldown])
	for shot in shots:
		objects.append([shot.p, shot.v, shot.tint, shot.low])
	return {"t": time, "c": starts_in, "w": winner, "f": actors, "s": objects, "x": flashes,
		"si": sound_id, "ls": last_sound}


func apply_snapshot(state: Dictionary) -> void:
	time = state["t"]
	starts_in = state["c"]
	winner = state["w"]
	for i in fighters.size():
		var f := fighters[i]
		var data: Array = state["f"][i]
		f.p = data[0]
		f.v = data[1]
		f.facing = data[2]
		f.balance = data[3]
		f.stocks = data[4]
		f.standing = data[5]
		f.attack_time = data[6]
		f.attack_kind = data[7]
		f.run_cycle = data[8]
		f.stun = data[9]
		f.invulnerable = data[10]
		f.dodge_time = data[11]
		f.shield = data[12]
		f.cooldown = data[13]
	shots.clear()
	for shot: Array in state["s"]:
		shots.append(Shot.new(shot[0], shot[1], 0, 1.0, 0.0, shot[2], shot[3]))
	flashes.assign(state["x"])
	if sound_id != state["si"] and not String(state["ls"]).is_empty():
		sound_id = state["si"]
		audio_queue.append(state["ls"])
