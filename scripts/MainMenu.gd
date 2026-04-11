extends Control

var _settings_overlay: Control
var _volume_value_label: Label

func _ready() -> void:
	MusicManager.play_track(MusicManager.Track.MENU)
	_build_ui()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ---- Dark hell background ----
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.0, 0.01)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Atmospheric bottom glow
	var glow := ColorRect.new()
	glow.color = Color(0.5, 0.05, 0.0, 0.25)
	glow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	glow.offset_top = -140
	add_child(glow)

	# ---- Center content ----
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left  = -220
	vbox.offset_right =  220
	vbox.offset_top   = -200
	vbox.offset_bottom =  200
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "ESCAPE\nFROM HELL"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.18, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Tagline
	var tagline := Label.new()
	tagline.text = "~ Survive 10 Waves of Darkness ~"
	tagline.add_theme_font_size_override("font_size", 19)
	tagline.add_theme_color_override("font_color", Color(0.75, 0.35, 0.1))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tagline)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 34)
	vbox.add_child(sp)

	# Start button
	var start_btn := Button.new()
	start_btn.text = "START GAME"
	start_btn.custom_minimum_size = Vector2(280, 62)
	start_btn.add_theme_font_size_override("font_size", 28)
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Arena.tscn"))
	vbox.add_child(start_btn)

	# Settings button
	var settings_btn := Button.new()
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(280, 62)
	settings_btn.add_theme_font_size_override("font_size", 28)
	settings_btn.pressed.connect(func(): _settings_overlay.visible = true)
	vbox.add_child(settings_btn)

	# Exit button
	var exit_btn := Button.new()
	exit_btn.text = "EXIT GAME"
	exit_btn.custom_minimum_size = Vector2(280, 62)
	exit_btn.add_theme_font_size_override("font_size", 28)
	exit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(exit_btn)

	# ---- Settings overlay ----
	_settings_overlay = _build_settings_overlay()
	_settings_overlay.visible = false
	add_child(_settings_overlay)


func _build_settings_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -260
	vbox.offset_right  =  260
	vbox.offset_top    = -160
	vbox.offset_bottom =  160
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	overlay.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Volume section
	var vol_label := Label.new()
	vol_label.text = "Volume"
	vol_label.add_theme_font_size_override("font_size", 22)
	vol_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(vol_label)

	# Slider row: 0 label | slider | 100 label
	var slider_row := HBoxContainer.new()
	slider_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slider_row.add_theme_constant_override("separation", 12)
	vbox.add_child(slider_row)

	var min_label := Label.new()
	min_label.text = "0"
	min_label.add_theme_font_size_override("font_size", 18)
	min_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	slider_row.add_child(min_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = MusicManager.get_volume()
	slider.custom_minimum_size = Vector2(300, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_child(slider)

	var max_label := Label.new()
	max_label.text = "100"
	max_label.add_theme_font_size_override("font_size", 18)
	max_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	slider_row.add_child(max_label)

	# Current value display
	_volume_value_label = Label.new()
	_volume_value_label.text = "%d" % int(slider.value)
	_volume_value_label.add_theme_font_size_override("font_size", 20)
	_volume_value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_volume_value_label)

	slider.value_changed.connect(_on_volume_changed)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(200, 54)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(func(): _settings_overlay.visible = false)
	vbox.add_child(back_btn)

	return overlay


func _on_volume_changed(value: float) -> void:
	MusicManager.set_volume(value)
	_volume_value_label.text = "%d" % int(value)
