extends RefCounted

const Chip = preload('chip.gd')

var sbc :ggpio.SBC

# /dev/gciochip%s
var chip_id :String

func _init(sbc :ggpio.SBC, chip_id :String) -> void:
	self.sbc = sbc
	self.chip_id = chip_id

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if self != null:
			ggpio.log('Closing chip %s'%chip_id, ggpio.LogLevel.DEBUG)
			close()

func open() -> void:
	ggpio.lg.GO(chip_id, sbc.share_id).run(sbc)

func close() -> void:
	ggpio.lg.GC(chip_id, sbc.share_id).run(sbc)

class ChipInfo extends RefCounted:
	var name :String
	var gpio_count :int
	var usage :String

func get_info() -> ChipInfo:
	'''
	Gets information for an opened gpiochip.
	In particular it gets the count of GPIO on the gpiochip, its name, and its usage'''
	var res := ggpio.lg.GIC(chip_id, sbc.share_id).run(sbc)
	var ret := ChipInfo.new()
	if res[0] != OK:
		return null
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

func open_gpio(
	gpio_id :int,
	mode := ggpio.Mode.UNSET,
	line_flags :ggpio.LineFlag = ggpio.LineFlag.ACTIVE_LOW,
	value: ggpio.Level = 0,
	) -> ggpio.GPIO:
	return ggpio.GPIO.new(self, gpio_id, mode, line_flags, value)

func close_gpio(gpio :ggpio.GPIO) -> void:
	gpio.close()
