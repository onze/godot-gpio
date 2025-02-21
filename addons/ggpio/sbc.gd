extends RefCounted
'''
SBC == Single Board Compter
This class wraps connection information
'''

var share_id :int = ggpio.DEFAULT_SHARE_ID
var host :String
var port :String

func _init(
	host :String = ggpio.DEFAULT_LG_ADDR,
	port :String = ggpio.DEFAULT_LG_PORT,
) -> void:
	self.host = host
	self.port = port

func list_chips() -> PackedStringArray:
	'''
	return ['id0', 'id1', ...]
	'''
	const gpiochip_pattern := '/dev/gpiochip'
	var res := ggpio.lg.FL(gpiochip_pattern, 5000, share_id).run(self)
	if res[0] != OK:
		ggpio.log(res[1], ggpio.LogLevel.ERROR)
		return PackedStringArray()

	var res1 := res[1] as String
	var buffer := res1.substr(res1.find(' ')+1)

	var chip_ids := PackedStringArray()
	var item_id := 0
	for line :String in buffer.split('\n', false):
		var chip_id := line.substr(gpiochip_pattern.length())
		chip_ids.append(chip_id)
	return chip_ids

func open_chip(chip_id :String) -> ggpio.Chip:
	var chip := ggpio.Chip.new(self, chip_id)
	chip.open()
	return chip

func close_chip(chip :ggpio.Chip) -> void:
	chip.close()

func run(cmd :ggpio.lg.LGCommand) -> Array:
	return cmd.run(self)
