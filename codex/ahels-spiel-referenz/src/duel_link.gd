class_name DuelLink
extends Node

signal lobby_updated
signal match_started(stage_index: int, one: int, two: int)
signal state_received(state: Dictionary)
signal connection_lost(message: String)

const VERSION := 4
const DEFAULT_PORT := 24738
const WAIT_SECONDS := 12.0

var peer: ENetMultiplayerPeer
var arena_ids := PackedStringArray()
var preview_arena := 1
var preview_host := -1
var rematch_requested := false
var ready_sent := false
var hosting := false
var local_fighter := 0
var guest := 0
var guest_fighter := -1
var round_id := 0
var remote_held := 0
var remote_edges := 0
var status := ""
var phase := "GETRENNT"
var waiting := 0.0
var last_input_time := 0


func _ready() -> void:
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connected_to_server.connect(on_connected)
	multiplayer.connection_failed.connect(on_failure)
	multiplayer.server_disconnected.connect(on_server_left)


func _process(delta: float) -> void:
	if waiting <= 0.0:
		return
	waiting -= delta
	if waiting <= 0.0:
		on_failure()


func listen(port: int, fighter: int) -> Error:
	close()
	local_fighter = fighter
	var socket := ENetMultiplayerPeer.new()
	var error := socket.create_server(port, 1, 3)
	if error != OK:
		phase = "GETRENNT"
		status = "Hosten fehlgeschlagen. Ist UDP-Port %s schon belegt?" % port
		lobby_updated.emit()
		return error
	peer = socket
	hosting = true
	phase = "WARTET"
	status = "Warte auf eine zweite Person · UDP %d" % port
	multiplayer.multiplayer_peer = socket
	lobby_updated.emit()
	return OK


func join(address: String, port: int, fighter: int) -> Error:
	close()
	local_fighter = fighter
	var socket := ENetMultiplayerPeer.new()
	var error := socket.create_client(address, port, 3)
	if error != OK:
		status = "Verbindung fehlgeschlagen. Prüfe Adresse und Port."
		lobby_updated.emit()
		return error
	peer = socket
	phase = "VERBINDET"
	status = "Verbinde mit %s · UDP %d …" % [address, port]
	waiting = WAIT_SECONDS
	multiplayer.multiplayer_peer = socket
	lobby_updated.emit()
	return OK


func close() -> void:
	waiting = 0.0
	phase = "GETRENNT"
	preview_host = -1
	rematch_requested = false
	ready_sent = false
	round_id = 0
	guest = 0
	guest_fighter = -1
	remote_held = 0
	remote_edges = 0
	hosting = false
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		peer = null
	status = ""


func on_peer_connected(id: int) -> void:
	if hosting and peer != null:
		guest = id
		phase = "VERBUNDEN"
		status = "Verbunden. Warte auf die Figurenwahl …"
		lobby_updated.emit()


func on_peer_disconnected(id: int) -> void:
	if hosting and id == guest:
		guest = 0
		guest_fighter = -1
		remote_held = 0
		remote_edges = 0
		rematch_requested = false
		phase = "WARTET"
		status = "Die zweite Person hat die Verbindung getrennt."
		connection_lost.emit(status)
		lobby_updated.emit()


func on_connected() -> void:
	if peer == null or hosting:
		return
	phase = "VERBUNDEN"
	status = "Spielversion wird geprüft …"
	announce.rpc_id(1, VERSION, local_fighter)
	lobby_updated.emit()


func on_failure() -> void:
	if peer == null or hosting:
		return
	close()
	status = "Kein Host erreichbar. Prüfe Adresse, UDP-Port und Firewall."
	lobby_updated.emit()


func on_server_left() -> void:
	if peer == null or hosting:
		return
	close()
	status = "Die Verbindung zum Host wurde getrennt."
	connection_lost.emit(status)
	lobby_updated.emit()


@rpc("any_peer", "call_remote", "reliable")
func announce(version: int, fighter: int) -> void:
	if not hosting or multiplayer.get_remote_sender_id() != guest:
		return
	if version != VERSION or fighter < 0 or fighter >= ArenaCatalog.STUDENTS:
		status = "Andere Spielversion. Beide brauchen dieselbe Version."
		lobby_updated.emit()
		reject.rpc_id(guest)
		return
	if guest_fighter != -1 and fighter != guest_fighter:
		return
	guest_fighter = fighter
	rematch_requested = true
	phase = "BEREIT"
	status = "Beide verbunden. Die Runde kann starten."
	send_preview()
	lobby_updated.emit()


