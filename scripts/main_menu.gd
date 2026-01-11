extends Node

@export var main_menu_panel: CanvasItem
@export_group("Join Server")
@export var join_server_panel: CanvasItem
@export var adress_input_line: LineEdit
@export var port_input_line: LineEdit

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func back_to_main_menu():
	main_menu_panel.visible = true
	join_server_panel.visible = false

func quit_application(): 
	get_tree().quit()

func _on_start_server_pressed():
	
	await NetworkManager.create_lobby(NetworkManager.LobbyVisibility.PUBLIC)
	
	load_game_scene()

func _on_join_server_pressed():
	main_menu_panel.visible = false
	join_server_panel.visible = true
	return

func _on_join_server_confirm_pressed():
	await NetworkManager.join_lobby({ "address": adress_input_line.text })
	load_game_scene()

func load_game_scene():
	get_tree().change_scene_to_file("res://scenes/game_scee.tscn")
