extends RefCounted

# GPIO id (not pin number)
var id :int
var chip :ggpio.Chip

var id_string: String:
	get: return String.num_int64(id)

func _init(id :int, chip :ggpio.Chip) -> void:
	self.id = id
	self.chip = chip

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if self != null:
			ggpio.log('freeing GPIO(%s)'%id, ggpio.LogLevel.DEBUG)
			GSF()

class GILResult extends RefCounted:
	var raw :String

	var gpio_id :int
	var line_flags :ggpio.LineFlag
	var user :String
	var purpose :String

	var is_GPIO :bool:
		get: return user.begins_with('GPIO')

	static func Parse(line :String) -> GILResult:
		# sample lines:
		#7 7 "SPI_CE1_N" "spi0 CS1"
		#0 65536 "ID_SDA" ""
		var ret := GILResult.new()
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

func GIL() -> GILResult:
	'''
	Gets information for GPIO g of an opened gpiochip. In particular it gets the GPIO number, line flags, its user, and its purpose.
	The meaning of the line flags bits are as given for the mode by GMODE.
	The user and purpose fields are filled in by the software which has claimed the GPIO and may be blank.
	'''
	var res := chip.run(['gil', chip.id_string, id_string])
	if res[0] != OK:
		ggpio.log('GIL errored: %s'%res[1], ggpio.LogLevel.ERROR)
		var ret := GILResult.new()
		ret.gpio_id = -1
		ret.user = 'error'
		return ret
	return GILResult.Parse(res[1])

func GMODE() -> int:
	'''
	gets the mode for GPIO g of an opened gpiochip
	'''
	var res := chip.run(['gmode', chip.id_string, id_string])
	if res[0] != OK:
		ggpio.log('GMODE errored: %s'%res[1], ggpio.LogLevel.ERROR)
	# TODO split this result in an array of GILResult{GPIO id, line flags, user, purpose}
	return int((res[1] as String).strip_edges())

func GSI() -> void:
	'''claims GPIO g for input'''
	return chip.run(['GSI', chip.id_string, id_string])
func GSIX(line_flag := ggpio.LineFlag.ACTIVE_LOW) -> void:
	return chip.run(['GSIX', chip.id_string, String.num_int64(line_flag), id_string])

func GSO(pin_id: int) -> void:
	return chip.run(['GSO', chip.id_string, id_string])
func GSOX(line_flag :ggpio.LineFlag, value: ggpio.Level) -> void:
	'''
	Claims GPIO g for output.
	The line flags lf may be used to set the GPIO as active low, open drain, open source,
	pull up, pull down, pull off.

	If v is zero the GPIO will be initialised low. If any other value is used the GPIO will be initialised high
	'''
	return chip.run([
		'GSOX',
		chip.id_string,
		String.num_int64(line_flag),
		id_string,
		String.num_int64(value),
	])

func GSF() -> void:
	'''
	Releases the GPIO. The GPIO may now be claimed by another user or for a different purpose.
	'''
	chip.run(['GSF', chip.id_string, id_string])

func GR() -> int:
	'''
	Returns the current value (0 or 1) of GPIO g.
	Returns -1 for error.
	This command will work for any claimed GPIO (even if a member of a group).
	For an output GPIO the value returned will be that last written to the GPIO
	'''
	var res :Array = chip.run(['GR', chip.id_string, id_string])
	if res[0] != OK:
		return -1
	return int(res[1])

func GW(value :int) -> void:
	'''
	Sets the value (0 or 1) of GPIO g.
	This command will work for any GPIO claimed as an output (even if a member of a group).
	If v is zero the GPIO will be set low. If any other value is used the GPIO will be set high.
	'''
	chip.run(['GW', chip.id_string, id_string, String.num_int64(value)])[1]

func GP(value :float, mon :int, moff :int) -> void:
	'''
	Starts software timed pulses on this GPIO.
	Each cycle consists of `mon` microseconds of GPIO high followed by `moff`
	microseconds of GPIO low.

	PWM is characterised by two values:
	- its frequency (number of cycles per second)
	- its duty cycle (percentage of high time per cycle).

	The set frequency will be 1000000 / (mon + moff) Hz.
	The set duty cycle will be mon / (mon + moff) * 100 %.

	E.g. if mon is 50 and moff is 100 the frequency will be 6666.67 Hz and the
	duty cycle will be 33.33 %.
	'''
	chip.run(['GP', chip.id_string, id_string, String.num_int64(mon), String.num_int64(moff)])

func GPX(value :float, mon :int, moff :int, off: int, cyc: int) -> void:
	'''
	Starts software timed pulses on this GPIO.

	`cyc` cycles are transmitted (0 means infinite).
	Each cycle consists of `mon` microseconds of GPIO high followed by
	`moff` microseconds of GPIO low.

	PWM is characterised by two values:
	- its frequency (number of cycles per second)
	- its duty cycle (percentage of high time per cycle).

	The set frequency will be 1000000 / (mon + moff) Hz.
	The set duty cycle will be mon / (mon + moff) * 100 %.

	E.g. if mon is 50 and moff is 100 the frequency will be 6666.67 Hz and the
	duty cycle will be 33.33 %.

	off is a microsecond offset from the natural start of the PWM cycle.
	For instance if the PWM frequency is 10 Hz the natural start of each cycle
	is at seconds 0, then 0.1, 0.2, 0.3 etc. In this case if the offset is
	20000 microseconds the cycle will start at seconds 0.02, 0.12, 0.22, 0.32 etc.

	Another command may be issued to the GPIO before the last has finished.

	If the last command had infinite cycles (cyc of 0) then it will be replaced
	by the new settings at the end of the current cycle. Otherwise it will be
	replaced by the new settings at the end of cyc cycles.

	Multiple pulse settings may be queued in this way.
	'''
	chip.run([
		'GPX',
		chip.id_string,
		id_string,
		String.num_int64(mon),
		String.num_int64(moff),
		String.num_int64(off),
		String.num_int64(cyc),
	])
