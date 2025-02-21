extends Control

#region chip UI
@onready var gpio_picker: OptionButton = %'gpio-picker'
@onready var refresh_gpio_btn: Button = %'refresh-gpio-btn'
@onready var chip_name_value: Label = %'chip-name-value'
@onready var chip_gpio_count_value: Label = %'chip-gpio-count-value'
@onready var chip_usage_value: Label = %'chip-usage-value'
#endregion

#region pinout
@onready var pinout_grid: GridContainer = %'pinout-grid'
#endregion

var chip :ggpio.Chip

var env :Dictionary[String, String] = {
	LG_ADDR='goshrimp.local',
	LG_PORT=String.num_int64(ggpio.DEFAULT_LG_PORT),
}

func _ready() -> void:
	get_window().title = 'GGPIO -- GPIO Explorer'
	ggpio.log_level = ggpio.LogLevel.DEBUG
	OS.set_environment('LG_ADDR', 'goshrimp.local')
	ggpio.Init(true)

	chip = ggpio.Chip.new(0)
	chip.set_remote('goshrimp.local')
	refresh_gpio_btn.pressed.connect(_request_refresh_gpiochips)
	gpio_picker.item_selected.connect(_on_gpio_picker_item_selected)
	_request_refresh_gpiochips()

func _request_refresh_gpiochips() -> void:
	# cleanup
	gpio_picker.clear()
	while pinout_grid.get_child_count() > 0:
		pinout_grid.get_child(0).queue_free()
		pinout_grid.remove_child(pinout_grid.get_child(0))
	# actual refresh
	RenderingServer.request_frame_drawn_callback(refresh_gpiochips)

func refresh_gpiochips() -> void:
	const gpiochip_pattern := '/dev/gpiochip'
	var res := ggpio.Run(['FL', '-a', gpiochip_pattern+'*', '5000'], env)
	if res[0] != OK:
		return ggpio._log(res[1], ggpio.LogLevel.ERROR)
	var res1 := res[1] as String
	var buffer := res1.substr(res1.find(' ')+1)

	var item_id := 0
	for line :String in buffer.split('\n', false):
		var chip_id := line.substr(gpiochip_pattern.length())
		gpio_picker.add_item('gpiochip%s'%chip_id)
		gpio_picker.set_item_metadata(item_id, chip_id)
		item_id += 1
	gpio_picker.select(-1)
	if not buffer.is_empty():
		gpio_picker.select(0)
		_on_gpio_picker_item_selected(0)

func _on_gpio_picker_item_selected(index :int)-> void:
	# create chip
	var chip_id :String = gpio_picker.get_item_metadata(gpio_picker.get_item_id(index))
	chip = ggpio.Chip.new(int(chip_id))
	chip.set_remote(env['LG_ADDR'], int(env['LG_PORT']))
	# get chip info
	var chip_info := chip.GIC()
	chip_gpio_count_value.text = '(%s GPIOs)'%String.num_int64(chip_info.gpio_count)
	chip_name_value.text = chip_info.name
	chip_usage_value.text = chip_info.usage
	# get line info in a single batched command
	var pins :Dictionary[int, ggpio.GPIO] = {}
	var GILcommand := PackedStringArray()
	for line_id :int in chip_info.gpio_count:
		pins[line_id] = ggpio.GPIO.new(line_id, chip)
		GILcommand.append_array(['GIL', chip_id, line_id])
	var res :Array = chip.run(GILcommand)
	if res[0] != OK:
		printerr("error GIL'ing gpios")
	var lines := (res[1] as String).split('\n')

	for line_id :int in chip_info.gpio_count:
		var gil := ggpio.GPIO.GILResult.Parse(lines[line_id])
		var pin_control :PinControl = preload('pin_control.tscn').instantiate()
		pin_control.gil = gil
		pin_control.gpio = pins[line_id]
		pinout_grid.add_child(pin_control)
