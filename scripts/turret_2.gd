extends Node3D

var enemies_in_range: Array[Node3D] = []
var current_enemy: Node3D = null
var current_enemy_class = null
var current_enemy_targetted: bool = false
var acquire_slerp_progress: float = 0

var last_fire_time: int
@export var fire_rate_ms: int = 1000
@export var projectile_type: PackedScene

func _on_patrol_zone_area_entered(area):
	if not enemies_in_range.has(area):
		enemies_in_range.append(area)
		print("Enemy entered range: ", area)

func _on_patrol_zone_area_exited(area):
	if enemies_in_range.has(area):
		enemies_in_range.erase(area)
		print("Enemy exited range: ", area)

	if area == current_enemy:
		print("Current enemy left range or was destroyed")
		_disconnect_current_enemy_signals()
		current_enemy = null
		current_enemy_class = null
		$StateChart.send_event("to_patrolling_state")

func set_patrolling(patrolling: bool):
	$PatrolZone.monitoring = patrolling

func rotate_towards_target(rtarget, delta):
	var target_vector = $Ballista.global_position.direction_to(Vector3(rtarget.global_position.x, $Ballista.global_position.y, rtarget.global_position.z))
	var target_basis: Basis = Basis.looking_at(target_vector, Vector3.UP)
	target_basis = target_basis.rotated(Vector3.UP, PI)

	if acquire_slerp_progress < 1:
		$Ballista.basis = $Ballista.basis.slerp(target_basis, acquire_slerp_progress)
		acquire_slerp_progress += delta
	else:
		$Ballista.basis = target_basis
		$StateChart.send_event("to_attacking_state")

func _find_enemy_parent(n: Node):
	while n != null:
		if n is Enemy or n is Speed_Enemy or n is Health_Enemy or n is Sp_Hth_Enemy or n is Boss_Enemy:
			return n
		n = n.get_parent()
	return null

func _on_patrolling_state_state_processing(_delta):
	if enemies_in_range.size() > 0:
		current_enemy = enemies_in_range[0]
		current_enemy_class = _find_enemy_parent(current_enemy)

		if current_enemy_class == null:
			print("ERROR: Could not find enemy class for: ", current_enemy)
			return

		_connect_current_enemy_signals()

		$StateChart.send_event("to_acquiring_state")
	else:
		current_enemy = null
		current_enemy_class = null

func _connect_current_enemy_signals():
	if current_enemy_class != null:
		if not current_enemy_class.enemy_finished.is_connected(self._remove_current_enemy):
			current_enemy_class.enemy_finished.connect(self._remove_current_enemy)

func _disconnect_current_enemy_signals():
	if current_enemy_class != null:
		if current_enemy_class.enemy_finished.is_connected(self._remove_current_enemy):
			current_enemy_class.enemy_finished.disconnect(self._remove_current_enemy)

func _remove_current_enemy():
	if enemies_in_range.has(current_enemy):
		enemies_in_range.erase(current_enemy)
	print("Enemy finished or destroyed: ", current_enemy)
	_disconnect_current_enemy_signals()
	current_enemy = null
	current_enemy_class = null
	$StateChart.send_event("to_patrolling_state")

func _on_acquiring_state_state_entered():
	current_enemy_targetted = false
	acquire_slerp_progress = 0

func _on_acquiring_state_state_physics_processing(delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, delta)
	else:
		print("Enemy lost during acquiring state")
		_disconnect_current_enemy_signals()
		current_enemy = null
		current_enemy_class = null
		$StateChart.send_event("to_patrolling_state")

func _on_attacking_state_state_physics_processing(_delta):
	if current_enemy != null and enemies_in_range.has(current_enemy):
		rotate_towards_target(current_enemy, _delta)
		_maybe_fire()
	else:
		print("Enemy lost during attacking state")
		_disconnect_current_enemy_signals()
		current_enemy = null
		current_enemy_class = null
		$StateChart.send_event("to_patrolling_state")

func _maybe_fire():
	if Time.get_ticks_msec() > (last_fire_time + fire_rate_ms) and current_enemy != null:
		var projectile: Projectile_2 = projectile_type.instantiate()
		projectile.starting_position = $Ballista/projectile_spawn.global_position
		projectile.target = current_enemy
		add_child(projectile)
		last_fire_time = Time.get_ticks_msec()

func _on_attacking_state_state_entered():
	last_fire_time = 0
