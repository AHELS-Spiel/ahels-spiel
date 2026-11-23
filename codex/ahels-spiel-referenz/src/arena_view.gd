class_name ArenaView
extends Node2D

const DISPLAY := preload("res://assets/fonts/Display.ttf")
const BOLD := preload("res://assets/fonts/OpenSans-Bold.ttf")
const TEXT := preload("res://assets/fonts/OpenSans-Regular.ttf")
const SCREEN := Rect2(0, 0, 1280, 720)
const NIGHT := Color("#101728")
const PAPER := Color("#f8f0df")
const SOFT := Color("#d5d9df")
const MINT := Color("#9ee9ce")
const PEACH := Color("#ffad94")
const PLATFORM_COLORS: Array[Color] = [
	Color("#283a4f"), Color("#253746"), Color("#253048"), Color("#433145"),
	Color("#283d3b"), Color("#473952"), Color("#45273f"), Color("#263d4f"),
]
const FAKE_LINES: Array[String] = [
	"Nach links! Also … mein links. Oder deins?",
	"Springen? Ich glaube, man wird dabei kleiner.",
	"Die Zielscheibe trifft man am besten mit Nichtstun.",
	"Die Spezialtaste ist sicher die lange da unten.",
	"Ausweichen! Jetzt einmal ganz still stehen.",
	"Ha! Genau so wollte ich es vorzeigen. Ungefähr.",
]
const PAD_LINES: Array[String] = [
	"Bewege dich mit dem linken Stick.",
	"Springe mit A. Drück A in der Luft erneut für den Doppelsprung.",
	"Geh nah an die Zielscheibe rechts und drück X.",
	"Drück Y für die Spezialfähigkeit deiner Figur.",
	"Weiche mit B aus. Am Boden lädt die Rolle wieder auf.",
	"Geschafft! Du hast alle Übungen abgeschlossen.",
]
const LESSONS: Array[String] = ["Laufen", "Springen", "Treffen", "Spezial", "Ausweichen"]

var catalog: ArenaCatalog
var keyboard: ArenaKeys
var bout: ArenaBout
var menu_scene := "home"
var match_context := ""
var clock := 0.0
var smooth_remote := false
var reduced_effects := false
var render_positions: Array[Vector2] = []
var previous_state: ArenaBout
var spotlight_id := -1
var spotlight_until := 0.0


func show_spotlight(id: int, seconds: float) -> void:
	spotlight_id = id
	spotlight_until = clock + seconds



