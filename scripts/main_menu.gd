extends Node

@export var main_menu_panel: CanvasItem
@export var join_server_panel: CanvasItem

func quit_application(): 
	get_tree().quit()

func _on_start_server_pressed():
	return

func _on_join_server_pressed():
	main_menu_panel.visible = false
	join_server_panel.visible = true
	return

func _on_join_server_confirm_pressed():
	return
