extends Node3D
class_name Enemy

@export var enemy_settings: EnemySettings

var enemy_health: int = 100
var enemy_damage: int = 5

@export var enemy_speed: float = 1.0
var current_speed: float = enemy_speed

signal enemy_killed
signal enemy_escaped
signal enemy_finished(is_killed: bool)


var enemy_model: Node = null
var attackable: bool = false
var distance_travelled: float = 0

var path3d: Path3D = null
var path_follow_3d: PathFollow3D = null

func _ready():
	# Inicjalizacja enemy_settings
	if enemy_settings == null:
		print("ERROR: enemy_settings is null! Loading default settings.")
		enemy_settings = load("res://resources/basic_enemy.tres")
	
	if enemy_settings != null:
		enemy_health = 100  # domyślne HP
		enemy_speed = 1.0   # domyślna prędkość
	else:
		print("ERROR: enemy_settings is still null after attempting to load!")
		enemy_health = 100
		enemy_speed = 1.0

	# Sprawdzenie i przypisanie węzła Path3D
	if has_node("Path3D"):
		path3d = get_node("Path3D")
		path3d.curve = path_route_to_curve_3d()
	else:
		path3d = null
	
	# Sprawdzenie i przypisanie węzła PathFollow3D
	if path3d != null and path3d.has_node("PathFollow3D"):
		path_follow_3d = path3d.get_node("PathFollow3D")
		path_follow_3d.progress = 0

		# Znajdź model przeciwnika jako dziecko PathFollow3D
		if path_follow_3d.get_child_count() > 0:
			enemy_model = path_follow_3d.get_child(0)
		else:
			enemy_model = null
	else:
		path_follow_3d = null
		enemy_model = null


func set_speed(new_speed: float):
	current_speed = new_speed


#
#  Poniżej: Metody stanu wroga (EnemyStateChart)
#

func _on_spawning_state_entered():
	attackable = false
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_travelling_state")

func _on_travelling_state_entered():
	attackable = true

func _on_travelling_state_processing(delta):
	distance_travelled += delta * current_speed
	var max_distance = PathGenInstance.get_path_route().size() - 1
	var distance_on_screen = clamp(distance_travelled, 0, max_distance)
	
	if path_follow_3d != null:
		path_follow_3d.progress = distance_on_screen
	else:
		print("ERROR: path_follow_3d is null!")
	
	# Jeśli wróg przekroczył max_distance -> dotarł do końca
	if distance_travelled > max_distance:
		$EnemyStateChart.send_event("to_damaging_state")
		var main = get_tree().get_root().get_node("main")
		main.decrease_castle_health(enemy_damage)

# Emisja sygnału, że wróg się przedarł:
		emit_signal("enemy_escaped")

		queue_free()  # lub przejście do stanu despawn


func _on_damaging_state_entered():
	attackable = false
	var main = get_tree().get_root().get_node("main")
	main.decrease_castle_health(enemy_damage)
	$EnemyStateChart.send_event("to_despawning_state")

func _on_despawning_state_entered():
	# Wróg dotarł do końca lub jest usuwany w inny sposób, ale nie jest to śmierć od obrażeń
	emit_signal("enemy_finished", false)  # false => wróg NIE został zabity
	$AnimationPlayer.play("despawn")
	await $AnimationPlayer.animation_finished
	$EnemyStateChart.send_event("to_remove_enemy_state")

func _on_dying_state_entered():
	# Wróg faktycznie został zabity (HP <= 0)
	get_parent_node_3d().cash += enemy_settings.destroy_value
	
	# Tu dopiszemy nową linię:
	
	var reward = enemy_settings.destroy_value  # np. 5, 8, 9, 500 itp.
	emit_signal("enemy_killed", true, reward)
	$ExplosionAudio.play()

	if enemy_model != null:
		enemy_model.visible = false

	await $ExplosionAudio.finished
	$EnemyStateChart.send_event("to_remove_enemy_state")


func _on_remove_enemy_state_entered():
	queue_free()


#
#  Pomocnicze metody
#

func path_route_to_curve_3d() -> Curve3D:
	var c3d = Curve3D.new()
	for element in PathGenInstance.get_path_route():
		c3d.add_point(Vector3(element.x, 0.25, element.y))
	return c3d

func _on_area_3d_area_entered(area):
	# Gdy wróg dostaje obrażenia od pocisków
	if area is Projectile or area is Projectile_2 or area is Projectile_3:
		enemy_health -= area.damage
	
	if enemy_health <= 0:
		$EnemyStateChart.send_event("to_dying_state")
