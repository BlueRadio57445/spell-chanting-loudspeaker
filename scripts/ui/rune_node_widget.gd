class_name RuneNodeWidget extends PanelContainer

signal port_clicked(node_id: String, port_name: String, is_input: bool)
signal node_moved(node_id: String, new_pos: Vector2)
signal node_delete_requested(node_id: String)

var node_id: String
var rune: RuneBase
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var _port_buttons: Dictionary = {}  # port_name -> Button

func setup(p_node_id: String, p_rune: RuneBase) -> void:
	node_id = p_node_id
	rune = p_rune
	_build_ui()

func get_port_global_position(port_name: String) -> Vector2:
	if _port_buttons.has(port_name):
		var btn: Button = _port_buttons[port_name]
		return btn.global_position + btn.size / 2.0
	return global_position

func _build_ui() -> void:
	# 面板樣式
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = rune.icon_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(140, 0)

	var vbox := VBoxContainer.new()
	add_child(vbox)

	# 標題
	var title := Label.new()
	title.text = rune.rune_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", rune.icon_color)
	vbox.add_child(title)

	# Port 區域
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	# 左：input ports
	var in_col := VBoxContainer.new()
	in_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(in_col)

	for port in rune.ports_in:
		var btn := _create_port_button(port, true)
		in_col.add_child(btn)

	# 右：output ports
	var out_col := VBoxContainer.new()
	out_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(out_col)

	for port in rune.ports_out:
		var btn := _create_port_button(port, false)
		out_col.add_child(btn)

func _create_port_button(port: RunePort, is_input: bool) -> HBoxContainer:
	var row := HBoxContainer.new()

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(16, 16)
	btn.text = ""
	btn.tooltip_text = "%s (%s)%s" % [
		port.port_name,
		RuneEnums.port_type_name(port.port_type),
		"" if port.is_required else " [可選]"
	]

	var port_color: Color = RuneEnums.PORT_COLORS.get(port.port_type, Color.WHITE) as Color
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = port_color
	btn_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)

	var key: String = port.port_name
	_port_buttons[key] = btn
	btn.pressed.connect(func() -> void:
		port_clicked.emit(node_id, port.port_name, is_input)
	)

	var label := Label.new()
	label.text = port.port_name
	label.add_theme_font_size_override("font_size", 11)

	if is_input:
		row.add_child(btn)
		row.add_child(label)
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		row.add_child(btn)

	return row

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				drag_offset = mb.position
			else:
				is_dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# 右鍵：刪除（非 starter）
			if not node_id.begins_with("starter_"):
				node_delete_requested.emit(node_id)
	elif event is InputEventMouseMotion and is_dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		position += motion.relative
		node_moved.emit(node_id, position)
