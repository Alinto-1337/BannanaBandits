extends Control


var display_values: Dictionary[String, Variant]

var _debug_text: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	_debug_text = Label.new();
	_debug_text.anchor_bottom = 1
	add_child(_debug_text);
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_display_value_ui();
	pass


func set_value(key:String, value:Variant):
	
	display_values.set(key, value)
	
	pass


func _update_display_value_ui() -> void:
	var _out: String
	for key:String in display_values.keys():
		
		_out += "\n {key} : {value}".format({"key": key, "value": str(display_values.get(key))});
		
		pass
	pass
	
	_debug_text.text = _out;
