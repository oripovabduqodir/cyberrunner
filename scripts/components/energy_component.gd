extends Node
class_name EnergyComponent

## Qayta ishlatiladigan energiya tizimi (Dash va energiya sarflovchi harakatlar uchun).

signal energy_changed(current_energy: float, max_energy: float)

@export var max_energy: float = 100.0
@export var regen_rate: float = 18.0
@export var regen_delay: float = 0.55

var current_energy: float = 100.0
var _regen_delay_timer: float = 0.0


func _ready() -> void:
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)


func _process(delta: float) -> void:
	if _regen_delay_timer > 0.0:
		_regen_delay_timer = maxf(0.0, _regen_delay_timer - delta)
		return

	if current_energy < max_energy:
		var prev: float = current_energy
		current_energy = minf(max_energy, current_energy + regen_rate * delta)
		if not is_equal_approx(prev, current_energy):
			energy_changed.emit(current_energy, max_energy)


func can_spend(amount: float) -> bool:
	return current_energy >= amount


func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false

	current_energy = maxf(0.0, current_energy - amount)
	_regen_delay_timer = regen_delay
	energy_changed.emit(current_energy, max_energy)
	return true


func restore(amount: float) -> float:
	if amount <= 0.0 or current_energy >= max_energy:
		return 0.0

	var prev: float = current_energy
	current_energy = minf(max_energy, current_energy + amount)
	var gained: float = current_energy - prev
	if gained > 0.0:
		energy_changed.emit(current_energy, max_energy)
	return gained


func reset_energy() -> void:
	_regen_delay_timer = 0.0
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
