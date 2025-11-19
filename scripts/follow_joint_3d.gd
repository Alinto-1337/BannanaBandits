extends Node3D
class_name FollowJoint3D

@export var rotation_stiffness: float = 3
@export var target_node: Node3D


func _ready() -> void: 
	
	
	pass

func _process(delta: float) -> void:
	
	global_position = target_node.global_position;
	
	# var cam_to_body_rot_diff = rad_to_deg((-my_camera_root_uvec).signed_angle_to(-body_rotation_root.basis.z, body_rotation_root.basis.y))
	# var this_to_target_rot_diff = rad_to_deg((target_node.basis.z).signed_angle_to(basis.z, basis.y))
	
	var new_rot: Quaternion = lerp(global_basis.get_rotation_quaternion(), target_node.global_basis.get_rotation_quaternion(), rotation_stiffness*delta)
	rotation = new_rot.get_euler()
	
	pass
