extends RefCounted

# rgpio share
var share_id :int = ggpio.DEFAULT_SHARE_ID
# /dev/gciochip%s
var id :int = 0
var id_string: String:
	get: return String.num_int64(id)

var _env :Dictionary[String, String] = {
	LG_ADDR=ggpio.DEFAULT_LG_ADDR,
	LG_PORT=ggpio.DEFAULT_LG_PORT,
}

func _init(gpiochip_id :int) -> void:
	id = gpiochip_id

func set_remote(addr :String, port :String = ggpio.DEFAULT_LG_PORT) -> void:
	_env['LG_ADDR'] = addr
	_env['LG_PORT'] = port

func run(cmd :Array[String], shared:=true) -> Array:
	'''
	Returns [Error, String]
	'''
	var full_cmd :Array[String] = []
	if shared:
		full_cmd.append('c')
		full_cmd.append(String.num_int64(share_id))
	full_cmd.append_array(cmd)
	return ggpio.Run(full_cmd, _env)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if self != null:
			ggpio._log('Freeing Chip(%s)'%id, ggpio.LogLevel.DEBUG)
			GC()

func gpio(
	gpio :int,
	output := true,
	line_flag := ggpio.LineFlag.ACTIVE_LOW,
	level := ggpio.Level.LOW
) -> ggpio.GPIO:
	assert(false) # needs review
	var pin := ggpio.GPIO.new(gpio, self)
	if output:
		pin.GSOX(line_flag, level)
	else:
		pin.GSIX(line_flag)
	return pin

func GO() -> void:
	'''opens a gpiochip'''
	run(['go', id_string])

func GC() -> void:
	'''closes a gpiochip previously opened by GO'''
	run(['gc', id_string])

class GICResult extends RefCounted:
	var name :String
	var gpio_count :int
	var usage :String

func GIC() -> GICResult:
	'''
	gets information for an opened gpiochip.
	In particular it gets the count of GPIO on the gpiochip, its name, and its usage'''
	var res := run(['gic', id_string])
	var ret := GICResult.new()
	if res[0] != OK:
		ret.name = 'error'
		ret.gpio_count = -1
		return ret
	# sample data: 54 "gpiochip0" "pinctrl-bcm2835"
	var line :String = res[1]
	ret.gpio_count = int(line.substr(0, line.find(' ')))
	var quote_index_start :int = line.find('"')
	var quote_index_end :int = line.find('"', quote_index_start+1)
	ret.name = line.substr(quote_index_start+1, quote_index_end-quote_index_start-1)
	quote_index_start = line.find('"', quote_index_end+1)
	quote_index_end = line.find('"', quote_index_start+1)
	ret.usage  = line.substr(quote_index_start+1, quote_index_end-quote_index_start-1)
	return ret


func GSGI(pin_ids: Array[int]) -> void:
	'''
	Claims a group of GPIO for inputs. All the GPIO share the same line flag setting.
	The first GPIO in the list is called the group leader and is used to reference the group as a whole.
	'''
	return _GSGx('GSGI', pin_ids)
func GSGO(pin_ids: Array[int]) -> void:
	'''
	claims a group of GPIO for outputs.
	The first GPIO in the list is called the group leader and is used to reference the group as a whole.
	The GPIO will be initialised low.
	'''
	return _GSGx('GSGO', pin_ids)
func _GSGx(cmd :String, pin_ids: Array[int]) -> void:
	if pin_ids.is_empty():
		ggpio._log('%s on %s: list of gpios is empty'%[cmd, id], ggpio.LogLevel.WARNING)
		return
	var args :Array[String] = [cmd, id_string]
	args.append_array(
		pin_ids.map(func(id :int)->String: return String.num_int64(id))
	)
	run(args)

func GSGIX(line_flag :ggpio.LineFlag, pin_ids: Array[int]) -> void:
	'''
	Claims a group of GPIO for inputs. All the GPIO share the same line flag setting.
	The line flags may be used to set the GPIO as active low, open drain, open source,
	pull up, pull down, pull off.

	The first GPIO in the list is called the group leader and is used to reference the group as a whole
	'''
	if pin_ids.is_empty():
		ggpio._log('%s on %s: list of gpios is empty'%['GSGIX', id], ggpio.LogLevel.WARNING)
		return
	var args :Array[String] = ['GSGIX', id_string, String.num_int64(line_flag)]
	args.append_array(
		pin_ids.map(func(pid :int)->String: return String.num_int64(pid))
	)
	run(args)

func GSGOX(line_flag :ggpio.LineFlag, pin_ids: Array[int], lowhighs :Array[int]) -> void:
	'''
	Claims a group of GPIO for outputs. All the GPIO and share the same line flag setting.
	The line flags may be used to set the GPIO as active low, open drain, open source, pull up,
	pull down, pull off.

	The first GPIO in the list is called the group leader and is used to reference the group as a whole.
	lowhighs is a list of initialisation values for the GPIO. If a value is ggpio.LOW the corresponding
	GPIO will be initialised low. If any other value is used the corresponding GPIO will be initialised high.
	'''
	if pin_ids.is_empty():
		ggpio._log('GSGOX on %s: list of gpios is empty'%[id], ggpio.LogLevel.WARNING)
		return
	if pin_ids.size() != lowhighs.size():
		ggpio._log('GSGOX on %s: shape mismatch between pin_ids and highlows'%[id], ggpio.LogLevel.WARNING)
		return
	var args :Array[String] = ['GSGOX', id_string, String.num_int64(line_flag)]
	args.append_array(
		pin_ids.map(func(pid :int)->String: return String.num_int64(pid))
	)
	args.append_array(
		lowhighs.map(func(lh :int)->String: return String.num_int64(lh))
	)
	run(args)

func GSGF(cmd :String, line_flag :ggpio.LineFlag, pin_ids: Array[int]) -> void:
	'''

	'''
	if pin_ids.is_empty():
		ggpio._log('%s on %s: list of gpios is empty'%[cmd, id], ggpio.LogLevel.WARNING)
		return
	var args :Array[String] = [cmd, id_string, String.num_int64(line_flag)]
	args.append_array(
		pin_ids.map(func(pid :int)->String: return String.num_int64(pid))
	)
	run(args)
