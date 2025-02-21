extends RefCounted
'''
Represents a generic output device with typical on/off behaviour.
Heavily inspired by https://gpiozero.readthedocs.io/en/latest/api_output.html#digitaloutputdevice
'''

const PWMOutputDevice = preload('pwm_output_device.gd')

static func Make(chip :ggpio.Chip, gpio_id :int) -> PWMOutputDevice:
	return PWMOutputDevice.new(
		chip.open_gpio(
			gpio_id,
			ggpio.Mode.OUTPUT,
			ggpio.LineFlag.PULL_DOWN,
			ggpio.Level.OFF,
		),
		100.,
	)

var gpio :ggpio.GPIO
var value :float:
	get: return value
	set(value_):
		value = clampf(value_, 0., 1.)
		if is_zero_approx(freq_hz) or is_zero_approx(value):
			stop()
		else:
			write(value)
var freq_hz :float = 100.
# a duty_cycle < dead_zone counts as 0
var dead_zone :float = .2

func _init(gpio :ggpio.GPIO, freq_hz :float = 100.) -> void:
	self.gpio = gpio
	self.freq_hz = clampi(freq_hz, 0, 10000)

func close() -> void:
	gpio.close()

func read() -> ggpio.Level:
	return gpio.read()

func write(duty_cycle :float) -> void:
	dead_zone = 0.2
	duty_cycle = clampf(duty_cycle, 0., 1.)
	if duty_cycle < dead_zone:
		stop()
	else:
		gpio.pwm(freq_hz, duty_cycle*100.)

func stop() -> void:
	self.gpio.pwm(1, 0, 0, 0)

func off() -> void:
	stop()
