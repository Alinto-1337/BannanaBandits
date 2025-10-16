extends Node3D

var match_scores : Array[Dictionary] 
var current_match_index : int = 0

var is_match_active : bool = false

signal match_scores_changed

func _ready() -> void:
	MultiplayerManager.on_peer_connected.connect(on_peer_connected)

func on_peer_connected(_id : int):
	
	pass

func end_match():
	is_match_active = false
	pass

func start_match():
	is_match_active = true
	current_match_index += 1
	
	# update match scores dict
	pass

func get_current_match_scores():
	return match_scores.get(current_match_index)
	
