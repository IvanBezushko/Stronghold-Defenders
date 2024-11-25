extends Area3D
class_name Projectile_3

@export var starting_position: Vector3
@export var target: Node3D
@export var speed: float = 2.0 # metry na sekundę
@export var damage: int = 30

var lerp_pos: float = 0.0

func _ready():
	global_position = starting_position

func _process(delta):
	if target != null and lerp_pos < 1.0:
		lerp_pos += delta * speed
		var new_position = starting_position.lerp(target.global_position, lerp_pos)
		var direction = (new_position - global_position).normalized()
		
		if direction.length() > 0:
			look_at(global_position + direction, Vector3.UP)
		
		global_position = new_position
	else:
		queue_free()
