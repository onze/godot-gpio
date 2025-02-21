extends Node
'''
This script turns GPIO 27 on and off alternatively.
It's better run locally to the pi and with the --headless godot flag.
'''

var t :float = .0
var gpio27 :ggpio.GPIO
var gpio27_level := 0

func _ready():
	ggpio.Init(true)
	var sbc := ggpio.SBC.new('goshrimp.local')
	var chip := sbc.open_chip('0')
	# get GPIO 27 in output mode
	gpio27 = chip.open_gpio(27, ggpio.Mode.OUTPUT, ggpio.LineFlag.PULL_DOWN, ggpio.Level.LOW)
	#assert(gpio27.read() == ggpio.Level.LOW)
	gpio27.write(ggpio.Level.HIGH)
	assert(gpio27.read() == ggpio.Level.HIGH)
	var mode := gpio27.get_mode()
	var mode_string := ggpio.GetModeString(mode)
	print('init ok, gpio 27 mode: %s / %s'%[mode, mode_string])

const MARGIN := .5
func _process(_delta: float) -> void:
	t += PI*1./24.
	var sin_t := sin(t)

	if gpio27 != null:
		var report := true
		if sin_t < MARGIN:
			gpio27.write(ggpio.Level.LOW)
			print('t=%.2f, sin_t=%.2f, gpio27=%s'%[t, sin_t, gpio27.read()])
		elif sin_t > 1.-MARGIN:
			gpio27.write(ggpio.Level.HIGH)
		else:
			gpio27_level = 0
			report = false
		if report:
			print('t=%.2f, sin_t=%.2f, gpio27=%s'%[t, sin_t, gpio27.read()])
