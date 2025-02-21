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
	var chip0 := ggpio.Chip.new(0)
	# open / acquire device
	chip0.GO()
	# get GPIO 27 in output mode
	gpio27 = ggpio.GPIO.new(27, chip0)
	gpio27.GSOX(ggpio.LineFlag.PULL_DOWN, ggpio.Level.LOW)
	assert(gpio27.GR() == ggpio.Level.LOW)
	gpio27.GW(ggpio.Level.HIGH)
	assert(gpio27.GR() == ggpio.Level.HIGH)
	var mode := gpio27.GMODE()
	var mode_string := ggpio.GetModeString(mode)
	print('init ok, gpio 27 mode: %s / %s'%[mode, mode_string])

func _process(_delta: float) -> void:
	t += PI*1./24.
	const delta := .5
	var sin_t := sin(t)
	if gpio27 != null:
		if sin_t < delta:
			gpio27.GW(ggpio.Level.LOW)
			gpio27_level = -1
		elif sin_t > 1.-delta:
			gpio27.GW(ggpio.Level.HIGH)
			gpio27_level = 1
		else:
			gpio27_level = 0
	print('t=%.2f, sin_t=%.2f, gpio27=%s'%[t, sin_t, gpio27_level])
