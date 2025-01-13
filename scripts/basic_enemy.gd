extends Node3D
class_name Enemy

@export var enemy_settings: EnemySettings

var enemy_health: int = 100
var enemy_damage:int = 5
var enemy_speed: float = 1.0  # Dodana zmienna

signal enemy_finished

var enemy_model: Node = null  # Dodana zmienna

var attackable: bool = false
var distance_travelled: float = 0

var path3d: Path3D = null
var path_follow_3d: PathFollow3D = null

func _ready():
	# Inicjalizacja enemy_settings
	if enemy_settings == null:
		print("ERROR: enemy_settings is null! Loading default settings.")
		enemy_settings = load("res://resources/basic_enemy.tres")  # Użyj 'load' zamiast 'preload'
	
	if enemy_settings != null:
		
		
		enemy_health = 100  # Ustaw domyślną wartość zdrowia
		enemy_speed = 1.0   # Ustaw domyślną wartość prędkości
		#print("Enemy health set to: ", enemy_health)
		#print("Enemy speed set to: ", enemy_speed)
	else:
		print("ERROR: enemy_settings is still null after attempting to load!")
		enemy_health = 100  # Ustaw domyślną wartość zdrowia
		enemy_speed = 1.0   # Ustaw domyślną wartość prędkości
	
	# Sprawdzenie i przypisanie węzła Path3D
	if has_node("Path3D"):
		path3d = get_node("Path3D")
		#print("Path3D exists")
		path3d.curve = path_route_to_curve_3d()
	else:
		#print("ERROR: Path3D not found!")
		path3d = null
	
	# Sprawdzenie i przypisanie węzła PathFollow3D
	if path3d != null and path3d.has_node("PathFollow3D"):
		path_follow_3d = path3d.get_node("PathFollow3D")
		#print("PathFollow3D exists")
		path_follow_3d.progress = 0

		# Znajdź model przeciwnika
		if path_follow_3d.get_child_count() > 0:
			enemy_model = path_follow_3d.get_child(0)
			#print("Enemy model found: ", enemy_model)
		else:
			#print("ERROR: PathFollow3D has no children!")
			enemy_model = null
	else:
		#print("ERROR: PathFollow3D not found!")
		path_follow_3d = null
		enemy_model = null

func _on_spawning_state_entered():
	attackable = false
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_travelling_state")

func _on_travelling_state_entered():
	attackable = true

func _on_travelling_state_processing(delta):
	distance_travelled += (delta * enemy_speed)  # Użycie enemy_speed
	var max_distance = PathGenInstance.get_path_route().size() - 1
	var distance_travelled_on_screen: float = clamp(distance_travelled, 0, max_distance)
	
	if path_follow_3d != null:
		path_follow_3d.progress = distance_travelled_on_screen
	else:
		print("ERROR: path_follow_3d is null!")
	
	if distance_travelled > max_distance:
		$EnemyStateChart.send_event("to_damaging_state")

func _on_despawning_state_entered():
	enemy_finished.emit()
	$AnimationPlayer.play("despawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func _on_remove_enemy_state_entered():
	queue_free()

func _on_damaging_state_entered():
	attackable = false
	#print("doing some damage!")
	var main = get_tree().get_root().get_node("main")  
	main.decrease_castle_health(enemy_damage)
	$EnemyStateChart.send_event("to_despawning_state")

func _on_dying_state_entered():
	get_parent_node_3d().cash+=enemy_settings.destroy_value
	enemy_finished.emit()
	$ExplosionAudio.play()

	if enemy_model != null:
		enemy_model.visible = false
	else:
		print("ERROR: enemy_model is null!")

	await $ExplosionAudio.finished
	$EnemyStateChart.send_event("to_remove_enemy_state")
	
func path_route_to_curve_3d() -> Curve3D:
	var c3d: Curve3D = Curve3D.new()
	
	for element in PathGenInstance.get_path_route():
		c3d.add_point(Vector3(element.x, 0.25, element.y))

	return c3d

func _on_area_3d_area_entered(area):
	if area is Projectile or area is Projectile_2 or area is Projectile_3:
		enemy_health -= area.damage
	
	if enemy_health <= 0:
		$EnemyStateChart.send_event("to_dying_state")
