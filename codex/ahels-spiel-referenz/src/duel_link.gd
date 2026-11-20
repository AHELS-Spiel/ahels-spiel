class_name DuelLink
extends Node

signal lobby_updated
signal match_started(stage_index: int, one: int, two: int)
signal state_received(state: Dictionary)
signal connection_lost(message: String)

const VERSION := 2
const DEFAULT_PORT := 24738
const WAIT_SECONDS := 12.0

var peer: ENetMultiplayerPeer
var hosting := false
var local_fighter := 0
var guest := 0
var guest_fighter := -1
var round_id := 0
var remote_held := 0
var remote_edges := 0
var status := ""
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
		status = "Hosten fehlgeschlagen. Ist UDP-Port %s schon belegt?" % port
		lobby_updated.emit()
		return error
	peer = socket
	hosting = true
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
	status = "Verbinde mit %s · UDP %d …" % [address, port]
	waiting = WAIT_SECONDS
	multiplayer.multiplayer_peer = socket
	lobby_updated.emit()
	return OK


func close() -> void:
	waiting = 0.0
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
		status = "Verbunden. Warte auf die Figurenwahl …"
		lobby_updated.emit()


func on_peer_disconnected(id: int) -> void:
	if hosting and id == guest:
		guest = 0
		guest_fighter = -1
		remote_held = 0
		remote_edges = 0
		status = "Die zweite Person hat die Verbindung getrennt."
		connection_lost.emit(status)
		lobby_updated.emit()


func on_connected() -> void:
	if peer == null or hosting:
		return
	waiting = 0.0
	status = "Verbunden. Die hostende Person startet die Runde."
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
	guest_fighter = fighter
	status = "Beide verbunden. Die Runde kann starten."
	lobby_updated.emit()


@rpc("authority", "call_remote", "reliable")
func reject() -> void:
	close()
	status = "Andere Spielversion. Beide brauchen dieselbe Version."
	lobby_updated.emit()


func can_start() -> bool:
	return hosting and guest != 0 and guest_fighter >= 0


func start_round(stage_index: int) -> void:
	if not can_start():
		return
	round_id += 1
	remote_edges = 0
	remote_held = 0
	last_input_time = Time.get_ticks_msec()
	open_round.rpc_id(guest, round_id, stage_index, local_fighter, guest_fighter)
	match_started.emit(stage_index, local_fighter, guest_fighter)


@rpc("authority", "call_remote", "reliable")
func open_round(serial: int, stage_index: int, one: int, two: int) -> void:
	if hosting or serial <= round_id or stage_index < 1 or stage_index > 3:
		return
	if one < 0 or one >= ArenaCatalog.STUDENTS or two < 0 or two >= ArenaCatalog.STUDENTS:
		return
	round_id = serial
	match_started.emit(stage_index, one, two)


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
	if can_start():
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
