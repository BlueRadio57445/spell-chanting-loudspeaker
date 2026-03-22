class_name RuneNodeWidget extends PanelContainer

signal port_clicked(node_id: String, port_name: String, is_input: bool)
signal node_moved(node_id: String, new_pos: Vector2)
signal node_delete_requested(node_id: String)
signal node_drag_released(node_id: String, global_pos: Vector2)

var node_id: String
var rune: RuneBase
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var _charge_label: Label = null

# port_name -> { "button": Button, "port_type": PortType, "is_input": bool, "style_normal": StyleBoxFlat, "style_connected": StyleBoxFlat }
var _port_data: Dictionary = {}

func setup(p_node_id: String, p_rune: RuneBase) -> void:
	node_id = p_node_id
	rune = p_rune
	_build_ui()

func get_port_global_position(port_name: String, is_input: bool = true) -> Vector2:
	var key: String = ("in:" if is_input else "out:") + port_name
	if _port_data.has(key):
		var data: Dictionary = _port_data[key]
		var btn: Button = data["button"]
		return btn.global_position + btn.size / 2.0
	# 向後相容：如果找不到帶前綴的 key，嘗試無前綴（不會有同名衝突的舊節點）
	if _port_data.has(port_name):
		var data: Dictionary = _port_data[port_name]
		var btn: Button = data["button"]
		return btn.global_position + btn.size / 2.0
	return global_position

## 取得此節點上第一個與 source_type 相容的 port（用於拖到節點空白處自動對接）
func find_compatible_port(source_type: RuneEnums.PortType, need_input: bool) -> String:
	var ports: Array[RunePort] = rune.ports_in if need_input else rune.ports_out
	for port: RunePort in ports:
		if RuneEnums.can_connect(source_type, port.port_type) if need_input else RuneEnums.can_connect(port.port_type, source_type):
			return port.port_name
	return ""

## 高亮所有與 source_type 相容的 port，暗淡不相容的
func highlight_compatible_ports(source_type: RuneEnums.PortType, source_is_input: bool) -> void:
	for port_name: String in _port_data:
		var data: Dictionary = _port_data[port_name]
		var btn: Button = data["button"]
		var port_type: int = data["port_type"]
		var is_input: bool = data["is_input"]
		# 只高亮對面方向的 port
		if is_input == source_is_input:
			_set_port_dimmed(btn, data)
			continue
		var compatible: bool
		if source_is_input:
			compatible = RuneEnums.can_connect(port_type, source_type)
		else:
			compatible = RuneEnums.can_connect(source_type, port_type)
		if compatible:
			_set_port_highlighted(btn, data)
		else:
			_set_port_dimmed(btn, data)

## 清除所有高亮，恢復正常樣式
func clear_highlights() -> void:
	for port_name: String in _port_data:
		var data: Dictionary = _port_data[port_name]
		var btn: Button = data["button"]
		_set_port_normal(btn, data)

## 更新 port 的連線狀態色（已連線 = 實心亮色，未連線 = 半透明暗色）
func update_connection_states(connected_ports: Array) -> void:
	for key: String in _port_data:
		var data: Dictionary = _port_data[key]
		var btn: Button = data["button"]
		var is_connected: bool = connected_ports.has(data["port_name"])
		data["is_connected"] = is_connected
		if is_connected:
			_apply_style(btn, data["style_connected"])
		else:
			_apply_style(btn, data["style_normal"])

