extends RefCounted
'''
Represents a generic motor connected to a Phase/Enable motor driver circuit;
- phase controls whether the motor turns forwards (0) or backwards (1)
- enable controls the speed with PWM
'''
const DigitalOutputDevice = preload('digital_output_device.gd')
const PWMOutputDevice = preload('pwm_output_device.gd')
const PhaseEnableMotor = preload('phase_enable_motor.gd')

static func Make(chip :ggpio.Chip, phase :int, enable :int) -> PhaseEnableMotor:
	return PhaseEnableMotor.new(
		DigitalOutputDevice.Make(chip, phase),
		PWMOutputDevice.Make(chip, enable),
	)

var is_active :bool:
	get: return not is_zero_approx(value)
func _get_value() -> float:
	return (
		enable.value
		if is_zero_approx(phase.value) # forward
		else -enable.value
	)
func _set_value(v :float) -> float:
		v = clampf(v, -1., 1.)
		if v > 0.:
			phase.off()
			enable.value = clampf(v, 0., 1.)
		elif v < 0.:
			phase.on()
			enable.value = clampf(-v, 0., 1.)
		else:
			phase.off()
			enable.value = 0
		return v
var value :float = 0:
	get: return _get_value()
	set(v): return _set_value(v)

var phase :ggpio.devices.output.DigitalOutputDevice
var enable :ggpio.devices.output.PWMOutputDevice

var reversed := false:
	get(): return reversed
	set(v):
		phase.high_value = -1 if v else 1

func _init(
	phase :ggpio.devices.output.DigitalOutputDevice,
	enable :ggpio.devices.output.PWMOutputDevice,
)->void:
	self.phase = phase
	self.enable = enable

func forward(speed :float = 1.) -> void:
	value = speed

func backward(speed :float = 1.) -> void:
	value = -speed

func stop() -> void:
	value = 0

func close() -> void:
	phase.close()
	enable.close()
