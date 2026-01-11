extends NetworkAdapter
class_name SteamP2PNetAdapter

const PACKET_READ_LIMIT: int = 32

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""

const _LOBBY_VISIBILITY_TO_LOBBY_TYPE = {
	NetworkManager.LobbyVisibility.PUBLIC: Steam.LobbyType.LOBBY_TYPE_PUBLIC,
	NetworkManager.LobbyVisibility.PRIVATE: Steam.LobbyType.LOBBY_TYPE_PRIVATE,
	NetworkManager.LobbyVisibility.FRIENDS_ONLY: Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY,
	NetworkManager.LobbyVisibility.INVITE_ONLY: Steam.LobbyType.LOBBY_TYPE_INVISIBLE,
}

func _ready() -> void:
	_initialize_steam()
	
	multiplayer_peer = SteamMultiplayerPeer.new()
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_persona_change)

func _process(delta: float) -> void:
	Steam.run_callbacks()

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby({ "lobby_id": int(these_arguments[1]) })

#region Steam Initialization

func _initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(480)
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()

#endregion

func create_lobby(lobby_visibility: NetworkManager.LobbyVisibility) -> void:
	if lobby_id != 0: return  # Already in a lobby
    
	var lobby_type: int = _LOBBY_VISIBILITY_TO_LOBBY_TYPE[lobby_visibility]
    
	# Create the lobby using low-level Steam API
	Steam.createLobby(lobby_type, NetworkManager.MAX_PLAYERS)

func join_lobby(join_info: Dictionary) -> void:
	assert(join_info.has("lobby_id"), "No lobby id provided.")
	
	lobby_id = join_info.get("lobby_id")
	print("Attempting to join lobby %s" % lobby_id)
	
	var result: Error = multiplayer_peer.connect_lobby(lobby_id)
	if result == OK:
		await multiplayer_peer.lobby_joined
		multiplayer.multiplayer_peer = multiplayer_peer
		lobby_joined.emit()
	else:
		push_error("Failed to join lobby. (Error code " + str(result) + ")")

func _on_peer_connected(peer_id: int) -> void:
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_disconnected.emit(peer_id)

func _on_server_disconnected() -> void:
	disconnect_from_lobby()

func _on_connected_to_server() -> void:
	NetworkManager.send_handshake.rpc_id(1, { "display_name": Steam.getPersonaName() })

func _add_lobby_members_to_peer() -> void:
	var member_count: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		    
		# Skip yourself (host)
		if member_steam_id == Steam.getSteamID():
			continue
		
		var err = multiplayer_peer.add_peer(member_steam_id)
		if err != OK:
			print("Failed to add peer %s: %s" % [member_steam_id, err])

#region SteamCallbacks

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect != 1:
		push_error("Lobby creation failed! Connect result: " + str(connect))
		return
	
	lobby_id = this_lobby_id
	print("Lobby created successfully: %s" % lobby_id)
	    
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.allowP2PPacketRelay(true)  # Important for fallback relay
	
	# Now initialize the multiplayer peer as HOST
	multiplayer_peer = SteamMultiplayerPeer.new()
	
	# Make this instance the host
	var err = multiplayer_peer.create_host()  # Or similar; check your version
	if err != OK:
		push_error("Failed to create host on SteamMultiplayerPeer: " + str(err))
		return
	
	multiplayer.multiplayer_peer = multiplayer_peer
	
	# Manually add existing lobby members (including yourself) as peers
	_add_lobby_members_to_peer()
	
	lobby_created.emit()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var fail_reason = _get_fail_reason(response)
		push_error("Failed to join lobby: " + fail_reason)
		return
	
	lobby_id = this_lobby_id
	print("Joined lobby: %s" % lobby_id)
	
	# Initialize peer as CLIENT
	multiplayer_peer = SteamMultiplayerPeer.new()
	
	# Usually connect to the lobby owner first as host
	var host_id: int = Steam.getLobbyOwner(lobby_id)
	var err = multiplayer_peer.create_client(host_id)  # Or add_peer(host_id) depending on version
	if err != OK:
		push_error("Failed to connect to host: " + str(err))
		return
	
	multiplayer.multiplayer_peer = multiplayer_peer
	
	# Add other members
	_add_lobby_members_to_peer()
	
	make_p2p_handshake()  # If you still need custom init
	lobby_joined.emit()

func _get_fail_reason(response: int) -> String:
	match response:
		Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: return "This lobby no longer exists."
		Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: return "You don't have permission to join this lobby."
		Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: return "The lobby is now full."
		Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: return "Uh... something unexpected happened!"
		Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: return "You are banned from this lobby."
		Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: return "You cannot join due to having a limited account."
		Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: return "This lobby is locked or disabled."
		Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: return "This lobby is community locked."
		Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: return "A user in the lobby has blocked you from joining."
		Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: return "A user you have blocked is in the lobby."
	return "Unknown error."

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	join_lobby({ "lobby_id": this_lobby_id })

func _on_lobby_chat_update():
	pass

func _on_lobby_data_update():
	pass

func _on_lobby_invite():
	pass

func _on_lobby_match_list():
	pass

func _on_lobby_message():
	pass

func _on_persona_change():
	pass

#endregion

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	# If needed, send a broadcast packet: send_p2p_packet(0, {"message": "handshake", "from": steam_id})
	# But with SteamMultiplayerPeer, peer connections should handle automatically via multiplayer signals

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
