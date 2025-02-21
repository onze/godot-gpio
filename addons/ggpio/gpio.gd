extends RefCounted

# GPIO id (not pin number)
var gpio_id :int:
	get: return gpio_id
	set(value):
		gpio_id = value
		gpio_id_string = String.num_int64(gpio_id)
var chip :ggpio.Chip

var gpio_id_string: String

func _init(
	chip :ggpio.Chip,
	gpio_id :int,
	mode := ggpio.Mode.UNSET,
	line_flags := ggpio.LineFlag.ACTIVE_LOW,
	value: ggpio.Level = 0,
	) -> void:
	self.gpio_id = gpio_id
	self.chip = chip
	if mode != ggpio.Mode.UNSET:
		open(mode, line_flags, value)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if self != null:
			ggpio.log('closing GPIO %s'%gpio_id, ggpio.LogLevel.DEBUG)
			close()

func open(
	mode :ggpio.Mode,
	line_flags :ggpio.LineFlag = ggpio.LineFlag.ACTIVE_LOW,
	value: ggpio.Level = 0,
	) -> void:
	match mode:
		ggpio.Mode.INPUT:
			ggpio.lg.GSIX(
				chip.chip_id,
				line_flags,
				gpio_id,
				chip.sbc.share_id
			).run(chip.sbc)
		ggpio.Mode.OUTPUT:
			ggpio.lg.GSOX(
				chip.chip_id,
				line_flags,
				gpio_id,
				value,
				chip.sbc.share_id
			).run(chip.sbc)

func close() -> void:
	ggpio.lg.GSF(chip.chip_id, gpio_id, chip.sbc.share_id).run(chip.sbc)

class GPIOInfo extends RefCounted:
	var raw :String

	var gpio_id :int
	var line_flags :ggpio.LineFlag
	var user :String
	var purpose :String

	var is_GPIO :bool:
		get: return user.begins_with('GPIO')

	static func Parse(line :String) -> GPIOInfo:
		# sample lines:
		#7 7 "SPI_CE1_N" "spi0 CS1"
		#0 65536 "ID_SDA" ""
		var ret := GPIOInfo.new()
		ret.raw = line
		var start_index := 0
		var end_index := line.find(' ') # first space
		ret.gpio_id = int(line.substr(start_index, end_index-start_index))
		start_index=end_index+1 # first lf char
		end_index=line.find(' ', start_index+1) # space after lf
		ret.line_flags = int(line.substr(start_index, end_index-start_index))
		start_index=line.find('"', end_index+1) # left dquote of user
		end_index=line.find('"', start_index+1) # right dquote of user
		ret.user = line.substr(start_index+1, end_index-start_index-1)
		start_index=line.find('"', end_index+1) # left dquote of purpose
		end_index=line.find('"', start_index+1) # right dquote of purpose
		ret.purpose = line.substr(start_index+1, end_index-start_index-1)
		return ret

func get_info() -> GPIOInfo:
	'''
	Gets information for GPIO g of an opened gpiochip. In particular it gets the GPIO number, line flags, its user, and its purpose.
	The meaning of the line flags bits are as given for the mode by GMODE.
	The user and purpose fields are filled in by the software which has claimed the GPIO and may be blank.
	'''
	var res := ggpio.lg.GIL(chip.chip_id, gpio_id, chip.sbc.share_id).run(chip.sbc)
	if res[0] != OK:
		ggpio.log('GIL errored: %s'%res[1], ggpio.LogLevel.ERROR)
		return null
	return GPIOInfo.Parse(res[1])

func get_mode() -> int:
	'''
	gets the mode for GPIO g of an opened gpiochip
	'''
	var res := ggpio.lg.GMODE(chip.chip_id, gpio_id, chip.sbc.share_id).run(chip.sbc)
	if res[0] != OK:
		ggpio.log('GMODE errored: %s'%res[1], ggpio.LogLevel.ERROR)
		return -1
	return int((res[1] as String).strip_edges())

func read() -> int:
	'''
	Returns the current value of GPIO g.
	Returns -1 for error.
	This command will work for any claimed GPIO (even if a member of a group).
	For an output GPIO the value returned will be that last written to the GPIO
	'''
	var res :Array = ggpio.lg.GR(chip.chip_id, gpio_id, chip.sbc.share_id).run(chip.sbc)
	if res[0] != OK:
		return -1
	return int(res[1])

func write(value :int) -> void:
	'''
	Sets the value (0 or 1) of GPIO g.
	This command will work for any GPIO claimed as an output (even if a member of a group).
	If v is zero the GPIO will be set low. If any other value is used the GPIO will be set high.
	'''
	ggpio.lg.GW(chip.chip_id, gpio_id, value, chip.sbc.share_id).run(chip.sbc)

func pwm(freq_hz :int, duty_cycle :int, off := 0, cyc := 0) -> void:
	'''
	Starts software timed PWM on an output GPIO.
	'''
	ggpio.lg.PX(chip.chip_id, gpio_id, freq_hz, duty_cycle, off, cyc, chip.sbc.share_id).run(chip.sbc)
