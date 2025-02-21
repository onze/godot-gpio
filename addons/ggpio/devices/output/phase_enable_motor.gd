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
	get: return is_zero_approx(value)
var value :float = 0:
	get: return (
		enable.value
		if phase.value == 0. # forward
		else -enable.value
	)
	set(v):
		v = clampf(v, -1., 1.)
		if v > 0.:
			forward(v)
		elif v < 0.:
			backward(-v)
		else:
			stop()

var phase :ggpio.devices.output.DigitalOutputDevice
var enable :ggpio.devices.output.PWMOutputDevice

func _init(
	phase :ggpio.devices.output.DigitalOutputDevice,
	enable :ggpio.devices.output.PWMOutputDevice,
)->void:
	self.phase = phase
	self.enable = enable

func forward(speed :float = 1.) -> void:
	speed = clampf(speed, 0., 1.)
	phase.off()
	enable.value = speed

func backward(speed :float = 1.) -> void:
	speed = clampf(speed, 0., 1.)
	phase.on()
	enable.value = speed

func stop() -> void:
	enable.off()

func close() -> void:
	phase.close()
	enable.close()
