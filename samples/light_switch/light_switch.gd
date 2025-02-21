extends Control

@onready var container: HBoxContainer = %container
@onready var gpio_picker: OptionButton = %'gpio-picker'
@onready var switch_btn: CheckButton = %'switch-btn'


var sbc :ggpio.SBC
var dod :ggpio.devices.output.DigitalOutputDevice


func _ready() -> void:
	ggpio.log_level = ggpio.LogLevel.VERBOSE
	ggpio.Utils.ParseDotEnv()
	sbc = ggpio.SBC.new()
	var chip := sbc.open_chip()
	for gpio_id :int in chip.get_info().gpio_count:
		gpio_picker.add_item(String.num_int64(gpio_id))
	gpio_picker.item_selected.connect(
		func(index :int)->void:
			if self.dod != null:
				self.dod.close()
			self.dod = ggpio.devices.output.DigitalOutputDevice.Make(sbc.open_chip(), index)
	)

	switch_btn.toggled.connect(_on_switch_toggled)
	# resize window to scene (with a little extra for the dropdown menus)
	RenderingServer.request_frame_drawn_callback(
		func()->void:
			get_window().size = Vector2(container.size.x, 5*container.size.y)
	)

func _on_switch_toggled(is_toggled_on :bool) -> void:
	if is_toggled_on:
		dod.on()
	else:
		dod.off()
