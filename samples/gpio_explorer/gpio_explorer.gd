extends Control

#region UI
@onready var gpio_picker: OptionButton = %'gpio-picker'
@onready var refresh_gpio_btn: Button = %'refresh-gpio-btn'
@onready var chip_name_value: Label = %'chip-name-value'
@onready var chip_gpio_count_value: Label = %'chip-gpio-count-value'
@onready var chip_usage_value: Label = %'chip-usage-value'
@onready var sync_freq_btn: OptionButton = %'sync-freq-btn'
#endregion

#region pinout
@onready var pinout_grid: GridContainer = %'pinout-grid'
#endregion

var _chip :ggpio.Chip
var _chip_info :ggpio.Chip.GICResult
var _sync_timer := Timer.new()

var env :Dictionary[String, String] = {
	LG_ADDR='goshrimp.local',
	LG_PORT=String.num_int64(ggpio.DEFAULT_LG_PORT),
}

func _ready() -> void:
	add_child(_sync_timer)
	_sync_timer.timeout.connect(_sync_gpios)
	get_window().title = 'GGPIO -- GPIO Explorer'
	ggpio.log_level = ggpio.LogLevel.DEBUG
	OS.set_environment('LG_ADDR', env.get('LG_ADDR'))
	ggpio.Init(true)

	_chip = ggpio.Chip.new(0)
	_chip.set_remote('goshrimp.local')
	refresh_gpio_btn.pressed.connect(_start_populating_gpiochips)
	gpio_picker.item_selected.connect(_on_gpio_picker_item_selected)
	sync_freq_btn.item_selected.connect(_update_sync_freq)
	_start_populating_gpiochips()

func _start_populating_gpiochips() -> void:
	# cleanup
	gpio_picker.clear()
	while pinout_grid.get_child_count() > 0:
		pinout_grid.get_child(0).queue_free()
		pinout_grid.remove_child(pinout_grid.get_child(0))
	_sync_timer.stop()
	# actual refresh
	RenderingServer.request_frame_drawn_callback(_continue_populating_gpiochips)

func _continue_populating_gpiochips() -> void:
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
	_chip = ggpio.Chip.new(int(chip_id))
	_chip.set_remote(env['LG_ADDR'], int(env['LG_PORT']))
	# get chip info
	_chip_info = _chip.GIC()
	chip_gpio_count_value.text = '(%s GPIOs)'%String.num_int64(_chip_info.gpio_count)
	chip_name_value.text = _chip_info.name
	chip_usage_value.text = _chip_info.usage
	# pupolate lineFeeds
	for line_id :int in _chip_info.gpio_count:
		var pin_control :PinControl = preload('pin_control.tscn').instantiate()
		pin_control.gpio = ggpio.GPIO.new(line_id, _chip)
		pinout_grid.add_child(pin_control)
	# manually ask for this refresh
	_sync_gpios()

func _sync_gpios() -> void:
	# get line info in a single batched command
	var pins :Dictionary[int, PinControl] = {}
	var GILcommand := PackedStringArray()
	for line_id :int in _chip_info.gpio_count:
		pins[line_id] = pinout_grid.get_child(line_id) as PinControl
		GILcommand.append_array(['GIL', _chip.id, line_id])

	var res :Array = _chip.run(GILcommand)
	if res[0] != OK:
		printerr("error GIL'ing gpios")
	var lines := (res[1] as String).split('\n')

	for line_id :int in pins:
		var gil := ggpio.GPIO.GILResult.Parse(lines[line_id])
		var pin_control :PinControl = pins[line_id]
		pin_control.gil = gil

func _update_sync_freq(item_index :int):
	# id contains the frequency value
	var freq :float = float(sync_freq_btn.get_item_id(item_index))
	_sync_timer.stop()
	if is_zero_approx(freq):
		return
	#_sync_timer.paused()
	_sync_timer.start(1./freq)
