class_name lgpio
'''
GDScript wrapper for the lgpio library: https://abyz.me.uk/rpi/lgpio.
Offers a few high-level classes to abstract common use cases (inspired
by gpiozero: https://gpiozero.readthedocs.io).
'''
# This file really is a just a namespace and imports other files.
## command reference:
## https://abyz.me.uk/lg/rgs.html

const devices = preload('devices/devices.gd')
const Utils = preload('utils.gd')
const Chip = preload('chip.gd')
const GPIO = preload('gpio.gd')

const DEFAULT_LG_ADDR :String = 'localhost'
const DEFAULT_LG_PORT :int = 8889
const DEFAULT_SHARE_ID := 1

enum LineFlag {
	ACTIVE_LOW = 4,
	OPEN_DRAIN = 8,
	OPEN_SOURCE = 16,
	PULL_UP = 32,
	PULL_DOWN = 64,
	PULL_NONE = 128
}

#enum Mode {
#}
static func GetModeString(mode :int, sep := '|') -> String:
	var modes := PackedStringArray()
	for i :int in 20:
		if mode & (1<<i):
			modes.append(ModeStrings.get(1<<i, ''))
	return sep.join(modes)

const ModeStrings = {
	1<<0: 'Kernel: In use by the kernel', #1
	1<<1: 'Kernel: Output', #2
	LineFlag.ACTIVE_LOW: 'Kernel: Active low', #4
	LineFlag.OPEN_DRAIN: 'Kernel: Open drain', #8
	LineFlag.OPEN_SOURCE: 'Kernel: Open source', #16
	LineFlag.PULL_UP: 'Kernel: Pull up set', #32
	LineFlag.PULL_DOWN: 'Kernel: Pull down set', #64
	LineFlag.PULL_NONE: 'Kernel: Pulls off set', #128
	1<<8: 'LG: Input', #256
	1<<9: 'LG: Output', #512
	1<<10: 'LG: Alert',
	1<<11: 'LG: Group',
	1<<12: 'LG: ---',
	1<<13: 'LG: ---',
	1<<14: 'LG: ---',
	1<<15: 'LG: ---',
	1<<16: 'Kernel: Input',
	1<<17: 'Kernel: Rising edge alert',
	1<<18: 'Kernel: Falling edge alert',
	1<<19: 'Kernel: Realtime clock alert',
}

enum Level {
	OFF = 0,
	LOW = 0,
	CLEAR = 0,
	ON = 1,
	HIGH = 1,
	SET = 1,
}

#region logging
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
}
static var log_level := lgpio.LogLevel.INFO

static func _log(s:String, level :LogLevel) -> void:
	if level < log_level:
		return
	var prefix := ''
	match level:
		LogLevel.DEBUG: prefix = '[DBG] '
		LogLevel.INFO: prefix = '[INF] '
		LogLevel.WARNING: prefix = '[WRN] '
		LogLevel.ERROR: prefix = '[ERR] '
	print(prefix, s)
#endregion

static func Init(with_reset = false, env :Dictionary[String, String] = {}) -> void:
	'''
	with_reset: will close the default GPIO,
	so as to reset it to its default state.
	'''
	CheckRGSBinary()
	var lib_version :String = lgpio.Run(['-v'], env)[1]
	print('Godot-LGPIO: using rgs %s'%[lib_version,])
	if with_reset:
		OS.execute('rgs', ['GC', DEFAULT_SHARE_ID], [], true, false)

static func CheckRGSBinary() -> void:
	if OS.execute('rgs', [], [], true, false) != 0:
		lgpio._log('PATH: %s'%OS.get_environment('PATH'), lgpio.LogLevel.DEBUG)
		lgpio._log('rgs binary not found! Godot-lgpio will NOT work.', lgpio.LogLevel.ERROR)

const ErrorCodes = {
	255: 'RGS_CONNECT_ERR',
	254: 'RGS_OPTION_ERR',
	253: 'RGS_SCRIPT_ERR',
}
static func Run(
	cmd :Array[String],
	env :Dictionary[String, String] = {}
) -> Array:
	'''
	Returns [Error, String].
	'''
	for k in env:
		OS.set_environment(k, env[k])
	var output :Array[String] = []
	var rcode := OS.execute('rgs', cmd, output, true, false)
	var err := OK if rcode == 0 else FAILED
	if err != OK:
		lgpio._log(
			'Error running command "%s" (rcode %s/%s): %s'%[
				cmd,
				rcode,
				lgpio.ErrorCodes.get(rcode, ''),
				output.back() if output.size()>1 else '<empty stderr>'
			],
			lgpio.LogLevel.WARNING
		)
	return [err, output[0].strip_edges()]
###################### PIGPIO
## GPIO not 0-31
#const BAD_USER_GPIO := -2
## GPIO not 0-53
#const BAD_GPIO := -3
#
## https://github.com/joan2937/lgpio/blob/c33738a320a3e28824af7807edafda440952c05d/lgpio.py#L358
#enum Mode {
	#INPUT=0, READ=0,
	#OUTPUT=1, WRITE=1,
	#ALT0=4,
	#ALT1=5,
	#ALT2=6,
	#ALT3=7,
	#ALT4=3,
	#ALT5=2,
	## mode not 0-7
	#BAD_MODE=-4,
#}
#
#
## https://github.com/joan2937/lgpio/blob/c33738a320a3e28824af7807edafda440952c05d/lgpio.py#L369
#enum PUD {
	#OFF = 0,
	#DOWN = 1,
	#UP = 2,
	## error mode
	#BAD_PUD = -6
#}
