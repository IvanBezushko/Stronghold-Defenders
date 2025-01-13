extends Control

var is_game_paused: bool = false  # Zmienna do kontroli stanu pauzy

func _on_exit_bt_pressed() -> void:
	get_tree().paused = false  # Wyłączenie pauzy przed powrotem do menu głównego
	var game_scene = load("res://menu/menu.tscn").instantiate()
	get_tree().current_scene.queue_free()  # Usuń aktualną scenę
	get_tree().root.add_child(game_scene)  # Dodaj nową scenę
	get_tree().current_scene = game_scene  # Ustaw jako bieżącą scenę



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func update_stats(time_played: int, cash_earned: int, enemies_killed: int):
	$time_stat.text = "%d seconds" % time_played
	$cash_stat.text = "$%d" % cash_earned
	$kill_stat.text = "%d" % enemies_killed
