extends Node

@export var player_scene: PackedScene

func _ready() -> void:
	if multiplayer.is_server():
		print("PlayerSpawner started on Server")
		MultiplayerManager.on_peer_connected.connect(_on_peer_connected)
		spawn_player(1)

func _on_peer_connected(id:int):
	print("Server spawning PlayerPrefab")
	spawn_player(id)
	

func spawn_player(id:int):
	var player_instance = player_scene.instantiate()
	player_instance.set_multiplayer_authority(id)
	add_child(player_instance)
