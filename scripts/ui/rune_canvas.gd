class_name RuneCanvas extends Control

signal graph_changed

var graph: RuneGraph = RuneGraph.new()
var node_widgets: Dictionary = {}  # node_id -> RuneNodeWidget

var rune_inventory: RuneInventory  # 由 main.gd 注入

# --- 連線狀態 ---
var is_connecting: bool = false
var connect_from_node: String = ""
var connect_from_port: String = ""
var connect_from_is_input: bool = false
var connect_source_port_type: RuneEnums.PortType = RuneEnums.PortType.ENERGY

# --- 重新路由狀態 ---
var is_rerouting: bool = false
var reroute_original_from_node: String = ""
var reroute_original_from_port: String = ""
var reroute_original_to_node: String = ""
var reroute_original_to_port: String = ""
var reroute_origin_pos: Vector2 = Vector2.ZERO  # 安全圓圈中心
const REROUTE_SAFE_RADIUS: float = 35.0

# --- 畫布平移 ---
var canvas_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var is_drag_panning: bool = false

# --- 連線懸停 ---
var hovered_edge_index: int = -1
const EDGE_HOVER_DISTANCE: float = 8.0

# --- 邊緣自動捲動 ---
const AUTO_SCROLL_MARGIN: float = 40.0
const AUTO_SCROLL_SPEED: float = 300.0

# --- 快取連線曲線點（用於懸停碰撞） ---
var _edge_curves: Array[PackedVector2Array] = []

func _ready() -> void:
	clip_contents = true
	_setup_starters()

func _setup_starters() -> void:
	var starter_ids: Array[String] = ["starter_q", "starter_w", "starter_e", "starter_r"]
	for i: int in starter_ids.size():
		var rune: RuneBase = RuneRegistry.create_instance(starter_ids[i])
		var node_id: String = "starter_%d" % i
		var pos: Vector2 = Vector2(30, 20 + i * 110)
		graph.add_node(node_id, rune, pos)
		_create_widget(node_id, rune, pos)

func add_rune_instance(rune: RuneBase, pos: Vector2) -> void:
	var node_id: String = "node_%d" % Time.get_ticks_msec()
	var canvas_pos: Vector2 = pos - canvas_offset
	graph.add_node(node_id, rune, canvas_pos)
	_create_widget(node_id, rune, pos)
	graph_changed.emit()
	_refresh_all_connection_states()

# =============================================================================
#  Widget 管理
# =============================================================================

func _create_widget(node_id: String, rune: RuneBase, screen_pos: Vector2) -> void:
	var widget := RuneNodeWidget.new()
	add_child(widget)
	widget.setup(node_id, rune)
	widget.position = screen_pos
	widget.port_clicked.connect(_on_port_clicked)
	widget.node_moved.connect(_on_node_moved)
	widget.node_delete_requested.connect(_on_node_delete)
	widget.node_drag_released.connect(_on_widget_drag_released)
	node_widgets[node_id] = widget

func _on_node_moved(node_id: String, new_pos: Vector2) -> void:
	graph.move_node(node_id, new_pos - canvas_offset)
	queue_redraw()

func _on_node_delete(node_id: String) -> void:
	if node_widgets.has(node_id):
		node_widgets[node_id].queue_free()
		node_widgets.erase(node_id)
	graph.remove_node(node_id)
	graph_changed.emit()
	_refresh_all_connection_states()
	queue_redraw()

# =============================================================================
#  連線邏輯（Click-Click）
# =============================================================================

func _on_port_clicked(node_id: String, port_name: String, is_input: bool) -> void:
	# 如果點擊的是已連線的 input port，進入重新路由模式
	if is_input and not is_connecting and not is_rerouting:
		var existing_edge: Dictionary = _find_edge_to_input(node_id, port_name)
		if not existing_edge.is_empty():
			_start_reroute(existing_edge, node_id, port_name)
			return

	if not is_connecting:
		_start_connection(node_id, port_name, is_input)
	else:
		_try_complete_connection(node_id, port_name, is_input)

func _start_connection(node_id: String, port_name: String, is_input: bool) -> void:
	is_connecting = true
	connect_from_node = node_id
	connect_from_port = port_name
	connect_from_is_input = is_input
	# 取得 source port type
	connect_source_port_type = _get_port_type(node_id, port_name, is_input)
	# 高亮所有相容 port
	_highlight_all_compatible(connect_source_port_type, is_input)

