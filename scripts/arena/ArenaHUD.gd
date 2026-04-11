extends Control

var hp_bar: ProgressBar
var hp_label: Label
var wave_label: Label
var stat_labels: Dictionary = {}
var log_display: RichTextLabel
var _log_lines: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func _build_ui() -> void:
	# HP Bar (top-left)
	var hp_container := VBoxContainer.new()
	hp_container.position = Vector2(16, 12)
	hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_container)

	var hp_title := Label.new()
	hp_title.text = "HP"
	hp_title.add_theme_font_size_override("font_size", 14)
	hp_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	hp_container.add_child(hp_title)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 18)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_container.add_child(hp_bar)

	hp_label = Label.new()
	hp_label.text = "100 / 100"
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hp_container.add_child(hp_label)

	# Stats (below HP)
	var stat_box := VBoxContainer.new()
	stat_box.position = Vector2(16, 80)
	stat_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stat_box)

	for stat_name in ["ATK", "DEF", "SPK", "REG"]:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stat_box.add_child(l)
		stat_labels[stat_name] = l

	# Wave counter (top-center)
	wave_label = Label.new()
	wave_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	wave_label.offset_top = 10
	wave_label.add_theme_font_size_override("font_size", 22)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wave_label)

	# Combat log (bottom)
	log_display = RichTextLabel.new()
	log_display.bbcode_enabled = true
	log_display.scroll_following = true
	log_display.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	log_display.offset_top = -90
	log_display.offset_left = 16
	log_display.offset_right = -16
	log_display.add_theme_font_size_override("normal_font_size", 13)
	log_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(log_display)

func update_hp(current: int, mx: int) -> void:
	hp_bar.max_value = mx
	hp_bar.value = current
	hp_label.text = "%d / %d" % [current, mx]

func update_wave(wave: int) -> void:
	wave_label.text = "WAVE %d / %d" % [wave, GameData.TOTAL_WAVES]

func update_stats() -> void:
	stat_labels["ATK"].text = "ATK: %d" % GameData.effective_attack()
	stat_labels["DEF"].text = "DEF: %d" % GameData.player_armor
	if GameData.player_spikes > 0:
		stat_labels["SPK"].text = "SPK: %d" % GameData.player_spikes
		stat_labels["SPK"].visible = true
	else:
		stat_labels["SPK"].visible = false
	stat_labels["REG"].text = "REG: %d" % GameData.effective_regen()

func log_msg(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 5:
		_log_lines = _log_lines.slice(-5)
	log_display.clear()
	log_display.append_text("\n".join(_log_lines))

func clear_log() -> void:
	_log_lines.clear()
	log_display.clear()
