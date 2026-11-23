class_name DuelLink
extends Node

signal lobby_updated
signal match_started(stage_index: int, lineup: PackedInt32Array, partner: int)
signal state_received(state: Dictionary)
signal connection_lost(message: String)

const VERSION := 7
const DEFAULT_PORT := 24738
const MAX_PLAYERS := 4
const WAIT_SECONDS := 12.0

var peer: ENetMultiplayerPeer
var arena_ids := PackedStringArray()
var preview_arena := 1
var preview_fighters := PackedInt32Array()
var ready_sent := false
var hosting := false
var capacity := 2
var team_partner := 0
var local_fighter := 0
var local_slot := 1
var seats: Array[int] = []
var guests: Dictionary[int, Dictionary] = {}
var round_id := 0
var round_active := false
var round_finished := false
var status := ""
var phase := "GETRENNT"
var waiting := 0.0


func _ready() -> void:
	(multiplayer as SceneMultiplayer).server_relay = false
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


func listen(port: int, fighter: int, player_count: int = 2, partner: int = 0) -> Error:
	close()
	local_fighter = fighter
	capacity = clampi(player_count, 2, MAX_PLAYERS)
	team_partner = clampi(partner, 0, 3) if capacity == 4 else 0
	var socket := ENetMultiplayerPeer.new()
	var error := socket.create_server(port, capacity - 1, 3)
	if error != OK:
		status = "Hosten fehlgeschlagen. Ist UDP-Port %s schon belegt?" % port
		lobby_updated.emit()
		return error
	peer = socket
	hosting = true
	local_slot = 0
	status = "UDP %d" % port
	multiplayer.multiplayer_peer = socket
	send_preview()
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
	preview_fighters.clear()
	team_partner = 0
	ready_sent = false
	round_id = 0
	round_active = false
	round_finished = false
	local_slot = 1
	seats.clear()
	guests.clear()
	hosting = false
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		peer = null
	status = ""


func on_peer_connected(id: int) -> void:
	if not hosting or peer == null:
		return
	if round_active or seats.size() >= capacity - 1:
		peer.disconnect_peer(id)
		return
	seats.append(id)
	guests[id] = {"fighter": -1, "ready": false, "held": 0, "edges": 0, "last_input": 0}


func on_peer_disconnected(id: int) -> void:
	if not hosting or not guests.has(id):
		return
	seats.erase(id)
	guests.erase(id)
	var abandoned := round_active
	round_active = false
	round_finished = false
	if abandoned:
		for visitor in guests.values():
			visitor["ready"] = visitor["fighter"] >= 0
	status = "Eine Person hat die Verbindung getrennt."
	send_preview(-1 if abandoned else 0)
	if abandoned:
		connection_lost.emit(status)


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
	status = "Kein Host erreichbar. Prüfe Adresse, UDP-Port und freie Plätze."
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
	var id := multiplayer.get_remote_sender_id()
	if not hosting or not guests.has(id):
		return
	if version != VERSION or fighter < 0 or fighter >= ArenaCatalog.STUDENTS:
		reject.rpc_id(id)
		return
	var visitor := guests[id]
	if round_active and (not round_finished or fighter != visitor["fighter"]):
		return
	visitor["fighter"] = fighter
	visitor["ready"] = true
	if round_active:
		lobby_updated.emit()
	else:
		status = ""
		send_preview()


@rpc("authority", "call_remote", "reliable")
func reject() -> void:
	close()
	status = "Andere Spielversion. Alle brauchen dieselbe Version."
	lobby_updated.emit()


func can_start() -> bool:
	if not hosting or seats.size() != capacity - 1 or (round_active and not round_finished):
		return false
	for visitor in guests.values():
		if not visitor["ready"]:
			return false
	return true


func choose_arena(index: int) -> void:
	if valid_arena(index):
		preview_arena = index
		if hosting and not round_active:
			send_preview()


func choose_team_partner(partner: int) -> void:
	if hosting and not round_active and capacity == 4:
		team_partner = clampi(partner, 0, 3)
		send_preview()


func send_preview(serial: int = 0) -> void:
	var lineup := PackedInt32Array([local_fighter])
	var registered: Array[int] = []
	for id in seats:
		var fighter: int = guests[id]["fighter"]
		if fighter >= 0:
			registered.append(id)
			lineup.append(fighter)
	preview_fighters = lineup
	phase = "BEREIT" if can_start() else "WARTET"
	for i in registered.size():
		if guest_connected(registered[i]):
			open_round.rpc_id(registered[i], serial, arena_ids[preview_arena], lineup,
				Vector3i(i + 1, capacity, team_partner))
	lobby_updated.emit()


func request_rematch() -> void:
	if peer == null or hosting or not round_active or ready_sent:
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
	round_active = true
	round_finished = false
	var lineup := PackedInt32Array([local_fighter])
	for id in seats:
		var visitor := guests[id]
		lineup.append(visitor["fighter"])
		visitor["ready"] = false
		visitor["edges"] = 0
		visitor["held"] = 0
	preview_fighters = lineup
	for i in seats.size():
		if guest_connected(seats[i]):
			open_round.rpc_id(seats[i], round_id, arena_ids[stage_index], lineup,
				Vector3i(i + 1, capacity, team_partner))
	match_started.emit(stage_index, lineup, team_partner)


@rpc("authority", "call_remote", "reliable")
func open_round(serial: int, arena_id: String, lineup: PackedInt32Array, settings: Vector3i) -> void:
	var stage_index := arena_ids.find(arena_id)
	if hosting or not valid_arena(stage_index) or settings.y < 2 or settings.y > MAX_PLAYERS:
		return
	if settings.z < 0 or settings.z > 3 or (settings.z != 0 and settings.y != 4):
		return
	if lineup.size() > settings.y or settings.x < 1 or settings.x >= lineup.size() or lineup[settings.x] != local_fighter:
		return
	for id in lineup:
		if id < 0 or id >= ArenaCatalog.STUDENTS:
			return
	if serial > 0 and (serial <= round_id or lineup.size() != settings.y):
		return
	if serial == 0 and round_active:
		return
	capacity = settings.y
	team_partner = settings.z
	local_slot = settings.x
	preview_arena = stage_index
	preview_fighters = lineup
	waiting = 0.0
	if serial <= 0:
		round_active = false
		ready_sent = false
		phase = "BEREIT" if lineup.size() == capacity else "WARTET"
		status = "Der Host startet die Runde." if lineup.size() == capacity else "Warte auf weitere Personen."
		if serial < 0:
			status = "Eine Person hat das Spiel verlassen."
		if serial < 0:
			connection_lost.emit(status)
		lobby_updated.emit()
	else:
		round_id = serial
		round_active = true
		ready_sent = false
		phase = "SPIEL LÄUFT"
		match_started.emit(stage_index, lineup, team_partner)


func valid_arena(stage_index: int) -> bool:
	return stage_index >= 1 and stage_index < arena_ids.size()


func send_controls(held: int, pressed: int) -> void:
	if not hosting and peer != null and round_active:
		move.rpc_id(1, round_id, held & ArenaBout.HELD_ACTIONS)
		if pressed != 0:
			act.rpc_id(1, round_id, pressed & ArenaBout.ACTIONS)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func move(serial: int, held: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if hosting and round_active and not round_finished and serial == round_id and guests.has(id):
		var visitor := guests[id]
		visitor["held"] = held & ArenaBout.HELD_ACTIONS
		visitor["last_input"] = Time.get_ticks_msec()


@rpc("any_peer", "call_remote", "reliable")
func act(serial: int, actions: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if hosting and round_active and not round_finished and serial == round_id and guests.has(id):
		var visitor := guests[id]
		visitor["edges"] |= actions & ArenaBout.ACTIONS


func consume_controls() -> Array[Vector2i]:
	var controls: Array[Vector2i] = []
	var now := Time.get_ticks_msec()
	for id in seats:
		var visitor := guests[id]
		var held: int = visitor["held"] if now - int(visitor["last_input"]) <= 900 else 0
		controls.append(Vector2i(held, visitor["edges"]))
		visitor["edges"] = 0
	return controls


func send_state(state: Dictionary) -> void:
	if not round_active:
		return
	round_finished = state["w"] != ArenaBout.ONGOING
	# Four fighters and their effects would otherwise often exceed the ENet MTU.
	var packet := var_to_bytes(state).compress(FileAccess.COMPRESSION_DEFLATE)
	for id in seats:
		if guest_connected(id):
			sync_state.rpc_id(id, round_id, packet)


func guest_connected(id: int) -> bool:
	var connection := peer.get_peer(id)
	return connection != null and connection.get_state() == ENetPacketPeer.STATE_CONNECTED


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func sync_state(serial: int, packet: PackedByteArray) -> void:
	if not hosting and round_active and serial == round_id and peer != null:
		var raw := packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE)
		if not raw.is_empty():
			var state: Variant = bytes_to_var(raw)
			if state is Dictionary and state.get("f") is Array and state["f"].size() == preview_fighters.size():
				state_received.emit(state)


static func lan_addresses() -> String:
	var list: Array[String] = []
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.contains(":") and not address.begins_with("127.") and not address.begins_with("169.254."):
			list.append(address)
	return ", ".join(list) if not list.is_empty() else "Keine IPv4-Adresse erkannt"
