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

var _phase :ggpio.GPIO
var _enable :ggpio.GPIO

func _init(
	phase :ggpio.GPIO,
	enable :ggpio.GPIO,
)->void:
	_phase = phase
	_enable = enable

func forward(speed :float = 1.) -> void:
	value = speed
func backward(speed :float = 1.) -> void:
	value = speed
func stop() -> void:
	value = 0
