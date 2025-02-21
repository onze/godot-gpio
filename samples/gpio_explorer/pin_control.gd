extends Control
class_name PinControl
'''
Styling:
- greyed text: in use by the Kernel
- pin circle:
	- green: GPIO
- pin center:
	- red: pullup
	- blue: pulldown
'''
const Plot = preload('plot.gd')

const VOLTAGE_PLOT_WINDOW_S := 10.

@onready var hbox: HBoxContainer = %hbox
@onready var name_hbox: HBoxContainer = %'name-hbox'
@onready var name_label: Label = %'name-label'
@onready var voltage_plot: Plot = %'voltage-plot'
@onready var icons_hbox: HBoxContainer = %'icons-hbox'
@onready var char_icons: Label = %'char-icons'
@onready var number_label: Label = %'number-label'
@onready var pin_container: MarginContainer = %'pin-container'
@onready var pin_icon: TextureRect = %'pin-icon'
@onready var pin_center: TextureRect = %'pin-center'

var gpio :ggpio.GPIO
# null in _ready, then updated async
var gpio_info :ggpio.GPIO.GPIOInfo = null:
	get: return gpio_info
	set(value):
		gpio_info = value
		if gpio_info != null:
			_refresh_from_gpio_info()
var voltage := Vector2.ZERO:
	get: return voltage
	set(value):
		voltage = value
		_refresh_from_voltage()

const GPIO_COLOR := '#859900'
const PULLUP_COLOR := Color.CRIMSON
const PULLDOWN_COLOR := Color.CORNFLOWER_BLUE
const UNSUPPORTED_COLOR := Color.DIM_GRAY

var reversed_layout :bool:
	get: return get_index() % 2 == 1

func _ready() -> void:
	var reverse_layout_direction := Control.LayoutDirection.LAYOUT_DIRECTION_RTL
	if reversed_layout:
		layout_direction = Control.LayoutDirection.LAYOUT_DIRECTION_RTL
		reverse_layout_direction = Control.LayoutDirection.LAYOUT_DIRECTION_LTR
	icons_hbox.layout_direction = reverse_layout_direction
	# gpio_id, fl, user,       purpose
	# 7         7  "SPI_CE1_N" "spi0 CS1"
	if gpio_info == null:
		gpio_info = ggpio.GPIO.GPIOInfo.new()
		gpio_info.gpio_id = -1 if gpio == null else gpio.gpio_id
		gpio_info.user = '<user>'
		gpio_info.purpose = '<purpose>'
		#gpio_info.line_flags = 0

	# plot setup
	voltage_plot.y_min = 0.
	voltage_plot.y_max = 1.
	var dt := Time.get_ticks_msec()
	voltage_plot.x_min = dt-VOLTAGE_PLOT_WINDOW_S
	voltage_plot.x_max = dt+1
	voltage_plot.background_color = Color.TRANSPARENT
	voltage_plot.curve_color_high = Color.GREEN_YELLOW
	voltage_plot.curve_color_low = Color.DARK_GREEN
	voltage_plot.width = 1.

func _refresh_from_gpio_info() -> void:
	number_label.text = String.num_int64(gpio_info.gpio_id)
	name_label.text = gpio_info.user
	if not name_label.text.is_empty():
		name = name_label.text
	if gpio_info.is_GPIO:
		pin_icon.modulate = Color(GPIO_COLOR)
	else:
		pin_icon.modulate = UNSUPPORTED_COLOR

	var name_tooltip :Array[String] = []
	if not gpio_info.purpose.is_empty():
		name_label.text += ' (%s)'%gpio_info.purpose
	name_tooltip.append('%s->%s'%[gpio_info.line_flags, ggpio.GetModeString(gpio_info.line_flags)])
	name_hbox.tooltip_text = '\n'.join(name_tooltip)

	var char_icons_texts :Array[String] = []
	var icons_hbox_tooltip :Array[String] = []
	var add_char_icon := func(flag :int, chars :String, tt :String)->bool:
		if gpio_info.line_flags & flag:
			# in use by kernel
			char_icons_texts.append(chars)
			icons_hbox_tooltip.append(tt)
			return true
		return false
	#if add_char_icon.call(1, 'K', 'K: '+ggpio.ModeStrings[1]):
		#name_hbox.modulate = Color.GRAY
		#icons_hbox.modulate = Color.GRAY
		#number_label.modulate = Color.GRAY
	add_char_icon.call(1<<8 | 1<<16, '(I)', 'I: Input')
	add_char_icon.call(1<<1 | 1<<9, '(O)', 'O: Output')
	add_char_icon.call(1<<10, '(A)', '(A): Alert')
	if add_char_icon.call(ggpio.LineFlag.PULL_UP, '(PU)', 'PU: Pull Up'):
		pin_center.modulate = PULLUP_COLOR
		pin_container.tooltip_text = 'Pull Up'
	elif add_char_icon.call(ggpio.LineFlag.PULL_DOWN, '(PD)', 'PD: Pull Down'):
		pin_center.modulate = PULLDOWN_COLOR
		pin_container.tooltip_text = 'Pull Down'
	else:
		pin_center.modulate = Color.WHITE
		pin_container.tooltip_text = ''
	if reversed_layout:
		char_icons_texts.reverse()
	char_icons.text = ' '.join(char_icons_texts)
	icons_hbox.tooltip_text = '|'.join(icons_hbox_tooltip)

func _refresh_from_voltage() -> void:
	voltage_plot.x_min = voltage.x-VOLTAGE_PLOT_WINDOW_S
	voltage_plot.x_max = voltage.x+1
	voltage_plot.add_point(Vector2(voltage.x, voltage.y))
