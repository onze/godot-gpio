extends RefCounted

var is_active :bool:
	get: return is_zero_approx(value)
var value :float = 0:
	get: return (
		_enable.value
		if _phase.value == 0
		else -_enable.value
	)
	set(v):
		value = clampf(v, -1, 1)
		if value > 0:
			forward(value)
		elif value < 0:
			backward(value)
		else:
			stop()

var _phase :lgpio.GPIO
var _enable :lgpio.GPIO

func _init(
	phase :lgpio.GPIO,
	enable :lgpio.GPIO,
)->void:
	_phase = phase
	_enable = enable

func forward(speed :float = 1.) -> void:
	value = speed
func backward(speed :float = 1.) -> void:
	value = speed
func stop() -> void:
	value = 0
