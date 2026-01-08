extends Control;

@export var start_match_button: Button;
@export var previous_level_button: Button;
@export var next_level_button: Button;
@export var level_name_label: Label;

var _level_spawner: LevelSpawner;
var _current_index: int;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_level_spawner = GameController.instance.level_spawner;
	
	if not multiplayer.is_server(): 
		visible = false;
		
	
	previous_level_button.pressed.connect(_on_previous_level_button_pressed);
	next_level_button.pressed.connect(_on_next_level_button_pressed);
	start_match_button.pressed.connect(_on_start_match_button_pressed);


func _on_previous_level_button_pressed():
	_current_index += 1;
	_update_level();


func _on_next_level_button_pressed():
	_current_index -= 1;
	_update_level();


func _on_start_match_button_pressed():
	
	GameController.instance.start_match();

func _update_level():
	if _level_spawner == null: return;
	
	var mod_ind: int = ((_current_index + 1) % _level_spawner.levels.keys().size()) - 1;
	
	level_name_label.text = _level_spawner.levels.keys()[mod_ind];
	
	
	_level_spawner.switch_level(mod_ind);
