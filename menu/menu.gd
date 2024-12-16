extends Control


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


func _on_achievements_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/achiev.tscn")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/tutorial.tscn")
