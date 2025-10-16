extends Node3D
class_name  MultiplayerBullet

var start_pos: Vector3
var start_impulse_direction: Vector3
var start_time: float
var gravity_factor: float

func _process(_delta: float) -> void:
	
	var t = Time.get_ticks_msec() - start_time
	
	global_position = start_pos + start_impulse_direction * t + gravity_factor * Vector3.DOWN
