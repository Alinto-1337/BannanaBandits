extends ProgressBar;

var _game_controller: GameController;

func _ready() -> void:
	_game_controller = GameController.instance;
	max_value = _game_controller.max_health;
	_game_controller.my_health_updated.connect(_on_my_health_updated);


func _on_my_health_updated(health: int) -> void:
	value = health;
