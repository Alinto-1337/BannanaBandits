extends NetworkAdapter
class_name DirectNetAdapter


const PORT = 7778

func _ready() -> void:
	multiplayer_peer = ENetMultiplayerPeer.new()
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func _on_server_disconnected() -> void:
	disconnect_from_lobby()

func _on_connected_to_server() -> void:
	NetworkManager.send_handshake.rpc_id(1, { "display_name": "CLIENT" })

func create_lobby(lobby_visibility: NetworkManager.LobbyVisibility) -> void:
	var result: Error = await multiplayer_peer.create_server(PORT, NetworkManager.MAX_PLAYERS - 1)
	if result == OK:
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		
		lobby_created.emit()
	else:
		push_error("Failed to create lobby. (Error code " + str(result) + ")")

func join_lobby(join_info: Dictionary) -> void:
	assert(join_info.has("address"), "No address provided!")
	#assert(join_info.has("port"), "No port provided!")
	
	var result: Error = await multiplayer_peer.create_client(join_info.address, PORT)
	if result == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		
		await multiplayer.connected_to_server
		
		lobby_joined.emit()
	else:
		push_error("Failed to join lobby. (Error code " + str(result) + ")")

func disconnect_from_lobby() -> void:
	super.disconnect_from_lobby()

func kick_from_lobby(peer_id: int, force: bool = false) -> void:
	if multiplayer.is_server() and multiplayer.get_peers().has(peer_id):
		multiplayer_peer.disconnect_peer(peer_id, force)

func get_statistic(peer_id: int, peer_statistic: ENetPacketPeer.PeerStatistic) -> float:
	var packet_peer: ENetPacketPeer = multiplayer_peer.get_peer(peer_id)
	if packet_peer:
		return packet_peer.get_statistic(peer_statistic)
	
	return float(0)