func _try_complete_connection(node_id: String, port_name: String, is_input: bool) -> void:
	if node_id == connect_from_node:
		_cancel_connection()
		return
	if is_input == connect_from_is_input:
		_cancel_connection()
		return

	var from_n: String
	var from_p: String
	var to_n: String
	var to_p: String

	if connect_from_is_input:
		from_n = node_id
		from_p = port_name
		to_n = connect_from_node
		to_p = connect_from_port
	else:
		from_n = connect_from_node
		from_p = connect_from_port
		to_n = node_id
		to_p = port_name

	# 移除 input port 上已有的連線
	graph.remove_edges_for_port(to_n, to_p, true)
	# 移除 output port 上已有的連線（一對一限制）
	graph.remove_edges_for_port(from_n, from_p, false)

	if graph.add_edge(from_n, from_p, to_n, to_p):
		graph_changed.emit()

	_cancel_connection()
	_refresh_all_connection_states()

func _cancel_connection() -> void:
	is_connecting = false
	connect_from_node = ""
	connect_from_port = ""
	_clear_all_highlights()
	queue_redraw()

# =============================================================================
#  重新路由（Reroute）
# =============================================================================

func _start_reroute(edge: Dictionary, input_node_id: String, input_port_name: String) -> void:
	is_rerouting = true
	reroute_original_from_node = edge["from_node"]
	reroute_original_from_port = edge["from_port"]
	reroute_original_to_node = edge["to_node"]
	reroute_original_to_port = edge["to_port"]

	# 安全圓圈位置 = 原始 input port 的位置
	var widget: RuneNodeWidget = node_widgets[input_node_id]
	reroute_origin_pos = widget.get_port_global_position(input_port_name) - global_position

	# 移除舊連線
	graph.remove_edge(edge["from_node"], edge["from_port"], edge["to_node"], edge["to_port"])
	_refresh_all_connection_states()

	# 進入連線模式：從 output 端開始
	is_connecting = true
	connect_from_node = reroute_original_from_node
	connect_from_port = reroute_original_from_port
	connect_from_is_input = false
	connect_source_port_type = _get_port_type(connect_from_node, connect_from_port, false)
	_highlight_all_compatible(connect_source_port_type, false)

func _finish_reroute_on_empty() -> void:
	# 檢查是否在安全圓圈內
	var mouse_local: Vector2 = get_local_mouse_position()
	var dist: float = mouse_local.distance_to(reroute_origin_pos)
	if dist <= REROUTE_SAFE_RADIUS:
		# 在安全圈內放開 → 恢復原始連線
		graph.add_edge(reroute_original_from_node, reroute_original_from_port,
			reroute_original_to_node, reroute_original_to_port)
	# 在安全圈外放開 → 連線斷開（不恢復）
	_reset_reroute_state()
	_cancel_connection()
	_refresh_all_connection_states()
	graph_changed.emit()

func _reset_reroute_state() -> void:
	is_rerouting = false
	reroute_original_from_node = ""
	reroute_original_from_port = ""
	reroute_original_to_node = ""
	reroute_original_to_port = ""

# =============================================================================
#  視覺回饋：port 高亮 & 連線狀態
# =============================================================================

func _highlight_all_compatible(source_type: RuneEnums.PortType, source_is_input: bool) -> void:
	for id: String in node_widgets:
		var w: RuneNodeWidget = node_widgets[id]
		if id == connect_from_node:
			w.clear_highlights()
		else:
			w.highlight_compatible_ports(source_type, source_is_input)

func _clear_all_highlights() -> void:
	for id: String in node_widgets:
		var w: RuneNodeWidget = node_widgets[id]
		w.clear_highlights()

func _refresh_all_connection_states() -> void:
	for id: String in node_widgets:
		var connected_ports: Array = []
		# 檢查 input ports
		for e: Dictionary in graph.edges:
			if e["to_node"] == id:
				connected_ports.append(e["to_port"])
			if e["from_node"] == id:
				connected_ports.append(e["from_port"])
		var w: RuneNodeWidget = node_widgets[id]
		w.update_connection_states(connected_ports)

# =============================================================================
#  連線懸停偵測
# =============================================================================

func _update_edge_hover(mouse_local: Vector2) -> void:
	hovered_edge_index = -1
	for i: int in _edge_curves.size():
		var curve: PackedVector2Array = _edge_curves[i]
		if _point_near_polyline(mouse_local, curve, EDGE_HOVER_DISTANCE):
			hovered_edge_index = i
			break

