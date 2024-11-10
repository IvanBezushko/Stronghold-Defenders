extends Node3D

var enemies_in_range: Array[Node3D] = []
var current_enemy: Node3D = null

func _on_patrol_zone_area_entered(area: Area3D) -> void:
	print("enter")
	if current_enemy == null:
		current_enemy = area
	enemies_in_range.append(area)
	print(enemies_in_range.size())

func _on_patrol_zone_area_exited(area: Area3D) -> void:
	print("exit")
	enemies_in_range.erase(area)
	print(enemies_in_range.size())
	
func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

# Funkcja obraca wieżę, aby patrzyła na obecny cel
func rotate_towards_target(rtarget):
	# Ustal pozycję przeciwnika z dopasowaniem `y` na poziomie wieży
	var target_position = Vector3(rtarget.global_position.x, $Cannon.global_position.y, rtarget.global_position.z)
	$Cannon.look_at(target_position, Vector3.UP)
	$Cannon.rotate_y(PI)

func _on_patrolling_state_state_processing(delta):
	if enemies_in_range.size() > 0:
		current_enemy = enemies_in_range[enemies_in_range.size() - 1]
		$StateChart.send_event("to_acquiring_state")

func _on_acquiring_state_state_entered():
	# Tylko przygotowanie do akcji, obrót nastąpi w _physics_processing
	pass

func _on_acquiring_state_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy)
	else:
		print("Enemy disappeared while acquiring!")
		$StateChart.send_event("to_patrolling_state")

func _on_attacking_state_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy)
	else:
		print("Enemy disappeared!")
		$StateChart.send_event("to_patrolling_state")

func _on_attacking_state_state_entered():
	print("Target acquired")
