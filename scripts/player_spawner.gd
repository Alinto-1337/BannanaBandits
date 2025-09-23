extends Node

@export var player_scene: PackedScene

@export var peer_id_label: Label

func _ready() -> void:
	peer_id_label.text = str(multiplayer.get_unique_id())
	if multiplayer.is_server():
		print("PlayerSpawner started on Server")
		MultiplayerManager.on_peer_connected.connect(_on_peer_connected)
		spawn_player(1)

func _on_peer_connected(id:int):
	spawn_player(id)

@rpc("reliable", "authority", "call_local")
func spawn_player(id:int):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	if multiplayer.is_server():
		player_instance.player_id = id
	add_child(player_instance, true)
