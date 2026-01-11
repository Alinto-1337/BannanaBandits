extends Node;
class_name FXSpawner;

static var instance

@export var sfx_reg: Dictionary[String, AudioStream];
@export var vfx_reg: Dictionary[String, PackedScene];


func _ready() -> void:
	instance = self;


func play_sfx(sfx_key: String, position: Vector3, pitch: float = 1, call_rpc: bool = true):
	if call_rpc:
		_rpc_send_sfx.rpc(sfx_key, position, pitch);
	
	_play_sfx(sfx_key, position, pitch);

@rpc("call_remote", "any_peer", "reliable")
func _rpc_send_sfx(sfx_key: String, position: Vector3, pitch: float = 1):
	_play_sfx(sfx_key, position, pitch);

func _play_sfx(sfx_key: String, position: Vector3, pitch: float):
	
	var audio: AudioStream = sfx_reg.get(sfx_key);
	if audio == null:
		return;
	
	var fx: AudioStreamPlayer3D = AudioStreamPlayer3D.new();
	fx.stream = audio;
	fx.autoplay = true;
	fx.pitch_scale = pitch;
	fx.position = position;
	fx.finished.connect(fx.queue_free);
	add_child(fx);

func play_vfx(vfx_key: String, position: Vector3, look_direction: Vector3 = Vector3.ZERO, call_rpc: bool = true):
	if call_rpc:
		_rpc_send_vfx.rpc(vfx_key, position, look_direction)
	
	_play_vfx(vfx_key, position, look_direction);

@rpc("call_remote", "any_peer", "reliable")
func _rpc_send_vfx(vfx_key: String, position: Vector3, look_direction: Vector3):
	_play_vfx(vfx_key, position, look_direction);


func _play_vfx(vfx_key: String, position: Vector3, look_direction: Vector3):
	var vfx_scene: PackedScene = vfx_reg.get(vfx_key);
	if vfx_scene == null:
		return;
	
	var fx = vfx_scene.instantiate()
	fx.position = position;
	if look_direction != Vector3.ZERO: fx.basis = Basis.looking_at(look_direction);
	if fx is GPUParticles3D or fx is CPUParticles3D:
		fx.ready.connect(fx.restart)
		fx.finished.connect(fx.queue_free);
	add_child(fx);
