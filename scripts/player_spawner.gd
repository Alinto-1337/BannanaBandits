extends Node;
class_name PlayerSpawner;

@export var player_scene: PackedScene;
@export var spectator_scene: PackedScene;
@export var player_root: PackedScene;
@export var start_player_state: PlayerState;

var player_roots: Dictionary[int, Node];
var player_states: Dictionary[int, PlayerState];
var spawned_player_states: Dictionary[int, PlayerState] ;

var spawnpoints_this_match: Array[Node];
var spawnpoints_used_flagged: Array[bool];

enum PlayerState {
	Spectator,
	Living
}

func _ready() -> void:
	
	DebugView.set_value("your_peer_id", str(multiplayer.get_unique_id()));
	if multiplayer.is_server():
		MultiplayerManager.on_peer_connected.connect(_on_peer_connected);
		GameController.instance.match_started.connect(_on_match_started);
		GameController.instance.match_ended.connect(_on_match_ended);
		_spawn_unspawned_player_roots();
		set_player_state(1, start_player_state);
		


#var _s: PlayerState = PlayerState.Spectator;
#func _process(delta: float) -> void:
	#
	#if not Input.is_action_just_pressed("debug_f1"): return;
	#if _s == PlayerState.Spectator:
		#set_all_players_state(PlayerState.Living)
	#else:
		#set_all_players_state(PlayerState.Spectator)

func _on_peer_connected(_id:int):
	_spawn_unspawned_player_roots();
	set_player_state(_id, start_player_state);

func _on_match_started():
	spawnpoints_this_match = get_tree().get_nodes_in_group("SpawnPoints")
	spawnpoints_used_flagged.resize(spawnpoints_this_match.size())
	spawnpoints_used_flagged.fill(false)
	set_all_players_state(PlayerState.Living);

func _on_match_ended():
	set_all_players_state(PlayerState.Spectator)

func set_all_players_state(state: PlayerState):
	for peer_id in _get_multiplayer_peer_id_list():
		set_player_state(peer_id, state);

func set_player_state(peer_id: int, state: PlayerState):
	if state == player_states.get(peer_id):
		print("trying to set player {id} to {state} but it is already {state}".format({ "state": str(state), "id": peer_id }));
		return;
	
	## must be a new state 
	player_states[peer_id] = state;
	_clear_player_root(peer_id);
	_spawn_player(peer_id);

func _spawn_unspawned_player_roots():
	for peer_id in _get_multiplayer_peer_id_list():
		if player_roots.keys().has(peer_id): 
			return;
		
		var new_root: Node = player_root.instantiate();
		new_root.name = "root_{id}".format({"id": peer_id});
		add_child(new_root);
		player_roots.set(peer_id, new_root);

func _clear_all_players_root():
	for peer_id in _get_multiplayer_peer_id_list():
		_clear_player_root(peer_id);

func _clear_player_root(peer_id: int): 
	if not multiplayer.is_server(): 
		return;
	
	for child in player_roots.get(peer_id).get_children():
		if child is MultiplayerSpawner: continue;
		child.queue_free();

func _spawn_player(peer_id: int):
	if player_states[peer_id] == PlayerState.Living:
		_spawn_living_player(peer_id);
	else:
		_spawn_spectator_player(peer_id);

func _spawn_spectator_player(peer_id: int):
	var player_instance = spectator_scene.instantiate() as SpectatorPlayer3D
	player_instance.name = "s"+str(peer_id);
	player_roots.get(peer_id).add_child(player_instance, true)

func _spawn_living_player(peer_id: int):
	
	var player_instance = player_scene.instantiate() as Player3D
	player_instance.name = "l"+str(peer_id);
	
	if spawnpoints_this_match.size() >= _get_multiplayer_peer_id_list().size():
		for i in spawnpoints_this_match.size():
			if spawnpoints_used_flagged[i]:
				continue
			var point = spawnpoints_this_match[i]
			if point == null:
				continue
			print("Spawning Living player at spawnpoint: " + str(point.position));
			player_instance.global_position = point.global_position
			spawnpoints_used_flagged[i] = true
			break
	
	player_roots.get(peer_id).add_child(player_instance, true)

func get_players_with_state(state: PlayerState) -> Array[int]:
	var list: Array[int];
	for peer_id in _get_multiplayer_peer_id_list():
		if player_states.get(peer_id) == state:
			list.append(peer_id);
	
	return list;

func _get_multiplayer_peer_id_list() -> PackedInt32Array:
	var list = multiplayer.get_peers();
	list.append(1);
	return list

func _peer_get_multiplayer_peer_id_list():
	print(multiplayer.get_peers())
