extends Node3D;
class_name LevelSpawner

@export var levels: Dictionary[String, PackedScene];

var _current_level_id: int
var _currently_spawned_level: Node3D

func _ready() -> void:
	if not multiplayer.is_server(): return;
	_current_level_id = 999;
	switch_level(0);
	
	pass 

func switch_level(level_id: int):
	if _current_level_id == level_id or not multiplayer.is_server(): return;
	if _currently_spawned_level != null: peers_murder_current_level.rpc();
	
	if levels.keys()[level_id] == null: 
		print ("trying to switch to level with invalid id: {id}".format({"id": level_id}));
		return;
	
	DebugView.set_value("Level ID", level_id)
	
	_current_level_id = level_id;
	_currently_spawned_level = levels[levels.keys()[level_id]].instantiate();
	_currently_spawned_level.name = ("level {lvl}".format({"lvl": levels.get(levels.keys()[level_id])}));
	add_child(_currently_spawned_level);
	
	pass

@rpc("call_local")
func peers_murder_current_level(): # Fusk lösning
	for child in get_children():
		child.queue_free();
