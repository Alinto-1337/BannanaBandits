extends SkeletonIK3D

@export var camera_root: Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	target = Transform3D(camera_root.global_basis, camera_root.global_position)
	pass
