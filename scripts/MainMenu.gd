extends Control

func _ready() -> void:
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
	start_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	vbox.add_child(start_btn)

	# Exit button
	var exit_btn := Button.new()
	exit_btn.text = "EXIT GAME"
	exit_btn.custom_minimum_size = Vector2(280, 62)
	exit_btn.add_theme_font_size_override("font_size", 28)
	exit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(exit_btn)
