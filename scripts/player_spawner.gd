extends Node

@export var player_scene: PackedScene

@export var peer_id_label: Label

var spawned_players: Dictionary[int, Node3D]

func _ready() -> void:
	peer_id_label.text = str(multiplayer.get_unique_id())
	MultiplayerManager.on_peer_connected.connect(_on_peer_connected)
	spawn_missing_players()

func _on_peer_connected(_id:int):
	spawn_missing_players()

@rpc("reliable", "authority", "call_local")
func spawn_missing_players():
	
	var peers = multiplayer.get_peers()
	peers.append(multiplayer.get_unique_id())
	
	print(peers)
	for peer in peers:
		if not spawned_players.has(peer):
			spawn_player(peer)


func spawn_player(id: int):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	player_instance.player_id = id
	add_child(player_instance, true)
	
	spawned_players.set(id, player_instance)
