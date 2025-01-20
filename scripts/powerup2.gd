extends Button

@onready var main = $"../.."
@export var powerup_button_icon:Texture2D
var slowdown_cost = 150
var slowdown_amount = 10

func _ready() -> void:
	icon=powerup_button_icon

func _process(delta: float) -> void:
	$Label.text="$ " + str(slowdown_cost)
	if main.cash < slowdown_cost:
		self.disabled=true
	else:
		self.disabled=false

func _on_pressed() -> void:
	if main.cash >= slowdown_cost:
		main.cash -= slowdown_cost
		main.slow_down_enemies(0.5, 10.0)
		$Label.text="$ " + str(slowdown_cost)
		slowdown_cost+=10
		if main.cash < slowdown_cost:
			self.disabled=true
		else:
			self.disabled=false
	else:
		print("Not enough gold to purchase.")
