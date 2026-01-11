extends Node;
class_name NetworkAdapter;

signal lobby_created()
signal lobby_joined()
signal lobby_disconnected()

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var multiplayer_peer = null

func create_lobby(lobby_visibility: NetworkManager.LobbyVisibility):
	assert("Use of abstract function");

func join_lobby(join_info: Dictionary):
	assert("Use of abstract function");

func disconnect_from_lobby() -> void:
	multiplayer_peer.close()
	multiplayer.set_multiplayer_peer(null)
	
	lobby_disconnected.emit()

func kick_from_lobby(_peer_id: int, _force: bool = false) -> void:
	assert(false, "Using abstract kick_peer()")

func get_statistic(_peer_id: int, _peer_statistic: ENetPacketPeer.PeerStatistic) -> float:
	assert(false, "Using abstract get_statistic()")
	
	return float(0)