func _point_near_polyline(point: Vector2, polyline: PackedVector2Array, max_dist: float) -> bool:
	if polyline.size() < 2:
		return false
	for i: int in polyline.size() - 1:
		var a: Vector2 = polyline[i]
		var b: Vector2 = polyline[i + 1]
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, a, b)
		if point.distance_to(closest) <= max_dist:
			return true
	return false

# =============================================================================
#  輸入處理
# =============================================================================

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if is_connecting:
			queue_redraw()
		if is_panning or is_drag_panning:
			var delta: Vector2 = motion_event.relative
			canvas_offset += delta
			for id: String in node_widgets:
				var w: RuneNodeWidget = node_widgets[id]
				var node_data: Dictionary = graph.nodes[id]
				w.position = (node_data["position"] as Vector2) + canvas_offset
			queue_redraw()
		# 連線懸停偵測（非連線/放置/拖拽模式時）
		if not is_connecting and not is_panning and not is_drag_panning:
			_update_edge_hover(get_local_mouse_position())
			queue_redraw()

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		# 中鍵拖拽畫布
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mb.pressed
		# 左鍵放開：停止拖拽平移
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			is_drag_panning = false
		# 左鍵按下
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if is_connecting:
				# 只有點擊在空白處才取消，點在 widget 上讓 port button 處理
				if not _is_click_on_widget(get_local_mouse_position()):
					if is_rerouting:
						_finish_reroute_on_empty()
					else:
						_cancel_connection()
			elif not _is_click_on_widget(get_local_mouse_position()) and get_global_rect().has_point(mb.global_position):
				is_drag_panning = true
		# 右鍵：取消連線
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if is_connecting:
				if is_rerouting:
					# 右鍵取消重新路由 → 恢復原始連線
					graph.add_edge(reroute_original_from_node, reroute_original_from_port,
						reroute_original_to_node, reroute_original_to_port)
					_reset_reroute_state()
					_refresh_all_connection_states()
					graph_changed.emit()
				_cancel_connection()

	# Escape 取消
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			if is_connecting:
				if is_rerouting:
					graph.add_edge(reroute_original_from_node, reroute_original_from_port,
						reroute_original_to_node, reroute_original_to_port)
					_reset_reroute_state()
					_refresh_all_connection_states()
					graph_changed.emit()
				_cancel_connection()

# =============================================================================
#  邊緣自動捲動
# =============================================================================

func _do_auto_scroll(delta: float) -> void:
	if not is_connecting:
		return
	var mouse_local: Vector2 = get_local_mouse_position()
	var scroll_dir: Vector2 = Vector2.ZERO
	if mouse_local.x < AUTO_SCROLL_MARGIN:
		scroll_dir.x = 1.0
	elif mouse_local.x > size.x - AUTO_SCROLL_MARGIN:
		scroll_dir.x = -1.0
	if mouse_local.y < AUTO_SCROLL_MARGIN:
		scroll_dir.y = 1.0
	elif mouse_local.y > size.y - AUTO_SCROLL_MARGIN:
		scroll_dir.y = -1.0
	if scroll_dir != Vector2.ZERO:
		var scroll_amount: Vector2 = scroll_dir * AUTO_SCROLL_SPEED * delta
		canvas_offset += scroll_amount
		for id: String in node_widgets:
			var w: RuneNodeWidget = node_widgets[id]
			var node_data: Dictionary = graph.nodes[id]
			w.position = (node_data["position"] as Vector2) + canvas_offset

# =============================================================================
#  繪製
# =============================================================================

