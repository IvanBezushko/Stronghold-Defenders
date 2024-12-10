extends Area3D
class_name Projectile_3

@export var starting_position: Vector3
@export var target: Node3D
@export var speed: float 
@export var damage: int 

var lerp_pos: float = 0.0

func set_tower_level(tower_level: int):
	match tower_level:
		1:
			speed = 2
			damage = 25
		2:
			speed = 2
			damage = 30
		3:
			speed = 2.5
			damage = 35

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
