extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dark green victory background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.04, 0.01)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Golden glow at top
	var glow := ColorRect.new()
	glow.color = Color(0.8, 0.7, 0.0, 0.15)
	glow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 120
	add_child(glow)

	# Center content
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -280
	vbox.offset_right  =  280
	vbox.offset_top    = -180
	vbox.offset_bottom =  180
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	add_child(vbox)

	var title := Label.new()
	title.text = "YOU WIN!"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub1 := Label.new()
	sub1.text = "You have escaped from Hell!"
	sub1.add_theme_font_size_override("font_size", 30)
	sub1.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	sub1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub1)

	var sub2 := Label.new()
	sub2.text = "All 10 waves conquered."
	sub2.add_theme_font_size_override("font_size", 20)
	sub2.add_theme_color_override("font_color", Color(0.55, 0.70, 0.55))
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub2)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(sp)

	var btn := Button.new()
	btn.text = "Back to Main Menu"
	btn.custom_minimum_size = Vector2(280, 62)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(btn)
