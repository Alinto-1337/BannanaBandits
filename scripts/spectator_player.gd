extends Node


@export var visuals: Node3D

@export_group("Debug")
@export var server_can_see_spectators: bool

func _ready() -> void:
	if server_can_see_spectators: 
		visuals.visible = true


func _process(delta: float) -> void:
	
	var target_move_input = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		target_move_input.y -= 1
	if Input.is_action_pressed("move_back"):
		target_move_input.y -= -1
	if Input.is_action_pressed("move_right"):
		target_move_input.x -= -1
	if Input.is_action_pressed("move_left"):
		target_move_input.x -= 1 
