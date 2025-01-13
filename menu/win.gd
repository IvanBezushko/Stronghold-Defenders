extends Control


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