func _build_ui() -> void:
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

	var title := Label.new()
	title.text = rune.rune_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", rune.icon_color)
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	var in_col := VBoxContainer.new()
	in_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(in_col)

	var required_in: Array[RunePort] = []
	var optional_in: Array[RunePort] = []
	for port: RunePort in rune.ports_in:
		if port.is_required:
			required_in.append(port)
		else:
			optional_in.append(port)

	var has_both: bool = required_in.size() > 0 and optional_in.size() > 0
	if has_both:
		_add_section_label(in_col, "必要")
	for port: RunePort in required_in:
		in_col.add_child(_create_port_row(port, true))
	if optional_in.size() > 0:
		if has_both:
			_add_section_label(in_col, "可選")
		for port: RunePort in optional_in:
			in_col.add_child(_create_port_row(port, true))

	var out_col := VBoxContainer.new()
	out_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(out_col)

	for port: RunePort in rune.ports_out:
		var row: HBoxContainer = _create_port_row(port, false)
		out_col.add_child(row)

	if rune is PassiveRunes.PassiveRuneBase:
		_charge_label = Label.new()
		_charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_charge_label.add_theme_font_size_override("font_size", 14)
		_charge_label.add_theme_color_override("font_color", rune.icon_color)
		vbox.add_child(_charge_label)
		_update_charge_label()

func _process(_delta: float) -> void:
	if _charge_label != null:
		_update_charge_label()

func _update_charge_label() -> void:
	var pr: PassiveRunes.PassiveRuneBase = rune as PassiveRunes.PassiveRuneBase
	var filled: String = "●".repeat(pr.stored_charges)
	var empty: String = "○".repeat(pr.max_charges - pr.stored_charges)
	_charge_label.text = filled + empty

func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(lbl)

func _create_port_row(port: RunePort, is_input: bool) -> HBoxContainer:
	var row := HBoxContainer.new()

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(16, 16)
	btn.text = ""
	btn.tooltip_text = "%s (%s)" % [port.port_name, RuneEnums.port_type_name(port.port_type)]

	var port_color: Color = RuneEnums.PORT_COLORS.get(port.port_type, Color.WHITE) as Color

	# 正常樣式（未連線 = 半透明空心感）
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = port_color.darkened(0.5)
	style_normal.bg_color.a = 0.5
	style_normal.border_color = port_color
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(8)

	# 已連線樣式（實心亮色）
	var style_connected := StyleBoxFlat.new()
	style_connected.bg_color = port_color
	style_connected.set_corner_radius_all(8)

	_apply_style(btn, style_normal)

	# 儲存 port 資料（用 "in:name" / "out:name" 作 key 避免同名衝突）
	var port_key: String = ("in:" if is_input else "out:") + port.port_name
	_port_data[port_key] = {
		"button": btn,
		"port_type": port.port_type,
		"is_input": is_input,
		"port_name": port.port_name,
		"is_connected": false,
		"base_color": port_color,
		"style_normal": style_normal,
		"style_connected": style_connected,
	}

	btn.pressed.connect(func() -> void:
		port_clicked.emit(node_id, port.port_name, is_input)  # 仍然 emit 原始 port_name
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

func _set_port_highlighted(btn: Button, data: Dictionary) -> void:
	var color: Color = data["base_color"]
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	_apply_style(btn, style)
	btn.custom_minimum_size = Vector2(20, 20)

func _set_port_dimmed(btn: Button, data: Dictionary) -> void:
	var color: Color = data["base_color"]
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.7)
	style.bg_color.a = 0.3
	style.set_corner_radius_all(8)
	_apply_style(btn, style)
	btn.custom_minimum_size = Vector2(16, 16)

func _set_port_normal(btn: Button, data: Dictionary) -> void:
	var is_connected: bool = data["is_connected"]
	var style: StyleBoxFlat = data["style_connected"] if is_connected else data["style_normal"]
	_apply_style(btn, style)
	btn.custom_minimum_size = Vector2(16, 16)

func _apply_style(btn: Button, style: StyleBoxFlat) -> void:
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				drag_offset = mb.position
			else:
				if is_dragging:
					node_drag_released.emit(node_id, get_global_mouse_position())
				is_dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if not node_id.begins_with("starter_"):
				node_delete_requested.emit(node_id)
	elif event is InputEventMouseMotion and is_dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		position += motion.relative
		node_moved.emit(node_id, position)
