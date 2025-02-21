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
@onready var hbox: HBoxContainer = %hbox
@onready var name_hbox: HBoxContainer = %'name-hbox'
@onready var name_label: Label = %'name-label'
@onready var number_label: Label = %'number-label'
@onready var pin_container: MarginContainer = %'pin-container'
@onready var pin_icon: TextureRect = %'pin-icon'
@onready var pin_center: TextureRect = %'pin-center'
@onready var icons_hbox: HBoxContainer = %'icons-hbox'
@onready var char_icons: Label = %'char-icons'

var gil :lgpio.GPIO.GILResult
var gpio :lgpio.GPIO

const GPIO_COLOR := '#859900'
const PULLUP_COLOR := Color.CRIMSON
const PULLDOWN_COLOR := Color.CORNFLOWER_BLUE
const UNSUPPORTED_COLOR := Color.DIM_GRAY

func _ready() -> void:
	var reversed_layout := get_index() % 2 == 1
	var reverse_layout_direction := Control.LayoutDirection.LAYOUT_DIRECTION_RTL
	if reversed_layout:
		layout_direction = Control.LayoutDirection.LAYOUT_DIRECTION_RTL
		reverse_layout_direction = Control.LayoutDirection.LAYOUT_DIRECTION_LTR
	icons_hbox.layout_direction = reverse_layout_direction
	# gpio_id, fl, user,       purpose
	# 7         7  "SPI_CE1_N" "spi0 CS1"
	if gil == null:
		gil = lgpio.GPIO.GILResult.new()
		gil.gpio_id = -1
		gil.user = 'user'
		gil.purpose = 'purpose'
		gil.line_flags = lgpio.LineFlag.PULL_UP

	number_label.text = String.num_int64(gil.gpio_id)
	name_label.text = gil.user
	name = name_label.text
	if gil.is_GPIO:
		pin_icon.modulate = Color(GPIO_COLOR)
	else:
		pin_icon.modulate = UNSUPPORTED_COLOR

	var name_tooltip :Array[String] = []
	if not gil.purpose.is_empty():
		name_label.text += ' (%s)'%gil.purpose
	if gil.gpio_id == 2:
		print('ok')
	name_tooltip.append('%s->%s'%[gil.line_flags, lgpio.GetModeString(gil.line_flags)])
	name_hbox.tooltip_text = '\n'.join(name_tooltip)

	var char_icons_texts :Array[String] = []
	var icons_hbox_tooltip :Array[String] = []
	var add_char_icon := func(flag :int, chars :String, tt :String)->bool:
		if gil.line_flags & flag:
			# in use by kernel
			char_icons_texts.append(chars)
			icons_hbox_tooltip.append(tt)
			return true
		return false
	#if add_char_icon.call(1, 'K', 'K: '+lgpio.ModeStrings[1]):
		#name_hbox.modulate = Color.GRAY
		#icons_hbox.modulate = Color.GRAY
		#number_label.modulate = Color.GRAY
	add_char_icon.call(1<<8 | 1<<16, '(I)', 'I: Input')
	add_char_icon.call(1<<1 | 1<<9, '(O)', 'O: Output')
	add_char_icon.call(1<<10, '(A)', '(A): Alert')
	if add_char_icon.call(lgpio.LineFlag.PULL_UP, '(PU)', 'PU: Pull Up'):
		pin_center.modulate = PULLUP_COLOR
		pin_container.tooltip_text = 'Pull Up'
	elif add_char_icon.call(lgpio.LineFlag.PULL_DOWN, '(PD)', 'PD: Pull Down'):
		pin_center.modulate = PULLDOWN_COLOR
		pin_container.tooltip_text = 'Pull Down'
	else:
		pin_center.modulate = Color.WHITE
		pin_container.tooltip_text = ''
	if reversed_layout:
		char_icons_texts.reverse()
	char_icons.text = ' '.join(char_icons_texts)
	icons_hbox.tooltip_text += '|'.join(icons_hbox_tooltip)