func _draw() -> void:
	_edge_curves.clear()

	# 繪製已連接的 edge
	for i: int in graph.edges.size():
		var edge: Dictionary = graph.edges[i]
		var from_id: String = edge["from_node"]
		var to_id: String = edge["to_node"]
		if not node_widgets.has(from_id) or not node_widgets.has(to_id):
			_edge_curves.append(PackedVector2Array())
			continue
		var from_widget: RuneNodeWidget = node_widgets[from_id]
		var to_widget: RuneNodeWidget = node_widgets[to_id]
		var from_pos: Vector2 = from_widget.get_port_global_position(edge["from_port"]) - global_position
		var to_pos: Vector2 = to_widget.get_port_global_position(edge["to_port"]) - global_position

		var node_data: Dictionary = graph.nodes[from_id]
		var rune: RuneBase = node_data["rune"] as RuneBase
		var port_color: Color = Color.WHITE
		for port: RunePort in rune.ports_out:
			if port.port_name == edge["from_port"]:
				port_color = RuneEnums.PORT_COLORS.get(port.port_type, Color.WHITE) as Color
				break

		var is_hovered: bool = (i == hovered_edge_index)
		var line_width: float = 4.0 if is_hovered else 2.0
		var draw_color: Color = port_color.lightened(0.3) if is_hovered else port_color

		var curve: PackedVector2Array = _compute_bezier(from_pos, to_pos)
		_edge_curves.append(curve)
		if curve.size() >= 2:
			draw_polyline(curve, draw_color, line_width, true)

	# 正在連線/重新路由時的橡皮筋線
	if is_connecting and node_widgets.has(connect_from_node):
		var widget: RuneNodeWidget = node_widgets[connect_from_node]
		var start_pos: Vector2 = widget.get_port_global_position(connect_from_port) - global_position
		var end_pos: Vector2 = get_local_mouse_position()
		var rubber_color: Color = RuneEnums.PORT_COLORS.get(connect_source_port_type, Color.WHITE) as Color
		rubber_color.a = 0.6
		var curve: PackedVector2Array = _compute_bezier(start_pos, end_pos)
		if curve.size() >= 2:
			draw_polyline(curve, rubber_color, 2.0, true)

	# 重新路由時的安全圓圈
	if is_rerouting:
		draw_arc(reroute_origin_pos, REROUTE_SAFE_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.2), 1.0)

func _compute_bezier(from: Vector2, to: Vector2) -> PackedVector2Array:
	var cp_offset: float = maxf(absf(to.x - from.x) * 0.5, 50.0)
	var cp1: Vector2 = from + Vector2(cp_offset, 0)
	var cp2: Vector2 = to - Vector2(cp_offset, 0)
	var points: PackedVector2Array = []
	var steps: int = 20
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var p: Vector2 = from.bezier_interpolate(cp1, cp2, to, t)
		points.append(p)
	return points

func _process(delta: float) -> void:
	_do_auto_scroll(delta)
	queue_redraw()

# =============================================================================
#  工具函式
# =============================================================================

func _get_port_type(node_id: String, port_name: String, is_input: bool) -> RuneEnums.PortType:
	var node_data: Dictionary = graph.nodes[node_id]
	var rune: RuneBase = node_data["rune"] as RuneBase
	var ports: Array[RunePort] = rune.ports_in if is_input else rune.ports_out
	for port: RunePort in ports:
		if port.port_name == port_name:
			return port.port_type
	return RuneEnums.PortType.ENERGY

func _find_edge_to_input(node_id: String, port_name: String) -> Dictionary:
	for e: Dictionary in graph.edges:
		if e["to_node"] == node_id and e["to_port"] == port_name:
			return e
	return {}

func _is_click_on_widget(local_pos: Vector2) -> bool:
	for id: String in node_widgets:
		var w: RuneNodeWidget = node_widgets[id]
		var rect: Rect2 = Rect2(w.position, w.size)
		if rect.has_point(local_pos):
			return true
	return false

# =============================================================================
#  節點拖回背包
# =============================================================================

func _on_widget_drag_released(node_id: String, global_pos: Vector2) -> void:
	if get_global_rect().has_point(global_pos):
		return  # 在畫布內，正常拖拽結束
	if node_id.begins_with("starter_"):
		_snap_widget_to_canvas(node_id)
		return
	if not graph.nodes.has(node_id):
		return
	if rune_inventory and rune_inventory.get_global_rect().has_point(global_pos):
		var rune: RuneBase = graph.nodes[node_id]["rune"] as RuneBase
		rune_inventory.add_rune(rune)
		_on_node_delete(node_id)
	else:
		_snap_widget_to_canvas(node_id)

func _snap_widget_to_canvas(node_id: String) -> void:
	if not node_widgets.has(node_id) or not graph.nodes.has(node_id):
		return
	var widget: RuneNodeWidget = node_widgets[node_id]
	var clamped: Vector2 = widget.position.clamp(Vector2.ZERO, size - widget.size)
	widget.position = clamped
	graph.move_node(node_id, clamped - canvas_offset)
	queue_redraw()
