extends Node

@export var game_scene: PackedScene
@export var main_menu_panel: CanvasItem
@export_group("Join Server")
@export var join_server_panel: CanvasItem
@export var adress_input_line: LineEdit
@export var port_input_line: LineEdit


func back_to_main_menu():
	main_menu_panel.visible = true
	join_server_panel.visible = false

func quit_application(): 
	get_tree().quit()

func _on_start_server_pressed():
	
	var error = MultiplayerManager.create_server(7777, 2)
	if error == OK:
		load_game_scene()

func _on_join_server_pressed():
	main_menu_panel.visible = false
	join_server_panel.visible = true
	return

func _on_join_server_confirm_pressed():
	var error = MultiplayerManager.join_server(adress_input_line.text, port_input_line.text.to_int())
	print(error_string(error))
	if error == OK:
		load_game_scene()

func load_game_scene():
	get_tree().change_scene_to_packed(game_scene)
