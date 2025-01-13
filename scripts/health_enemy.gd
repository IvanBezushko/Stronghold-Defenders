extends Node3D
class_name Health_Enemy

@export var enemy_settings: EnemySettings

var enemy_health: int 
var enemy_speed: float 

var path3d: Path3D = null
var path_follow_3d: PathFollow3D = null
var enemy_model: Node = null

signal enemy_finished

var attackable: bool = false
var distance_travelled: float = 0

func _ready():
	#print("Health_Enemy: _ready() called")

	# Sprawdź enemy_settings
	if enemy_settings == null:
		print("ERROR: enemy_settings is null! Loading default settings.")
		enemy_settings = load("res://resources/health_enemy_settings.res")

	if enemy_settings != null:
		# Duplikuj zasób, aby uniknąć globalnych zmian
		enemy_settings = enemy_settings.duplicate(true)  # Głęboka kopia
		enemy_health = enemy_settings.health
		
		enemy_speed = enemy_settings.speed
		#print("Enemy health set to: ", enemy_health)
		#print("Enemy speed set to: ", enemy_speed)
	else:
		print("ERROR: Could not load enemy_settings, setting defaults.")
		enemy_health = 500
		enemy_speed = 1.0

	# Sprawdź Path3D
	if has_node("Path3D"):
		path3d = $Path3D
		#print("Path3D found")

		# Sprawdź PathFollow3D
		if path3d.has_node("PathFollow3D"):
			path_follow_3d = path3d.get_node("PathFollow3D")
			#print("PathFollow3D found")

			# Sprawdź enemy_model jako dziecko PathFollow3D
			if path_follow_3d.get_child_count() > 0:
				enemy_model = path_follow_3d.get_child(0)
				#print("Enemy model found: ", enemy_model)
			

	# Ustawienie krzywej Path3D
	if path3d:
		path3d.curve = path_route_to_curve_3d()
	else:
		print("ERROR: Cannot set curve on a null Path3D!")

	# Inicjalizacja początkowego postępu PathFollow3D
	if path_follow_3d:
		path_follow_3d.progress = 0
	else:
		print("ERROR: Cannot set progress on a null PathFollow3D!")

func _on_spawning_state_entered():
	print("State: Spawning entered")
	attackable = false
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_travelling_state")

func _on_travelling_state_entered():
	print("State: Travelling entered")
	attackable = true

func _on_travelling_state_processing(delta):
	if enemy_settings != null:
		distance_travelled += (delta * enemy_speed)
		#print("Travelling: Distance travelled: ", distance_travelled)

		var path_size = PathGenInstance.get_path_route().size()
		var distance_travelled_on_screen: float = clamp(distance_travelled, 0, path_size - 1)

		if path_follow_3d:
			path_follow_3d.progress = distance_travelled_on_screen
			#print("Travelling: Progress on path: ", path_follow_3d.progress)
		else:
			print("ERROR: path_follow_3d is null!")

		if distance_travelled > path_size - 1:
			#print("Travelling: Reached end of path")
			$EnemyStateChart.send_event("to_damaging_state")
	else:
		print("ERROR: enemy_settings is null during travelling state!")

func _on_despawning_state_entered():
	print("State: Despawning entered")
	enemy_finished.emit()
	$AnimationPlayer.play("despawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func _on_remove_enemy_state_entered():
	#print("State: Remove entered")
	queue_free()

func _on_damaging_state_entered():
	#print("State: Damaging entered")
	attackable = false
	#print("Enemy is damaging something!")
	$EnemyStateChart.send_event("to_despawning_state")

func _on_dying_state_entered():
	#print("State: Dying entered")
	enemy_finished.emit()
	$ExplosionAudio.play()

	# Ukryj model przeciwnika
	if enemy_model:
		#print("Hiding enemy_model")
		enemy_model.visible = false
	else:
		print("ERROR: 'enemy_model' not found!")

	await $ExplosionAudio.finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func path_route_to_curve_3d() -> Curve3D:
	#print("Generating Curve3D from path")
	var c3d: Curve3D = Curve3D.new()

	var path_route = PathGenInstance.get_path_route()
	if path_route == null:
		print("ERROR: PathGenInstance.get_path_route() returned null!")
		return c3d

	for element in path_route:
		c3d.add_point(Vector3(element.x, 0.25, element.y))
	#print("Curve3D generated with points: ", c3d.get_point_count())
	return c3d

func _on_area_3d_area_entered(area):
	#print("Collision detected with area: ", area)
	if area is Projectile or area is Projectile_2 or area is Projectile_3:
		#print("Hit by projectile, damage: ", area.damage)
		enemy_health -= area.damage
		#print("Remaining health: ", enemy_health)

		if enemy_health <= 0:
			print("Enemy health is 0 or less, dying")
			$EnemyStateChart.send_event("to_dying_state")
