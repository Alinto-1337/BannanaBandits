extends Node3D;
class_name GameController

static var instance: GameController;

@export var player_spawner: PlayerSpawner;
@export var level_spawner: LevelSpawner;

@export_group("Game Rules")
@export var max_health: int
@export var gun_damage: Dictionary[String, int]

var match_scores : Array[Dictionary];
var current_match_index : int = 0;
var player_healths: Dictionary[int, int];
var dead_players: Array[int]

var is_match_active : bool = false;

signal match_scores_changed;
signal my_health_updated(health: int);
signal player_healths_updated(player_healths: Dictionary[int, int]);

signal match_ended;
signal match_started;

func _ready() -> void:
	NetworkManager.peer_connected.connect(on_peer_connected);
	instance = self;

func _process(delta: float) -> void:
	
	if is_match_active and Input.is_action_just_pressed("debug_f2"):
		end_match()
		

func on_peer_connected(_id : int):
	
	pass

func end_match():
	is_match_active = false
	
	match_ended.emit()


func start_match():
	match_started.emit()
	is_match_active = true
	current_match_index += 1
	server_set_all_players_health(max_health);



func get_current_match_scores():
	return match_scores.get(current_match_index)

#region Health_Management

func server_register_damage_to_peer(peer_id: int, gun: String):
	if not multiplayer.is_server(): return;
	if not player_healths.has(peer_id) or not gun_damage.has(gun): return
	if player_healths.get(peer_id) - gun_damage.get(gun) < 1:
		player_spawner.set_player_state(peer_id, PlayerSpawner.PlayerState.Spectator)
		dead_players.append(peer_id);
		if _get_multiplayer_peer_id_list().size() - dead_players.size() == 1:
			end_match();
	
	server_set_player_health(peer_id, player_healths.get(peer_id) - gun_damage.get(gun))

func server_set_all_players_health(health: int) -> void:
	if not multiplayer.is_server(): return;
	player_healths.clear();
	for peer_id in _get_multiplayer_peer_id_list():
		player_healths.set(peer_id, health);
	
	peer_health_changed.rpc(health);
	peer_all_player_health_update.rpc(player_healths);

func server_set_player_health(peer_id: int, health: int) -> void:
	if not multiplayer.is_server(): return;
	print("server updating health for: {id}".format({"id": peer_id}))
	
	player_healths.set(peer_id, health); # record change
	
	# To obscure other players healths from each other, never tell a peer other peers healths. 
	# The only one who needs to know if a players health is changed is the server, spectators and that player
	for spectator_ids in player_spawner.get_players_with_state(PlayerSpawner.PlayerState.Spectator):
		peer_all_player_health_update.rpc_id(spectator_ids, player_healths)
	
	peer_health_changed.rpc_id(peer_id, health); # tell the affected peer

@rpc("authority", "call_local", "reliable")
func peer_health_changed(new_health: int) -> void:
	
	DebugView.set_value("my_health", new_health)
	
	my_health_updated.emit(new_health) 

@rpc("authority", "call_local", "reliable")
func peer_all_player_health_update(updated_healths: Dictionary[int, int]) -> void:
	
	player_healths_updated.emit(updated_healths)

#endregion

func _get_multiplayer_peer_id_list() -> PackedInt32Array:
	var list = multiplayer.get_peers();
	list.push_back(1);
	return list
