extends RefCounted
'''
Represents a generic output device with typical on/off behaviour.
Heavily inspired by https://gpiozero.readthedocs.io/en/latest/api_output.html#digitaloutputdevice
'''

const DigitalOutputDevice = preload('digital_output_device.gd')

static func Make(chip :ggpio.Chip, gpio_id :int) -> DigitalOutputDevice:
	return DigitalOutputDevice.new(
		chip.open_gpio(
			gpio_id,
			ggpio.Mode.OUTPUT,
			ggpio.LineFlag.PULL_DOWN,
			ggpio.Level.OFF,
		)
	)

var gpio :ggpio.GPIO
var high_value := 1
var value :float:
	get: return value
	set(value_):
		value = clampf(value_, 0., 1.)
		if is_zero_approx(value):
			off()
		else:
			on()

var is_on :bool:
	get: return value > .0
	set(flag):
		if flag:
			on()
		else:
			off()
var is_off :bool:
	get: return not is_on
	set(flag):
		is_on = not flag

func _init(gpio :ggpio.GPIO, active_high := true) -> void:
	self.gpio = gpio
	if not active_high:
		high_value = 0

func on() -> void:
	self.gpio.write(high_value)

func off() -> void:
	self.gpio.write(1-high_value)

func close() -> void:
	gpio.close()

func read() -> ggpio.Level:
	return gpio.read()
