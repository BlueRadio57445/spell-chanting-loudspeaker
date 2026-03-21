class_name RuneInventory extends PanelContainer

signal rune_selected(rune_id: String)

var _buttons: Dictionary = {}

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(160, 0)

	var vbox := VBoxContainer.new()
	add_child(vbox)

	var title := Label.new()
	title.text = "背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	_populate(list)

func _populate(container: VBoxContainer) -> void:
	for rune_id in RuneRegistry.get_all_ids():
		var template: RuneBase = RuneRegistry.get_template(rune_id)
		# 跳過起始符文（它們固定在畫布左側）
		if template.category == RuneEnums.RuneCategory.STARTER:
			continue

		var btn := Button.new()
		btn.text = template.rune_name
		btn.tooltip_text = template.description
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = template.icon_color.darkened(0.6)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style: StyleBoxFlat = btn_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = template.icon_color.darkened(0.4)
		btn.add_theme_stylebox_override("hover", hover_style)

		var id_capture: String = rune_id  # 閉包捕獲
		btn.pressed.connect(func() -> void:
			rune_selected.emit(id_capture)
		)

		container.add_child(btn)
		_buttons[rune_id] = btn
