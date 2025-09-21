extends Node

var peer: ENetMultiplayerPeer


func _exit_tree() -> void:
	disconnect_peer()

func disconnect_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func create_server(port: int, max_clients: int):
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, max_clients)
	multiplayer.multiplayer_peer = peer

func join_server(ip: String, port: int): 
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
