extends Control

var _settings_overlay: Control
var _volume_value_label: Label
var _resolution_dropdown: OptionButton
var _display_mode_dropdown: OptionButton
var _volume_slider: HSlider

# Pending settings (applied only on Save)
var _pending_volume: float
var _pending_fullscreen: bool
var _pending_resolution_idx: int

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

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
	settings_btn.pressed.connect(_open_settings)
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
	vbox.offset_left   = -280
	vbox.offset_right  =  280
	vbox.offset_top    = -260
	vbox.offset_bottom =  260
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	overlay.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# ── Volume ──
	var vol_row := _make_setting_row("Volume")
	vbox.add_child(vol_row)

	var slider_row := HBoxContainer.new()
	slider_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slider_row.add_theme_constant_override("separation", 12)
	vbox.add_child(slider_row)

	var min_label := Label.new()
	min_label.text = "0"
	min_label.add_theme_font_size_override("font_size", 18)
	min_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	slider_row.add_child(min_label)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.value = MusicManager.get_volume()
	_volume_slider.custom_minimum_size = Vector2(300, 30)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_child(_volume_slider)

	var max_label := Label.new()
	max_label.text = "100"
	max_label.add_theme_font_size_override("font_size", 18)
	max_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	slider_row.add_child(max_label)

	_volume_value_label = Label.new()
	_volume_value_label.text = "%d" % int(_volume_slider.value)
	_volume_value_label.add_theme_font_size_override("font_size", 20)
	_volume_value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_volume_value_label)

	_volume_slider.value_changed.connect(func(value: float): _volume_value_label.text = "%d" % int(value))

	# ── Display Mode ──
	var mode_row := _make_setting_row("Display Mode")
	vbox.add_child(mode_row)

	_display_mode_dropdown = OptionButton.new()
	_display_mode_dropdown.custom_minimum_size = Vector2(280, 40)
	_display_mode_dropdown.add_theme_font_size_override("font_size", 20)
	_display_mode_dropdown.add_item("Windowed", 0)
	_display_mode_dropdown.add_item("Fullscreen", 1)
	_display_mode_dropdown.selected = 1 if _is_fullscreen() else 0
	_display_mode_dropdown.item_selected.connect(func(idx: int): _resolution_dropdown.disabled = (idx == 1))
	vbox.add_child(_display_mode_dropdown)

	# ── Resolution ──
	var res_row := _make_setting_row("Resolution")
	vbox.add_child(res_row)

	_resolution_dropdown = OptionButton.new()
	_resolution_dropdown.custom_minimum_size = Vector2(280, 40)
	_resolution_dropdown.add_theme_font_size_override("font_size", 20)
	var current_size := DisplayServer.window_get_size()
	var selected_idx := 3  # default to 1920x1080
	for i in RESOLUTIONS.size():
		var r: Vector2i = RESOLUTIONS[i]
		_resolution_dropdown.add_item("%d x %d" % [r.x, r.y], i)
		if r == current_size:
			selected_idx = i
	_resolution_dropdown.selected = selected_idx
	_resolution_dropdown.disabled = _is_fullscreen()
	vbox.add_child(_resolution_dropdown)

	# ── Buttons row ──
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(180, 54)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_settings_back)
	btn_row.add_child(back_btn)

	var save_btn := Button.new()
	save_btn.text = "SAVE CHANGES"
	save_btn.custom_minimum_size = Vector2(220, 54)
	save_btn.add_theme_font_size_override("font_size", 24)
	save_btn.pressed.connect(_on_settings_save)
	btn_row.add_child(save_btn)

	return overlay

func _make_setting_row(label_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _snapshot_settings() -> void:
	_pending_volume = MusicManager.get_volume()
	_pending_fullscreen = _is_fullscreen()
	var current_size := DisplayServer.window_get_size()
	_pending_resolution_idx = 3
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == current_size:
			_pending_resolution_idx = i
			break

func _open_settings() -> void:
	_snapshot_settings()
	# Reset UI to current live values
	_volume_slider.value = _pending_volume
	_volume_value_label.text = "%d" % int(_pending_volume)
	_display_mode_dropdown.selected = 1 if _pending_fullscreen else 0
	_resolution_dropdown.selected = _pending_resolution_idx
	_resolution_dropdown.disabled = _pending_fullscreen
	_settings_overlay.visible = true

func _on_settings_back() -> void:
	# Discard changes — close without applying
	_settings_overlay.visible = false

func _on_settings_save() -> void:
	# Apply volume
	MusicManager.set_volume(_volume_slider.value)
	# Apply display mode
	var want_fullscreen := (_display_mode_dropdown.selected == 1)
	var was_fullscreen := _is_fullscreen()
	if want_fullscreen and not was_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not want_fullscreen:
		if was_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Apply resolution in windowed mode
		var idx := _resolution_dropdown.selected
		if idx >= 0 and idx < RESOLUTIONS.size():
			var res: Vector2i = RESOLUTIONS[idx]
			get_window().size = res
			await get_tree().process_frame
			get_window().size = res
			_center_window()
	_settings_overlay.visible = false

func _center_window() -> void:
	var screen := DisplayServer.screen_get_size()
	var win := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen - win) / 2)
