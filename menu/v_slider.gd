extends VSlider  # Lub HSlider, jeśli wolisz

@export var bus_name: String  # Nazwa grupy audio (bus), którą kontrolujemy

var bus_index: int  # Indeks grupy audio
var initializing: bool = true  # Flaga inicjalizacji

func _ready() -> void:
	# Upewnij się, że bus_name jest ustawione
	if bus_name == "":
		print("Błąd: bus_name nie jest ustawione.")
		return
	value = 0.5

	bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		print("Błąd: Grupa audio o nazwie", bus_name, "nie istnieje.")
		return

	# Ustaw domyślną wartość suwaka, jeśli jest równa 0
	if value == 0:
		value = 0.5  # Ustaw domyślną wartość na 50%

	# Ustaw głośność grupy audio na podstawie wartości suwaka
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	print("Początkowa głośność grupy", bus_name, "ustawiona na:", value)

	# Podłącz sygnał 'value_changed' do funkcji '_on_value_changed'
	# Po ustawieniu wartości suwaka, aby uniknąć wywołania funkcji podczas inicjalizacji
	value_changed.connect(_on_value_changed)
	initializing = false  # Inicjalizacja zakończona

func _on_value_changed(new_value: float) -> void:
	if initializing:
		return  # Ignoruj wywołania podczas inicjalizacji

	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(new_value)
	)
	print("Głośność grupy", bus_name, "ustawiona na:", new_value)
