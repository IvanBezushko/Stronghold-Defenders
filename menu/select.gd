extends Control

func _ready() -> void:
	pass	# Replace with function body

func _process(delta: float) -> void:
	pass

func _on_easy_pressed() -> void:
	get_tree().paused = false
	Global.difficulty = "easy"	# Ustaw poziom trudności na "easy"
	get_tree().current_scene.queue_free()
	var game_scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene




func _on_hard_pressed() -> void:
	get_tree().paused = false
	Global.difficulty = "hard"	# Ustaw poziom trudności na "hard"
	get_tree().current_scene.queue_free()
	var game_scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene
