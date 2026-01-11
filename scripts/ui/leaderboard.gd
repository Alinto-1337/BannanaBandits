extends Control

@export var list_item_container: Control

func _process(delta: float) -> void:
	visible = Input.is_action_pressed("show_leaderboard");
	if Input.is_action_just_pressed("show_leaderboard"):
		_reload_list();

func _reload_list():
	for child in list_item_container.get_children():
		child.queue_free();
	
	for player in NetworkManager.players.values():
		_spawn_player_item(player.get("display_name"), 0);

func _spawn_player_item(player_name: String, score: int):
	var h_box = HBoxContainer.new();
	list_item_container.add_child(h_box);
	
	var name_text = Label.new();
	name_text.text = player_name;
	h_box.add_child(name_text);
	var score_text = Label.new();
	score_text.text = str(score);
	h_box.add_child(score_text);
