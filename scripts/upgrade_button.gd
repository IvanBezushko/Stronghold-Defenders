extends Button
@onready var panel = getnode(../..) 
func _process(delta: float) -> void:
	disabled=level>2
