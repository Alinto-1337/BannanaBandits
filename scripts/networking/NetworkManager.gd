extends Node

signal lobby_created()
signal lobby_joined()
signal lobby_disconnected()

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

signal handshake_accepted_server(peer_id: int, player_info: Dictionary)
signal handshake_denied_server(peer_id: int, response: Dictionary)

signal handshake_accepted_client(server_response: Dictionary)
signal handshake_denied_client(server_response: Dictionary)

signal player_registered(peer_id: int, player_info: Dictionary)
signal player_deregistered(peer_id: int)

signal ping_list_updated(ping_list: Dictionary)

enum AdapterType {
	DIRECT_P2P,
	STEAM_P2P,
}

enum LobbyVisibility {
	PUBLIC,
	PRIVATE,
	FRIENDS_ONLY,
	INVITE_ONLY,
}

enum HandshakeResult {
	SUCCESS,
	ERROR,
}

const MAX_PLAYERS = 16
const KICK_FORCE_DELAY = 0.5
const PING_INTERVAL = 2

const ADAPTER_TYPE: AdapterType = AdapterType.DIRECT_P2P;

var _current_adapter = null
var _ping_refresh_timer = null

var players: Dictionary[int, Dictionary] = {}



func _ready() -> void:
	
	_create_adapter(ADAPTER_TYPE);
	_ping_refresh_timer = Timer.new()
	_ping_refresh_timer.timeout.connect(refresh_ping_list)
	
	add_child(_ping_refresh_timer)
	
	_ping_refresh_timer.start(PING_INTERVAL)

#region Adapters

func _create_adapter(adapter_type: AdapterType) -> NetworkAdapter:
	if _current_adapter:
		await disconnect_from_lobby()
	
	if adapter_type == AdapterType.DIRECT_P2P:
		_current_adapter = DirectNetAdapter.new()
	elif adapter_type == AdapterType.STEAM_P2P:
		_current_adapter = SteamP2PNetAdapter.new()
	
	_current_adapter.lobby_created.connect(func():
		lobby_created.emit()
	)
	_current_adapter.lobby_joined.connect(func():
		lobby_joined.emit()
	)
	_current_adapter.lobby_disconnected.connect(func():
		lobby_disconnected.emit()
	)
	
	_current_adapter.peer_connected.connect(func(peer_id: int):
		peer_connected.emit(peer_id)
	)
	_current_adapter.peer_disconnected.connect(func(peer_id: int):
		deregister_player.rpc(peer_id)
		
		peer_disconnected.emit(peer_id)
	)
	
	add_child(_current_adapter)
	return _current_adapter

func get_adapter() -> NetworkAdapter:
	assert(_current_adapter, "No adapter has been created.")
	return _current_adapter

#endregion

#region Lobby Management

func create_lobby(lobby_visibility: LobbyVisibility) -> void:
	print_net("!!! [NetworkManager]: Starting new lobby...")
	
	await _current_adapter.create_lobby(lobby_visibility)
	
	register_player.rpc(1, { "display_name": "HOST" })
	
	print_net("!!! [NetworkManager]: Started new lobby!")

func join_lobby(join_info: Dictionary) -> void:
	print_net("!!! [NetworkManager]: Joining lobby...")
	print_net("! [NetworkManager]: Join info: " + str(join_info))
	
	await _current_adapter.join_lobby(join_info)

func disconnect_from_lobby() -> void:
	print_net("!!! [NetworkManager]: Disconnecting from lobby...")
	
	var adapter: NetworkAdapter = get_adapter()
	await adapter.disconnect_from_lobby()
	
	players.clear()
	
	print_net("!!! [NetworkManager]: Disconnected from lobby!")

func kick_from_lobby(peer_id: int, force: bool = false) -> void:
	print_net("!!! [NetworkManager]: Kicking peer " + str(peer_id) + " from lobby...")
	
	var adapter: NetworkAdapter = get_adapter()
	await adapter.kick_from_lobby(peer_id, force)
	
	deregister_player.rpc(peer_id)
	
	print_net("!!! [NetworkManager]: Kicked " + str(peer_id) + " from lobby!")

#endregion

#region Network Statistics

func refresh_ping_list() -> void:
	if multiplayer.multiplayer_peer and multiplayer.is_server():
		var ping_delays = {}
		
		for peer_id in players.keys():
			if peer_id == 1:
				ping_delays[peer_id] = float(0)
				continue
			
			var adapter: NetworkAdapter = get_adapter()
			var ping_result = await adapter.get_statistic(peer_id, ENetPacketPeer.PeerStatistic.PEER_ROUND_TRIP_TIME)
			ping_delays[peer_id] = ping_result
		
		ping_list_recieved.rpc(ping_delays)

@rpc("authority", "call_local", "reliable")
func ping_list_recieved(ping_list: Dictionary) -> void:
	for peer_id in ping_list.keys():
		var ping_delay = ping_list[peer_id]
		var matching_player = players.get(peer_id)
		if matching_player:
			matching_player["ping"] = ping_delay
	
	ping_list_updated.emit(ping_list)

#endregion

#region Handshake

@rpc("any_peer", "call_remote", "reliable")
func send_handshake(recieved_player_info: Dictionary) -> void:
	if multiplayer.is_server():
		var sender_peer_id = multiplayer.get_remote_sender_id()
		
		# Check if player is already in lobby
		if players.has(sender_peer_id):
			handshake_denied_server.emit(sender_peer_id, { "message": "Already connected." })
			handshake_response.rpc_id(sender_peer_id, false, { "message": "Already connected." })
			return
		
		var filtered_player_info = {}
		
		# Filter display_name
		if recieved_player_info.has("display_name") and typeof(recieved_player_info.display_name) == TYPE_STRING:
			filtered_player_info["display_name"] = recieved_player_info.display_name
		else:
			handshake_denied_server.emit(sender_peer_id, { "message": "Invalid display name." })
			handshake_response.rpc_id(sender_peer_id, false, { "message": "Invalid display name." })
			return
		
		handshake_accepted_server.emit(sender_peer_id, filtered_player_info)
		handshake_response.rpc_id(sender_peer_id, true, { "registered_players": NetworkManager.players })

@rpc("authority", "call_remote", "reliable")
func handshake_response(success: bool, response: Dictionary) -> void:
	if success:
		players = response.registered_players
		
		handshake_accepted_client.emit(response)
	else:
		handshake_denied_client.emit(response)

#endregion

#region Player Registration

@rpc("authority", "call_local", "reliable")
func register_player(peer_id: int, player_info: Dictionary) -> void:
	players[peer_id] = player_info
	player_registered.emit(peer_id, player_info)
	
	print_net("! [NetworkManager]: Registered player with peer id \"" + str(peer_id) + "\".")

@rpc("authority", "call_local", "reliable")
func deregister_player(peer_id: int) -> void:
	players.erase(peer_id)
	player_deregistered.emit(peer_id)
	
	print_net("! [NetworkManager]: Deregistered player with peer id \"" + str(peer_id) + "\".")

#endregion

#region Debug Utils

func print_net(string: String) -> void:
	if multiplayer.has_multiplayer_peer():
		print("(Peer " + str(multiplayer.get_unique_id()) + ") " + string)
	else:
		print("(No Multiplayer Connection) " + string)

#endregion