@rpc("authority", "call_remote", "reliable")
func reject() -> void:
	close()
	status = "Andere Spielversion. Beide brauchen dieselbe Version."
	lobby_updated.emit()


func connected_guest() -> bool:
	return hosting and guest != 0 and guest_fighter >= 0


func can_start() -> bool:
	return connected_guest() and rematch_requested


func choose_arena(index: int) -> void:
	if valid_arena(index):
		preview_arena = index
		send_preview()


func send_preview() -> void:
	if connected_guest():
		open_round.rpc_id(guest, 0, arena_ids[preview_arena], local_fighter, guest_fighter)


func request_rematch() -> void:
	if peer == null or hosting or round_id == 0 or ready_sent:
		return
	ready_sent = true
	phase = "BEREIT"
	announce.rpc_id(1, VERSION, local_fighter)
	lobby_updated.emit()


func start_round(stage_index: int) -> void:
	if not can_start() or not valid_arena(stage_index):
		return
	round_id += 1
	preview_arena = stage_index
	phase = "SPIEL LÄUFT"
	rematch_requested = false
	remote_edges = 0
	remote_held = 0
	last_input_time = Time.get_ticks_msec()
	open_round.rpc_id(guest, round_id, arena_ids[stage_index], local_fighter, guest_fighter)
	match_started.emit(stage_index, local_fighter, guest_fighter)


@rpc("authority", "call_remote", "reliable")
func open_round(serial: int, arena_id: String, one: int, two: int) -> void:
	var stage_index := arena_ids.find(arena_id)
	if hosting or not valid_arena(stage_index):
		return
	if one < 0 or one >= ArenaCatalog.STUDENTS or two != local_fighter:
		return
	preview_arena = stage_index
	preview_host = one
	# Serial zero previews the matchup without clearing an active or completed round.
	if serial == 0:
		waiting = 0.0
		if round_id == 0:
			phase = "BEREIT"
			status = "Beide verbunden. Der Host startet die Runde."
			lobby_updated.emit()
	elif serial > round_id:
		round_id = serial
		ready_sent = false
		phase = "SPIEL LÄUFT"
		match_started.emit(stage_index, one, two)


func valid_arena(stage_index: int) -> bool:
	return stage_index >= 1 and stage_index < arena_ids.size()


func send_controls(held: int, pressed: int) -> void:
	if not hosting and peer != null and round_id > 0:
		move.rpc_id(1, round_id, held & (ArenaBout.LEFT | ArenaBout.RIGHT))
		if pressed != 0:
			act.rpc_id(1, round_id, pressed & ArenaBout.ACTIONS)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func move(serial: int, held: int) -> void:
	if hosting and serial == round_id and multiplayer.get_remote_sender_id() == guest:
		remote_held = held & (ArenaBout.LEFT | ArenaBout.RIGHT)
		last_input_time = Time.get_ticks_msec()


@rpc("any_peer", "call_remote", "reliable")
func act(serial: int, actions: int) -> void:
	if hosting and serial == round_id and multiplayer.get_remote_sender_id() == guest:
		remote_edges |= actions & ArenaBout.ACTIONS


func consume_controls() -> Vector2i:
	if Time.get_ticks_msec() - last_input_time > 900:
		remote_held = 0
	var input := Vector2i(remote_held, remote_edges)
	remote_edges = 0
	return input


func send_state(state: Dictionary) -> void:
	if connected_guest():
		sync_state.rpc_id(guest, round_id, state)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func sync_state(serial: int, state: Dictionary) -> void:
	if not hosting and serial == round_id and peer != null:
		state_received.emit(state)


static func lan_addresses() -> String:
	var list: Array[String] = []
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.contains(":") 				and not address.begins_with("127.") and not address.begins_with("169.254."):
			list.append(address)
	return ", ".join(list) if not list.is_empty() else "Keine IPv4-Adresse erkannt"
