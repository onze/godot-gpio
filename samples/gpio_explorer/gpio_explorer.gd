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

var _sbc :ggpio.SBC
var _chip :ggpio.Chip
var _chip_info :ggpio.Chip.ChipInfo
var _sync_timer := Timer.new()

func _ready() -> void:
	#var env :Dictionary[String, String] = {
	var env :Dictionary = {
		LG_ADDR=ggpio.DEFAULT_LG_ADDR,
		LG_PORT=ggpio.DEFAULT_LG_PORT,
	}
	_parse_command_line(env)
	add_child(_sync_timer)
	_sync_timer.timeout.connect(_sync_gpios)
	_sync_timer.stop()
	get_window().title = 'GGPIO Explorer -- v%s'%[
		ProjectSettings.get_setting('application/config/version')
	]
	ggpio.log_level = ggpio.LogLevel.DEBUG

	ggpio.Init(true)
	for kv :Array in [['LG_ADDR', ggpio.DEFAULT_LG_ADDR], ['LG_PORT', ggpio.DEFAULT_LG_PORT]]:
		var key :String = kv[0]
		var default_value :String = kv[1]
		var value :String = env.get(key)
		if value in [null, '']:
			value = default_value
		print('%s=%s'%[key, value])
		OS.set_environment(key, value)
	_sbc = ggpio.SBC.new(env.get('LG_ADDR'), env.get('LG_PORT'))

	refresh_gpio_btn.pressed.connect(_start_populating_gpiochips)
	gpio_picker.item_selected.connect(_on_gpio_picker_item_selected)
	sync_freq_btn.item_selected.connect(_update_sync_freq)
	_start_populating_gpiochips.call_deferred()

func _start_populating_gpiochips() -> void:
	# cleanup
	gpio_picker.clear()
	while pinout_grid.get_child_count() > 0:
		pinout_grid.get_child(0).queue_free()
		pinout_grid.remove_child(pinout_grid.get_child(0))
	_sync_timer.stop()
	# actual refresh
	_continue_populating_gpiochips()

func _continue_populating_gpiochips() -> void:
	var chip_ids := _sbc.list_chips()
	var item_id := 0
	for chip_id :String in chip_ids:
		gpio_picker.add_item('gpiochip%s'%chip_id)
		gpio_picker.set_item_metadata(item_id, chip_id)
		item_id += 1

	if not chip_ids.is_empty():
		gpio_picker.select(0)
		_on_gpio_picker_item_selected(0)

func _on_gpio_picker_item_selected(index :int)-> void:
	# create chip
	var chip_id :String = gpio_picker.get_item_metadata(gpio_picker.get_item_id(index))
	_chip = _sbc.open_chip(chip_id)
	# get chip info
	_chip_info = _chip.get_info()
	chip_gpio_count_value.text = '(%s GPIOs)'%String.num_int64(_chip_info.gpio_count)
	chip_name_value.text = _chip_info.name
	chip_usage_value.text = _chip_info.usage
	# pupolate lineFeeds
	for line_id :int in _chip_info.gpio_count:
		var pin_control :PinControl = preload('pin_control.tscn').instantiate()
		pin_control.gpio = _chip.open_gpio(line_id)
		pinout_grid.add_child(pin_control)
	# manually ask for this refresh
	_sync_gpios()

func _sync_gpios() -> void:
	# get line info in a single batched command
	#var pins :Dictionary[int, PinControl] = {}
	var pins :Dictionary = {}
	var GIL_query := ggpio.lg.LGCommand.new().share(_sbc.share_id)
	for line_id :int in pinout_grid.get_child_count():
		var pin_control :PinControl = pinout_grid.get_child(line_id)
		pins[line_id] = pin_control
		GIL_query.append_array(['GIL', _chip.chip_id, line_id])

	var res :Array = GIL_query.run(_sbc)
	if res[0] != OK:
		printerr("error GIL'ing gpios")
	var GILlines := (res[1] as String).split('\n')

	var dt :float = Time.get_ticks_msec() / 1000.
	for line_id :int in pins:
		var gpio_info := ggpio.GPIO.GPIOInfo.Parse(GILlines[line_id])
		var pin_control :PinControl = pins[line_id]
		pin_control.gpio_info = gpio_info

	# now building GR query (had to pull GIL info first, to know which GPIO to read)
	var GR_query := ggpio.lg.LGCommand.new().share(_sbc.share_id)
	var read_gpio_indexes := PackedInt32Array()
	for line_id :int in pins:
		var pin_control :PinControl = pins[line_id]
		if pin_control.gpio_info.is_GPIO:
			read_gpio_indexes.append(line_id)
			GR_query.append_array(['GR', _chip.chip_id, line_id])
	res = GR_query.run(_sbc)
	if res[0] != OK:
		printerr("error GR'ing gpios")
	var GRlines := (res[1] as String).split('\n')
	var GRlines_index := 0
	for read_gpio_index:int in read_gpio_indexes:
		var pin_control :PinControl = pins[read_gpio_index]
		var gr := float(GRlines[GRlines_index])
		GRlines_index += 1
		pin_control.voltage = Vector2(dt, gr)

func _update_sync_freq(item_index :int):
	# id contains the frequency value
	var freq :float = float(sync_freq_btn.get_item_id(item_index))
	_sync_timer.stop()
	if is_zero_approx(freq):
		return
	_sync_timer.start(1./freq)


func _usage() -> void:
	print('USAGE: --host=HOST --port=PORT')

func _parse_command_line(env :Dictionary) -> void:
	var args := OS.get_cmdline_user_args()
	if '--help' in args:
		return _usage()
	for arg :String in args:
		var tokens := arg.split('=')
		var key := tokens[0]
		match key:
			'--host':
				if tokens.size() != 2:
					return _usage()
				env['LG_ADDR'] = tokens[1]
			'--port':
				if tokens.size() != 2:
					return _usage()
				env['LG_PORT'] = tokens[1]
