extends Node

var peer: ENetMultiplayerPeer
var player_prefab : PackedScene
var peer_alias: Dictionary[int, String]

signal on_peer_connected(player_id: int)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_network_peer_connected)

func _exit_tree() -> void:
	disconnect_peer()

func disconnect_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func create_server(port: int, max_clients: int) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_clients)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	
	return error;


func join_server(ip: String, port: int) -> Error: 
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
	
	return error

func _on_network_peer_connected(id):
	print("Gooober connected: {id}, i am: {my_id}".format({"id": id, "my_id": multiplayer.get_unique_id()}))
	on_peer_connected.emit(id)
	

func print_net(string: String) -> void:
	if multiplayer.has_multiplayer_peer():
		print("(Peer " + str(multiplayer.get_unique_id()) + ") " + string)
	else:
		print("(No Multiplayer Connection) " + string)
