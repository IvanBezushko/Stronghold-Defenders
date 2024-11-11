extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_but_pressed() -> void:
	get_tree().paused = false  # Wyłączenie pauzy
	# Usuń obecną scenę (menu główne)
	get_tree().current_scene.queue_free()
	# Załaduj nową instancję sceny gry
	var game_scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene


func _on_settings_but_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/settings.tscn")
	
	


func _on_quit_but_pressed() -> void:
	get_tree().quit()
