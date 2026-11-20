extends SceneTree

var app: ArenaApp

func _initialize() -> void:
	call_deferred("run")


func tap(button: JoyButton) -> void:
	for state in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = state
		Input.parse_input_event(event)
		await process_frame
		await process_frame


func run() -> void:
	app = ArenaApp.new()
	root.add_child(app)
	await process_frame
	await tap(JOY_BUTTON_A)
	if app.screen != "select":
		push_error("A öffnet die Kampagne nicht.")
		quit(1)
		return
	for count in 5:
		await tap(JOY_BUTTON_DPAD_RIGHT)
	for count in 3:
		await tap(JOY_BUTTON_DPAD_DOWN)
	await tap(JOY_BUTTON_A)
	if app.selected.x != 23:
		push_error("Karte Simon nicht per Steuerkreuz erreicht: " + str(app.selected.x))
		quit(1)
		return
	await tap(JOY_BUTTON_B)
	if app.screen != "home":
		push_error("B öffnet das Hauptmenü nicht.")
		quit(1)
		return
	app.show_selection("versus")
	app.show_arena_picker()
	await tap(JOY_BUTTON_DPAD_RIGHT)
	await tap(JOY_BUTTON_DPAD_DOWN)
	await tap(JOY_BUTTON_A)
	if app.screen != "select" or app.catalog.arenas[app.stage_pick]["id"] != "aula":
		push_error("Controller konnte Aula nicht wählen.")
		quit(1)
		return
	app.start_versus()
	await tap(JOY_BUTTON_START)
	if not app.paused:
		push_error("Controller öffnet das Pausenmenü nicht.")
		quit(1)
		return
	await tap(JOY_BUTTON_B)
	if app.paused:
		push_error("B konnte das Match nicht fortsetzen.")
		quit(1)
		return
	print("OK Synthetischer Controller: Auswahl 24, Arena-Picker, Pause und Rückkehr.")
	app.queue_free()
	await process_frame
	quit()
