extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("toggle_pause_menu"):
		
		if multiplayer.is_server() and not GameController.instance.is_match_active and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			pass
		else:
			toggle_visibility()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_visibility():
	visible = not visible
	pass

func quit_game():
	get_tree().change_scene_to_file("res://scenes/menu.tscn");
	NetworkManager.disconnect_from_lobby()
