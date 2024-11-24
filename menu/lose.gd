extends Control

var is_game_paused: bool = false  # Zmienna do kontroli stanu pauzy

func _on_exit_bt_pressed() -> void:
	get_tree().paused = false  # Wyłączenie pauzy przed powrotem do menu głównego
	var game_scene = load("res://menu/menu.tscn").instantiate()
	get_tree().current_scene.queue_free()  # Usuń aktualną scenę
	get_tree().root.add_child(game_scene)  # Dodaj nową scenę
	get_tree().current_scene = game_scene  # Ustaw jako bieżącą scenę