func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	clock += delta
	if previous_state != bout:
		previous_state = bout
		render_positions.clear()
	if bout != null and smooth_remote:
		for i in bout.fighters.size():
			var target := bout.fighters[i].p
			if i >= render_positions.size():
				render_positions.append(target)
			elif render_positions[i].distance_to(target) > 140.0:
				render_positions[i] = target
			else:
				render_positions[i] = render_positions[i].lerp(target, minf(delta * 31.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if catalog == null:
		return
	if bout == null:
		draw_menu_background()
	else:
		draw_match()


func draw_menu_background() -> void:
	draw_texture_rect(catalog.backdrops[1], SCREEN, false)
	if menu_scene != "home":
		draw_rect(SCREEN, Color(0.03, 0.055, 0.105, 0.88))
		for x in range(17, 1280, 38):
			for y in range(14, 720, 38):
				draw_rect(Rect2(x, y, 2, 2), Color(0.58, 0.72, 0.85, 0.12))
		return
	draw_rect(SCREEN, Color(0.027, 0.045, 0.095, 0.28))
	for strip in 24:
		var opacity := lerpf(0.085, 0.018, float(strip) / 23.0)
		draw_rect(Rect2(strip * 29, 0, 650 - strip * 22, 720), Color(0.025, 0.035, 0.083, opacity))
	draw_rect(Rect2(0, 631, 1280, 89), Color("#122034"))
	draw_line(Vector2(0, 631), Vector2(1280, 631), Color("#4c6578"), 2)
	draw_platform(Rect2(650, 565, 553, 53), MINT, 1)
	draw_platform(Rect2(778, 426, 155, 23), PEACH, 1)
	for i in (0 if reduced_effects else 32):
		var x := fposmod(float(i * 173) + clock * (13.0 + float(i % 3)), 690.0) + 580.0
		var y := 145.0 + fposmod(float(i * 83) - clock * float(6 + (i % 8)), 440.0)
		var size := 2 + (i % 3)
		draw_rect(Rect2(floorf(x), floorf(y), size, size), Color(0.98, 0.75, 0.64, 0.18 + float(i % 3) * 0.14))
	var bob := 0.0 if reduced_effects else roundf(sin(clock * 2.4) * 6.0)
	draw_circle(Vector2(947, 327), 152, Color(0.97, 0.74, 0.65, 0.11))
	draw_arc(Vector2(964, 320), 147, 2.91, 4.99, 22, Color(0.64, 0.93, 0.80, 0.52), 2)
	draw_arc(Vector2(945, 315), 170, -0.43, 2.2, 24, Color(0.98, 0.66, 0.54, 0.46), 2)
	catalog.draw_sprite(self, 9, 7, Rect2(655, 322 + bob, 282, 356), 1, Color("#cadbf7"))
	catalog.draw_sprite(self, 17, 5, Rect2(883, 177 - bob, 305, 385), -1)
	draw_line(Vector2(688, 498), Vector2(603, 522), Color(0.55, 0.87, 0.81, 0.35), 3)
	draw_line(Vector2(1102, 245), Vector2(1208, 212), Color(0.99, 0.82, 0.73, 0.39), 3)


func draw_match() -> void:
	var accent: Color = bout.stage["accent"]
	draw_texture_rect(catalog.backdrops[bout.stage_index], SCREEN, false)
	draw_rect(SCREEN, Color(0.032, 0.058, 0.11, 0.30))
	for strip in 7:
		draw_rect(Rect2(0, 720 - (strip + 1) * 12, 1280, 12),
			Color(0.045, 0.059, 0.11, 0.61 - strip * 0.07))
	for surface: Rect2 in bout.stage["surfaces"]:
		draw_platform(surface, accent, bout.stage_index)
	if bout.mode == "training":
		draw_training_actors()
	for shot in bout.shots:
		draw_shot(shot)
	for i in bout.fighters.size():
		var f := bout.fighters[i]
		if f.stocks <= 0:
			continue
		var position := render_positions[i] if smooth_remote and i < render_positions.size() else f.p
		draw_fighter(f, position, i)
	for fx in bout.flashes:
		draw_flash(fx)
	draw_hud()
	if spotlight_id >= 0 and clock < spotlight_until:
		draw_spotlight()
	if bout.mode == "training":
		draw_lesson()
	elif bout.mode == "practice":
		draw_practice()
	if bout.starts_in > 0.0:
		draw_countdown()


func draw_platform(surface: Rect2, accent: Color, stage: int) -> void:
	var x := surface.position.x
	var y := surface.position.y
	var w := surface.size.x
	var h := surface.size.y
	var deep := PLATFORM_COLORS[stage] if stage < PLATFORM_COLORS.size() else accent.darkened(0.7)
	draw_rect(Rect2(x, y + 4, w, h), NIGHT)
	draw_rect(Rect2(x + 4, y + 10, w - 8, h - 11), deep)
	draw_rect(Rect2(x, y, w, 5), accent)
	draw_rect(Rect2(x + 3, y + 5, w - 6, 4), accent.darkened(0.51))
	draw_line(Vector2(x + 8, y + h - 5), Vector2(x + w - 8, y + h - 5), deep.lightened(0.16), 2)
	for tile in range(14, int(w) - 12, 29):
		draw_rect(Rect2(x + tile, y + 13, 2, h - 20), deep.lightened(0.12))
		if tile % 3 == 1 and h > 32:
			draw_rect(Rect2(x + tile + 6, y + 20, 12, 3), deep.lightened(0.33))


func draw_fighter(f: ArenaBout.Fighter, position: Vector2, index: int) -> void:
	var p := position.round()
	var accent: Color = f.profile["accent"]
	var player_color := MINT if index == 0 else PEACH
	var large := 1.22 if f.id == ArenaCatalog.BOSS else 1.0
	var size := ArenaCatalog.SPRITE_SIZE * 1.32 * large
	var foot := Rect2(p.x - size.x * 0.53, p.y - size.y * 0.925, size.x, size.y)
	var frame := int(clock * 2.8) % 2
	if f.stun > 0.0:
		frame = 8
	elif f.attack_time > 0.0:
		frame = 6 if f.attack_kind in ArenaMoves.OPENERS else 7
		if f.attack_kind == "sweep":
			foot.position.y += 10.0
		elif f.attack_kind == "air":
			foot.position.y -= 6.0
	elif not f.standing or f.dodge_time > 0.0:
		frame = 5
	elif absf(f.v.x) > 33.0:
		frame = 2 + int(f.run_cycle) % 3
	var tint := Color.WHITE
	if f.invulnerable > 0.12 and (reduced_effects or int(clock * 18.0) % 2 == 0):
		tint.a = 0.75 if reduced_effects else 0.57
	if f.stun > 0.11:
		tint = Color("#ffd8c5")
	if f.dodge_time > 0.0 and not reduced_effects:
		catalog.draw_sprite(self, f.id, frame, Rect2(foot.position - Vector2(f.v.x * 0.054, 0), foot.size),
			f.facing, Color(accent, 0.27))
	if f.standing:
		draw_shadow(p, 25.0 * large)
	if f.shield > 0.0:
		draw_circle(p - Vector2(0, 50), 48, Color(accent, 0.11))
		draw_arc(p - Vector2(0, 50), 48, 0, TAU, 30, Color(accent, 0.75), 2)
	catalog.draw_sprite(self, f.id, frame, foot, f.facing, tint)
	if f.pending and f.attack_kind in ["rush", "sweep", "finisher"]:
		var anticipation := p + Vector2(26 * f.facing, -27 if f.attack_kind == "sweep" else -82)
		draw_rect(Rect2(anticipation, Vector2(7, 7)), PAPER)
	if f.id == ArenaCatalog.BOSS and bout.boss_warning > 0.0:
		var warning := 1.0 - bout.boss_warning / 0.95
		var color := Color("#93ecff") if bout.boss_chalk else PEACH
		if bout.boss_chalk:
			var origin := p + Vector2(0, -130)
			for side in [-1, 1]:
				draw_dashed_line(origin, origin + Vector2(410 * side, 130), color, 2.0, 12.0)
		else:
			draw_arc(p - Vector2(0, 2), 37 + 90 * warning, PI, TAU, 20, color, 3)
		draw_string(DISPLAY, p + Vector2(-6, -138), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, color)
	elif bout.mode != "training":
		var badge := p + Vector2(0, -128 * large)
		draw_rect(Rect2(badge - Vector2(9, 9), Vector2(18, 18)), NIGHT)
		draw_rect(Rect2(badge - Vector2(9, 9), Vector2(18, 18)), player_color, false)
		draw_string(BOLD, badge + Vector2(-8, 5), str(index + 1),
			HORIZONTAL_ALIGNMENT_CENTER, 16, 12, player_color)


func draw_shadow(at: Vector2, half: float) -> void:
	draw_set_transform(at + Vector2(0, 2), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, half, Color(0.065, 0.09, 0.15, 0.42))
	draw_set_transform(Vector2.ZERO)


func draw_shot(shot: ArenaBout.Shot) -> void:
	var p := shot.p.round()
	var sign_x := signf(shot.v.x)
	var tint := shot.tint
	if shot.low:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-27, 17), p + Vector2(-14,-5),
			p + Vector2(0,-18), p + Vector2(16,-3), p + Vector2(31,17)]), Color(tint, 0.71))
		draw_line(p + Vector2(-31, 17), p + Vector2(31, 17), PAPER, 3)
	else:
		draw_rect(Rect2(p.x - 13 - 18 * sign_x, p.y - 3, 26, 6), Color(tint, 0.40))
		draw_rect(Rect2(p.x - 10, p.y - 7, 20, 14), Color(tint, 0.74))
		draw_rect(Rect2(p.x - 4, p.y - 4, 8, 8), PAPER)


