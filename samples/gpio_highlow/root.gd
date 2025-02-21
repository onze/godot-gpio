extends Node
'''
This script turns GPIO 27 on and off alternatively.
It's better run locally to the pi and with the --headless godot flag.
'''

var t :float = .0
var gpio27 :lgpio.GPIO
var gpio27_level := 0

func _ready():
	lgpio.Init(true)
	var chip0 := lgpio.Chip.new(0)
	# open / acquire device
	chip0.GO()
	# get GPIO 27 in output mode
	gpio27 = lgpio.GPIO.new(27, chip0)
	gpio27.GSOX(lgpio.LineFlag.PULL_DOWN, lgpio.Level.LOW)
	assert(gpio27.GR() == lgpio.Level.LOW)
	gpio27.GW(lgpio.Level.HIGH)
	assert(gpio27.GR() == lgpio.Level.HIGH)
	var mode := gpio27.GMODE()
	var mode_string := lgpio.GetModeString(mode)
	print('init ok, gpio 27 mode: %s / %s'%[mode, mode_string])

func _process(_delta: float) -> void:
	t += PI*1./24.
	const delta := .5
	var sin_t := sin(t)
	if gpio27 != null:
		if sin_t < delta:
			gpio27.GW(lgpio.Level.LOW)
			gpio27_level = -1
		elif sin_t > 1.-delta:
			gpio27.GW(lgpio.Level.HIGH)
			gpio27_level = 1
		else:
			gpio27_level = 0
	print('t=%.2f, sin_t=%.2f, gpio27=%s'%[t, sin_t, gpio27_level])
