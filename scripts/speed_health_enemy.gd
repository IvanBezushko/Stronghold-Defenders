extends Node3D
class_name Sp_Hth_Enemy

@export var enemy_settings: EnemySettings  # EnemySettings to zasób dziedziczący po Resource

var enemy_health: int 
var enemy_damage:int 
@export var enemy_speed: float = 1.8
var current_speed: float = enemy_speed

signal enemy_finished

var enemy_model: Node = null  # Dodana zmienna

var attackable: bool = false
var distance_travelled: float = 0

var path3d: Path3D = null
var path_follow_3d: PathFollow3D = null

func _ready():
	#print("Sp_Hth_Enemy: _ready() called")
	
	# Inicjalizacja enemy_settings
	if enemy_settings == null:
		print("ERROR: enemy_settings jest null! Ładowanie domyślnych ustawień.")
		enemy_settings = load("res://resources/speed_health_enemy_settings.res")
	
	if enemy_settings != null:
		# Duplikuj zasób, aby modyfikacje były lokalne
		enemy_settings = enemy_settings.duplicate(true)  # Głęboka kopia
		enemy_health = enemy_settings.health
		enemy_damage = enemy_settings.damage
		enemy_speed = enemy_settings.speed
		#print("Enemy health set to: ", enemy_health)
		#print("Enemy speed set to: ", enemy_speed)
	else:
		print("ERROR: enemy_settings nadal jest null po próbie ustawienia!")
		enemy_health = 480  # Ustaw domyślną wartość zdrowia
		enemy_speed = 1.8 
	
	# Sprawdzenie i przypisanie węzła Path3D
	if has_node("Path3D"):
		path3d = get_node("Path3D")
		print("Path3D istnieje")
		path3d.curve = path_route_to_curve_3d()
	else:
		#print("ERROR: Path3D nie został znaleziony!")
		path3d = null
	
	# Sprawdzenie i przypisanie węzła PathFollow3D
	if path3d != null and path3d.has_node("PathFollow3D"):
		path_follow_3d = path3d.get_node("PathFollow3D")
		print("PathFollow3D istnieje")
		path_follow_3d.progress = 0

		# Znajdź model przeciwnika
		if path_follow_3d.get_child_count() > 0:
			enemy_model = path_follow_3d.get_child(0)
			#print("Model przeciwnika znaleziony: ", enemy_model.name)
		else:
			print("ERROR: PathFollow3D nie ma dzieci!")
			enemy_model = null
	else:
		print("ERROR: PathFollow3D nie został znaleziony!")
		path_follow_3d = null
		enemy_model = null

func set_speed(new_speed: float):
	current_speed = new_speed

func _on_spawning_state_entered():
	print("Stan: Spawning wejście")
	attackable = false
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_travelling_state")

func _on_travelling_state_entered():
	#print("Stan: Travelling wejście")
	attackable = true

func _on_travelling_state_processing(delta):
	if enemy_settings != null:
		distance_travelled += (delta * current_speed)
		var path_size = PathGenInstance.get_path_route().size()
		var distance_travelled_on_screen: float = clamp(distance_travelled, 0, path_size - 1)
		
		if path_follow_3d != null:
			path_follow_3d.progress = distance_travelled_on_screen
			#print("Travelling: Postęp na ścieżce: ", path_follow_3d.progress)
		else:
			print("ERROR: path_follow_3d jest null!")
		
		if distance_travelled > path_size - 1:
			$EnemyStateChart.send_event("to_damaging_state")
	else:
		print("ERROR: enemy_settings jest null podczas stanu Travelling!")

func _on_despawning_state_entered():
	print("Stan: Despawning wejście")
	enemy_finished.emit()
	$AnimationPlayer.play("despawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func _on_remove_enemy_state_entered():
	print("Stan: Remove wejście")
	queue_free()

func _on_damaging_state_entered():
	#print("Stan: Damaging wejście")
	attackable = false
	#print("Enemy wykonuje obrażenia!")
	var main = get_tree().get_root().get_node("main")  
	main.decrease_castle_health(enemy_damage)
	$EnemyStateChart.send_event("to_despawning_state")

func _on_dying_state_entered():
	print("Stan: Dying wejście")
	get_parent_node_3d().cash+=enemy_settings.destroy_value
	enemy_finished.emit()
	$ExplosionAudio.play()
	var collision_shape = $Path3D/PathFollow3D/Area3D/CollisionShape3D
	if collision_shape != null:
		collision_shape.queue_free()
	else:
		print("ERROR: CollisionShape3D is null!")
	
	if enemy_model != null:
		enemy_model.visible = false
	else:
		print("ERROR: enemy_model jest null!")
	
	await $ExplosionAudio.finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func path_route_to_curve_3d() -> Curve3D:
	#print("Generowanie Curve3D z trasy")
	var c3d: Curve3D = Curve3D.new()
	
	var path_route = PathGenInstance.get_path_route()
	if path_route == null:
		print("ERROR: PathGenInstance.get_path_route() zwrócił null!")
		return c3d

	for element in path_route:
		c3d.add_point(Vector3(element.x, 0.25, element.y))
	#print("Curve3D wygenerowany z punktami: ", c3d.get_point_count())
	return c3d

func _on_area_3d_area_entered(area):
	#print("Wykryto kolizję z obszarem: ", area.name)
	if area is Projectile or area is Projectile_2 or area is Projectile_3:
		#print("Został trafiony przez pocisk, obrażenia: ", area.damage)
		enemy_health -= area.damage
		#print("Pozostało zdrowia: ", enemy_health)

		if enemy_health <= 0:
			#print("Zdrowie przeciwnika jest 0 lub mniej, umieranie")
			$EnemyStateChart.send_event("to_dying_state")
