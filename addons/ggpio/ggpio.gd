class_name ggpio
'''
GDScript addon to access Raspberri PI GPIO.
Offers a few high-level classes to abstract common use cases (inspired
by gpiozero: https://gpiozero.readthedocs.io).
'''
# This file really is a just a namespace and imports other files.
## command reference:
## https://abyz.me.uk/lg/rgs.html

const devices = preload('devices/devices.gd')
const lg = preload('lg.gd')
const Utils = preload('utils.gd')
const SBC = preload('sbc.gd')
const Chip = preload('chip.gd')
const GPIO = preload('gpio.gd')

const DEFAULT_LG_ADDR :String = 'localhost'
const DEFAULT_LG_PORT :String = '8889'
const DEFAULT_SHARE_ID := 1
# use it to disable sharing in lg commands
const NO_SHARE := -1

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

enum Mode {
	INPUT=1<<8,
	OUTPUT=1<<9,
	UNSET=-1,
}

const ModeStrings = {
	1<<0: 'Kernel: In use by the kernel', #1
	1<<1: 'Kernel: Output', #2
	LineFlag.ACTIVE_LOW: 'Kernel: Active low', #4
	LineFlag.OPEN_DRAIN: 'Kernel: Open drain', #8
	LineFlag.OPEN_SOURCE: 'Kernel: Open source', #16
	LineFlag.PULL_UP: 'Kernel: Pull up set', #32
	LineFlag.PULL_DOWN: 'Kernel: Pull down set', #64
	LineFlag.PULL_NONE: 'Kernel: Pulls off set', #128
	Mode.INPUT: 'LG: Input', #256
	Mode.OUTPUT: 'LG: Output', #512
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
	VERBOSE = -1,
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
}
static var log_level := ggpio.LogLevel.INFO

static func log(s:String, level :LogLevel) -> void:
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

static func Init(
	with_reset = false,
	env :Dictionary[String, String] = {},
) -> void:
	'''
	with_reset: will close the default GPIO,
	so as to reset it to its default state.
	'''
	_CheckRGSBinary()
	var lib_version :String = ggpio.Run(['-v'], env)[1]
	print('GGPIO: using rgs %s'%[lib_version,])
	if with_reset:
		OS.execute('rgs', ['GC', DEFAULT_SHARE_ID], [], true, false)

static func _CheckRGSBinary() -> void:
	if OS.execute('rgs', [], [], true, false) != 0:
		ggpio.log('PATH: %s'%OS.get_environment('PATH'), ggpio.LogLevel.DEBUG)
		ggpio.log('rgs binary not found! ggpio will NOT work.', ggpio.LogLevel.ERROR)

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
	ggpio.log('[CMD] %s'%[' '.join(cmd)], ggpio.LogLevel.VERBOSE)
	var rcode := OS.execute('rgs', cmd, output, true, false)
	var err := OK if rcode == 0 else FAILED
	if err != OK:
		ggpio.log(
			'Error running command "%s" (rcode %s/%s): %s'%[
				cmd,
				rcode,
				ggpio.ErrorCodes.get(rcode, ''),
				output.back() if output.size()>1 else '<empty stderr>'
			],
			ggpio.LogLevel.WARNING
		)
	return [err, output[0].strip_edges()]
