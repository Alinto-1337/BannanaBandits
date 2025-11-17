extends Node3D
class_name  MultiplayerBullet

var camera_root: Node3D

# Raycast
@export var raycast: RayCast3D
var raycast_start_pos: Vector3
var raycast_shoot_direction: Vector3

# Line
var line_start_pos: Vector3

func _process(_delta: float) -> void:
	
	# var t = Time.get_ticks_msec() - start_time
	
	# global_position = start_pos + start_impulse_direction * t + gravity_factor * Vector3.DOWN
	
	
	pass


func _ready() -> void:
	raycast.target_position = camera_root.basis.x * range
	
	if raycast.is_colliding():
		
		pass
	
	
	pass
