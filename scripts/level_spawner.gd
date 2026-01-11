extends Node3D;
class_name LevelSpawner

@export var level_select_ui: PackedScene
@export var levels: Dictionary[String, PackedScene];

var _current_level_id: int
var _currently_spawned_level: Node3D
var spawned_ui: Control;

func _ready() -> void:
	if not multiplayer.is_server(): return;
	_current_level_id = 999;
	switch_level(0);
	
	GameController.instance.match_started.connect(_on_match_started)
	GameController.instance.match_ended.connect(_on_match_ended)
	_on_match_ended()
	pass 

func _on_match_started():
	spawned_ui.queue_free()
	pass

func _on_match_ended():
	spawned_ui = level_select_ui.instantiate()
	add_child(spawned_ui);
	pass

func switch_level(level_id: int):
	if _current_level_id == level_id or not multiplayer.is_server(): return;
	if _currently_spawned_level != null: 
		peers_murder_current_level.rpc();
		_currently_spawned_level.queue_free();
	
	if levels.keys()[level_id] == null: 
		print ("trying to switch to level with invalid id: {id}".format({"id": level_id}));
		return;
	
	DebugView.set_value("Level ID", level_id)
	
	_current_level_id = level_id;
	_currently_spawned_level = levels[levels.keys()[level_id]].instantiate();
	_currently_spawned_level.name = ("level {lvl}".format({"lvl": levels.get(levels.keys()[level_id])}));
	add_child(_currently_spawned_level);
	
	pass

@rpc("call_remote", "reliable")
func peers_murder_current_level(): # Fusk lösning
	for child in get_children():
		child.queue_free();