func draw_flash(fx: Dictionary) -> void:
	var progress := 1.0 - float(fx["life"]) / float(fx["max"])
	var p: Vector2 = fx["p"]
	var c := Color(fx["c"], 1.0 - progress)
	if reduced_effects:
		if fx["k"] != "dust" and progress < 0.65:
			draw_arc(p, 12 + progress * 24, 0, TAU, 12, c, 2)
		return
	var facing := float(fx["v"])
	match String(fx["k"]):
		"rush":
			for n in 4:
				var start := p + Vector2(-27 * facing, n * 9 - 15)
				draw_line(start, start + Vector2(facing * (35 + progress * 60), 0), c, 4.0 - progress * 2)
		"sweep":
			draw_set_transform(p, 0.0, Vector2(1.0, 0.25))
			draw_arc(Vector2.ZERO, 25 + progress * 86, 0, TAU, 18, c, 7)
			draw_set_transform(Vector2.ZERO)
		"air":
			var angle := 0.65 if facing > 0.0 else PI - 0.65
			draw_arc(p, 22 + progress * 54, angle - 0.9, angle + 0.85, 16, c, 5)
		"combo":
			var radius := 25 + progress * 67
			var points := PackedVector2Array([p - Vector2(radius, 0), p - Vector2(0, radius),
				p + Vector2(radius, 0), p + Vector2(0, radius), p - Vector2(radius, 0)])
			draw_polyline(points, c, 4.0 - progress * 2)
			draw_arc(p, 20 + progress * 93, 0, TAU, 24, Color(PAPER, c.a * 0.65), 2)
		"slash":
			var angle := 0.0 if int(fx["v"]) > 0 else PI
			draw_arc(p, 15 + progress * 40, angle - 1.32, angle + 1.22, 13, c, 5.0 - 3.0 * progress)
			draw_arc(p, 22 + progress * 46, angle - 1.10, angle + .63, 10, Color(c, c.a * 0.45), 2)
		"hit", "burst":
			draw_arc(p, 8 + progress * 63, 0, TAU, 10, c, 3)
			for index in 7:
				var spark := p + Vector2.from_angle(index * TAU / 7.0 + .5) * (8 + progress * 64)
				draw_rect(Rect2(spark.round(), Vector2(5, 3)), c)
		"out", "spawn":
			draw_line(p, p - Vector2(0, 110 + progress * 70), c, 16.0 * (1.0 - progress) + 2)
			draw_arc(p, 11 + progress * 70, 0, TAU, 16, c, 2)
		"dodge":
			draw_arc(p, 14 + progress * 54, 0, TAU, 18, c, 2)
		"dust":
			for i in 6:
				var dust := p + Vector2((i - 2.5) * (8 + progress * 7), -progress * (4 + (i % 3) * 6))
				draw_rect(Rect2(dust.round(), Vector2(4, 3)), Color(c, c.a * 0.55))


