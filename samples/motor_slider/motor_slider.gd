extends Control
'''
A slider connected to a PhaseEnableMotor.
'''
@onready var container: VBoxContainer = %container
@onready var phase_selector: OptionButton = %'phase-selector'
@onready var enable_selector: OptionButton = %'enable-selector'
@onready var play_btn: Button = %'play-btn'
@onready var value_label: Label = %'value-label'
@onready var stop_btn: Button = %'stop-btn'
@onready var value_slider: HSlider = %'value-slider'

var chip :ggpio.Chip
var pem :ggpio.devices.output.PhaseEnableMotor

const PEM_UPDATE_DEBOUNCE_MS :int = 250
var _last_value_change :float = Time.get_unix_time_from_system()

func _ready() -> void:
	get_window().title = name
	ggpio.log_level = ggpio.LogLevel.VERBOSE
	ggpio.Utils.ParseDotEnv()
	ggpio.Init(true)

	chip = ggpio.SBC.new().open_chip()

	play_btn.disabled = true

	var chip_info := chip.get_info()
	if chip_info == null:
		return printerr('Could not read from chip %s'%chip.chip_id)

	for gpio_id :int in chip.get_info().gpio_count:
		phase_selector.add_item(String.num_int64(gpio_id))
		enable_selector.add_item(String.num_int64(gpio_id))
	phase_selector.item_selected.connect(_on_phase_selected)
	enable_selector.item_selected.connect(_on_enable_selected)

	play_btn.pressed.connect(_on_play_pressed)
	stop_btn.pressed.connect(_on_stop_pressed)

	value_slider.value_changed.connect(_update_pem)
	value_label.text = String.num(value_slider.value)
	# resize window to scene (with a little extra for the dropdown menus)
	RenderingServer.request_frame_drawn_callback(
		func()->void:
			get_window().size = Vector2(container.size.x, 4*container.size.y)
	)
	var phase_gpio :int = (OS.get_environment('GPIO_PHASE') as String).to_int()
	phase_selector.select(phase_gpio)
	var enable_gpio :int = (OS.get_environment('GPIO_ENABLE') as String).to_int()
	enable_selector.select(enable_gpio)

func _disable_item(btn:OptionButton, disabled_index :int) -> void:
	for index :int in btn.item_count:
		btn.set_item_disabled(index, index == disabled_index)

func _on_phase_selected(index :int) -> void:
	_disable_item(enable_selector, index)
	if index == enable_selector.selected:
		play_btn.disabled = true
		return
	play_btn.disabled = false

func _on_enable_selected(index :int) -> void:
	_disable_item(phase_selector, index)
	if index == phase_selector.selected:
		play_btn.disabled = true
		return
	play_btn.disabled = false

func _on_play_pressed() -> void:
	if pem != null:
		pem.close()
	assert(phase_selector.selected != enable_selector.selected)
	pem = ggpio.devices.output.PhaseEnableMotor.Make(
		chip,
		phase_selector.selected,
		enable_selector.selected,
	)
	pem.value = 0

func _on_stop_pressed()->void:
	value_slider.value = 0
	if pem != null:
		pem.stop()

func _update_pem(value :float) -> void:
	if pem == null:
		if value_slider.value != 0:
			value_slider.value = 0
		value_label.text = '!'
		return

func _process(_delta: float) -> void:
	if pem == null:
		return
	if is_equal_approx(pem.value, value_slider.value):
		return
	if Time.get_unix_time_from_system() - _last_value_change < PEM_UPDATE_DEBOUNCE_MS/1000.:
		return
	pem.value = value_slider.value
	value_label.text = String.num(value_slider.value)
	_last_value_change = Time.get_unix_time_from_system()
