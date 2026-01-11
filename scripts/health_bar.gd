extends ProgressBar;

@export var lerp_speed: float = 4;

var _game_controller: GameController;
var target_value: float;

func _ready() -> void:
	if not is_multiplayer_authority():
		get_parent_control().visible = false;
		return;
	
	_game_controller = GameController.instance;
	max_value = _game_controller.max_health;
	target_value = max_value
	value = max_value
	_game_controller.my_health_updated.connect(_on_my_health_updated);

func _process(delta: float) -> void:
	value = lerpf(value, target_value, lerp_speed*delta)

func _on_my_health_updated(health: int) -> void:
	target_value = health;
