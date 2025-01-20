extends Control

func _on_easy_pressed() -> void:
	Global.difficulty = "easy"
	_start_new_game()

func _on_hard_pressed() -> void:
	Global.difficulty = "hard"
	_start_new_game()

func _start_new_game() -> void:
	get_tree().paused = false
	# Po prostu zmiana sceny na "main.tscn"
	var result = get_tree().change_scene_to_file("res://scenes/main.tscn")
	if result != OK:
		print("Error changing scene: ", result)
	else:
		print("Scene changed successfully to main.tscn")