func draw_training_actors() -> void:
	var phase := bout.lesson_time
	var tutor_x := 627.0
	var tutor_y := 560.0
	var d := 1
	var frame := int(clock * 2.3) % 2
	match bout.tutorial_step:
		0:
			tutor_x += minf(phase * 53.0, 75.0)
			if phase < 1.42:
				frame = 2 + int(phase * 8.0) % 3
		1:
			var stumble := clampf(phase - 0.28, 0.0, 0.53)
			tutor_y -= 35.0 * sin(stumble / .53 * PI)
			frame = 5 if stumble < .52 else 8
		2:
			d = -1
			frame = 6 if phase < 0.65 else 0
		3:
			frame = 8 if phase < 1.4 else 0
		4:
			frame = 0
			d = -1
		5:
			frame = 7
	draw_shadow(Vector2(tutor_x, 560), 21)
	catalog.draw_sprite(self, ArenaCatalog.TUTOR, frame,
		Rect2(tutor_x - 42, tutor_y - 106, 91, 116), d)
	draw_rect(Rect2(882, 551, 95, 9), Color("#30394d"))
	draw_rect(Rect2(922, 515, 14, 38), Color("#90604b"))
	draw_circle(Vector2(930, 505), 28, Color("#302c45"))
	draw_circle(Vector2(930, 504), 23, PEACH)
	draw_circle(Vector2(930, 504), 15, PAPER)
	draw_circle(Vector2(930, 504), 7, Color("#c9686f"))
	if bout.tutorial_step == 2:
		draw_arc(Vector2(930, 504), 35.0 + 4.0 * sin(clock * 6), 0, TAU, 24, MINT, 2)
		draw_string(BOLD, Vector2(889, 458), "ZIELSCHEIBE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PAPER)


func draw_hud() -> void:
	var middle := String(bout.stage["name"]).to_upper()
	match bout.mode:
		"training":
			middle = "TUTORIAL"
		"practice":
			middle = "TRAINING"
	draw_rect(Rect2(0, 0, 1280, 108), Color(0.055, 0.082, 0.141, 0.93))
	draw_line(Vector2(0, 108), Vector2(1280, 108), Color("#465671"), 2)
	draw_string(DISPLAY, Vector2(478, 47), middle, HORIZONTAL_ALIGNMENT_CENTER, 324, 29, PAPER)
	var sub := "TURNSAAL"
	if bout.mode == "practice":
		sub = "Gegner: %s" % ArenaBout.PRACTICE_BEHAVIORS[bout.practice_behavior]
	elif bout.mode != "training":
		var remaining := ceili(maxf(0.0, bout.time_limit - bout.time))
		sub = "%d:%02d" % [remaining / 60, remaining % 60] if bout.time_limit > 0.0 else "Ohne Zeitlimit"
	draw_string(BOLD, Vector2(488, 78), sub, HORIZONTAL_ALIGNMENT_CENTER, 304, 16, SOFT)
	if not match_context.is_empty():
		draw_string(BOLD, Vector2(488, 97), match_context, HORIZONTAL_ALIGNMENT_CENTER, 304, 11, MINT)
	for index in bout.fighters.size():
		draw_status(index)
	if bout.mode == "training":
		var y := 63.0
		var x := 963.0
		draw_string(BOLD, Vector2(x, 39), "ÜBUNGEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SOFT)
		for n in 5:
			draw_rect(Rect2(x + 53 * n, y, 42, 6), MINT if n < bout.tutorial_step else Color("#3a4b61"))


func draw_spotlight() -> void:
	var fighter := catalog.fighters[spotlight_id]
	var profile: Dictionary = fighter["class_duel"]
	var accent: Color = fighter["accent"]
	var area := Rect2(478, 116, 324, 47)
	draw_rect(area, Color("#162036"))
	draw_rect(Rect2(area.position, Vector2(3, area.size.y)), accent)
	draw_texture_rect(catalog.portraits[spotlight_id], Rect2(489, 120, 34, 37), false)
	var caption: String = "%s · %s" % [fighter["name"], profile["callout"]]
	draw_string(BOLD, Vector2(532, 145), caption, HORIZONTAL_ALIGNMENT_LEFT, 258, 16, PAPER)


func draw_status(index: int) -> void:
	var f := bout.fighters[index]
	var x := 33.0 if index == 0 else 925.0
	var color := MINT if index == 0 else PEACH
	draw_rect(Rect2(x, 24, 58, 61), Color("#253650"))
	draw_rect(Rect2(x, 24, 3, 61), color)
	draw_texture_rect(catalog.portraits[f.id], Rect2(x+2, 26, 54, 61), false)
	var fighter_name := String(f.profile["name"])
	if f.id in [5, 7, 15, 16]:
		fighter_name += " · %02d" % (f.id + 1)
	draw_string(BOLD, Vector2(x+73, 41), fighter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
	if bout.mode != "training":
		if f.id == ArenaCatalog.BOSS:
			var s := clampf(1.0 - f.balance / 131.0, 0, 1)
			draw_rect(Rect2(x+73, 53, 172, 8), Color("#38425a"))
			draw_rect(Rect2(x+73, 53, 172*s, 8), color)
			var warning_name := "KREIDEBOGEN!" if bout.boss_chalk else "REGALWELLE!"
			var hint := "ÖFFNUNG" if bout.boss_recovery > 0 else warning_name if bout.boss_warning > 0 else "PHASE %d" % bout.boss_phase
			draw_string(BOLD, Vector2(x+73, 81), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		else:
			if bout.mode == "practice":
				draw_string(TEXT, Vector2(x+73, 65), String(f.profile["ability"]),
					HORIZONTAL_ALIGNMENT_LEFT, 120, 13, SOFT)
			else:
				var stock_slots := 1 if bout.mode == "survival" and index == 1 else bout.max_stocks
				for stock in stock_slots:
					draw_rect(Rect2(x+73 + stock*18, 56, 11, 11), color if stock < f.stocks else Color("#39465b"))
			var value_x := x + (199 if bout.mode == "practice" else 169)
			draw_string(DISPLAY, Vector2(value_x, 83), "%d%%" % roundi(f.balance),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 36, color)
	if f.id != ArenaCatalog.BOSS:
		draw_rect(Rect2(x+73, 82, 71, 4), Color("#3a4b61"))
		var ready := 1.0 - clampf(f.cooldown / float(f.profile["cooldown"]), 0.0, 1.0)
		draw_rect(Rect2(x+73, 82, 71.0 * ready, 4), color)

		if f.combo_window > 0.0 and f.cooldown <= 0.0:
			draw_string(BOLD, Vector2(x + 73, 101), "FINISHER BEREIT", HORIZONTAL_ALIGNMENT_LEFT, 249, 12, color)
			draw_rect(Rect2(x + 181, 93, 72.0 * f.combo_window / ArenaMoves.CHAIN_TIME, 3), color)
		elif f.repeated_hits > 1:
			var percent := roundi(ArenaMoves.repetition_scale(f.repeated_hits - 1) * 100)
			draw_string(TEXT, Vector2(x + 73, 101), "Wiederholung · %d%%" % percent,
				HORIZONTAL_ALIGNMENT_LEFT, 249, 12, SOFT)


func draw_practice() -> void:
	draw_rect(Rect2(330, 655, 620, 50), Color("#101728"))
	draw_string(BOLD, Vector2(341, 676), "Treffer → %s für Finisher      Unten + Angriff für Beinfeger" % keyboard.caption(0, 4),
		HORIZONTAL_ALIGNMENT_CENTER, 598, 15, PAPER)
	draw_string(TEXT, Vector2(341, 696), "R  Reset      F2  Gegner      Esc / Start  Moves und Optionen",
		HORIZONTAL_ALIGNMENT_CENTER, 598, 14, SOFT)


func draw_lesson() -> void:
	var step := bout.tutorial_step
	var text_rect := Rect2(51, 132, 580, 108)
	draw_rect(Rect2(text_rect.position+Vector2(5, 6), text_rect.size), Color(0.05, 0.075, 0.13, .46))
	draw_rect(text_rect, PAPER)
	draw_colored_polygon(PackedVector2Array([Vector2(557,240), Vector2(581,240), Vector2(590,259)]), PAPER)
	draw_string(BOLD, Vector2(71, 159), "HERR HAIDENTHALER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#62566b"))
	draw_string(BOLD, Vector2(71, 196), FAKE_LINES[step], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, NIGHT)
	if bout.lesson_time > 0.64 or step == 5:
		draw_rect(Rect2(51, 628, 1178, 62), Color(0.065, 0.10, 0.17, 0.96))
		draw_rect(Rect2(51, 628, 4, 62), MINT)
		var heading := "TURNSAAL-TAFEL  /  " + LESSONS[step].to_upper() if step < 5 else "TURNSAAL-TAFEL"
		draw_string(BOLD, Vector2(72, 653), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MINT)
		var instruction := PAD_LINES[step] if not Input.get_connected_joypads().is_empty() else keyboard_lesson(step)
		draw_string(TEXT, Vector2(72, 676), instruction, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, PAPER)


func keyboard_lesson(step: int) -> String:
	match step:
		0:
			return "Laufe mit %s oder %s ein Stück zur Seite." % [keyboard.caption(0, 0), keyboard.caption(0, 1)]
		1:
			return "Springe mit %s. In der Luft geht ein zweiter Sprung." % keyboard.caption(0, 2)
		2:
			return "Geh nah an die Zielscheibe rechts und drück %s." % keyboard.caption(0, 3)
		3:
			return "Drück %s für die Spezialfähigkeit deiner Figur." % keyboard.caption(0, 4)
		4:
			return "Weiche mit %s aus. Am Boden lädt die Rolle wieder auf." % keyboard.caption(0, 5)
	return "Geschafft! Du hast alle Übungen abgeschlossen."


func draw_countdown() -> void:
	var counter := str(ceili(bout.starts_in)) if bout.starts_in > 0.45 else "LOS!"
	draw_rect(Rect2(515, 235, 250, 116), Color(0.055, 0.082, 0.14, 0.87))
	draw_line(Vector2(515, 235), Vector2(765, 235), MINT, 3)
	draw_string(DISPLAY, Vector2(535, 318), counter, HORIZONTAL_ALIGNMENT_CENTER, 210, 72, PAPER)
