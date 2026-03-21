class_name RuneCanvas extends Control

signal graph_changed

var graph: RuneGraph = RuneGraph.new()
var node_widgets: Dictionary = {}  # node_id -> RuneNodeWidget

# 連線狀態
var is_connecting: bool = false
var connect_from_node: String = ""
var connect_from_port: String = ""
var connect_from_is_input: bool = false
var mouse_pos: Vector2 = Vector2.ZERO

# 放置模式
var is_placing: bool = false
var placing_rune_id: String = ""

# 畫布平移
var canvas_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	_setup_starters()

func _setup_starters() -> void:
	var starter_ids: Array[String] = ["starter_q", "starter_w", "starter_e", "starter_r"]
	for i: int in starter_ids.size():
		var rune: RuneBase = RuneRegistry.create_instance(starter_ids[i])
		var node_id := "starter_%d" % i
		var pos := Vector2(30, 20 + i * 110)
		graph.add_node(node_id, rune, pos)
		_create_widget(node_id, rune, pos)

func add_rune_at(rune_id: String, pos: Vector2) -> void:
	var rune: RuneBase = RuneRegistry.create_instance(rune_id)
	var node_id := "node_%d" % Time.get_ticks_msec()
	var canvas_pos := pos - canvas_offset
	graph.add_node(node_id, rune, canvas_pos)
	_create_widget(node_id, rune, canvas_pos + canvas_offset)
	graph_changed.emit()

func start_placing(rune_id: String) -> void:
	is_placing = true
	placing_rune_id = rune_id

func _create_widget(node_id: String, rune: RuneBase, screen_pos: Vector2) -> void:
	var widget := RuneNodeWidget.new()
	add_child(widget)
	widget.setup(node_id, rune)
	widget.position = screen_pos
	widget.port_clicked.connect(_on_port_clicked)
	widget.node_moved.connect(_on_node_moved)
	widget.node_delete_requested.connect(_on_node_delete)
	node_widgets[node_id] = widget

func _on_port_clicked(node_id: String, port_name: String, is_input: bool) -> void:
	if not is_connecting:
		# 開始連線
		is_connecting = true
		connect_from_node = node_id
		connect_from_port = port_name
		connect_from_is_input = is_input
	else:
		# 嘗試完成連線
		if node_id == connect_from_node:
			# 點擊同一個節點，取消
			_cancel_connection()
			return
		# 確保一端是 input 一端是 output
		if is_input == connect_from_is_input:
			_cancel_connection()
			return

		var from_n: String
		var from_p: String
		var to_n: String
		var to_p: String

		if connect_from_is_input:
			# 起點是 input，終點是 output → 反轉
			from_n = node_id
			from_p = port_name
			to_n = connect_from_node
			to_p = connect_from_port
		else:
			from_n = connect_from_node
			from_p = connect_from_port
			to_n = node_id
			to_p = port_name

		# 移除 input port 上已有的連線（一個 input 只接一條線）
		graph.remove_edges_for_port(to_n, to_p, true)

		if graph.add_edge(from_n, from_p, to_n, to_p):
			print("[RuneCanvas] 連線: %s.%s -> %s.%s" % [from_n, from_p, to_n, to_p])
			graph_changed.emit()
		else:
			print("[RuneCanvas] 連線失敗（型別不符或形成環）")

		_cancel_connection()

func _cancel_connection() -> void:
	is_connecting = false
	connect_from_node = ""
	connect_from_port = ""
	queue_redraw()

func _on_node_moved(node_id: String, new_pos: Vector2) -> void:
	graph.move_node(node_id, new_pos - canvas_offset)
	queue_redraw()

func _on_node_delete(node_id: String) -> void:
	if node_widgets.has(node_id):
		node_widgets[node_id].queue_free()
		node_widgets.erase(node_id)
	graph.remove_node(node_id)
	graph_changed.emit()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		mouse_pos = motion_event.position
		if is_connecting:
			queue_redraw()
		if is_panning:
			var delta: Vector2 = motion_event.relative
			canvas_offset += delta
			for id: String in node_widgets:
				var w: RuneNodeWidget = node_widgets[id]
				var node_data: Dictionary = graph.nodes[id]
				w.position = (node_data["position"] as Vector2) + canvas_offset
			queue_redraw()

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		# 中鍵拖拽畫布
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mb.pressed
		# 左鍵：放置模式
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and is_placing:
			add_rune_at(placing_rune_id, get_local_mouse_position())
			is_placing = false
			placing_rune_id = ""
		# 右鍵：取消連線/放置
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if is_connecting:
				_cancel_connection()
			if is_placing:
				is_placing = false
				placing_rune_id = ""

func _draw() -> void:
	# 繪製已連接的 edge
	for edge: Dictionary in graph.edges:
		var from_id: String = edge["from_node"]
		var to_id: String = edge["to_node"]
		if not node_widgets.has(from_id) or not node_widgets.has(to_id):
			continue
		var from_widget: RuneNodeWidget = node_widgets[from_id]
		var to_widget: RuneNodeWidget = node_widgets[to_id]
		var from_pos: Vector2 = from_widget.get_port_global_position(edge["from_port"]) - global_position
		var to_pos: Vector2 = to_widget.get_port_global_position(edge["to_port"]) - global_position

		# 顏色取 output port 的型別
		var node_data: Dictionary = graph.nodes[from_id]
		var rune: RuneBase = node_data["rune"] as RuneBase
		var port_color: Color = Color.WHITE
		for port: RunePort in rune.ports_out:
			if port.port_name == edge["from_port"]:
				port_color = RuneEnums.PORT_COLORS.get(port.port_type, Color.WHITE) as Color
				break

		# 畫貝茲曲線
		_draw_connection(from_pos, to_pos, port_color)

	# 正在連線時畫虛線到滑鼠位置
	if is_connecting and node_widgets.has(connect_from_node):
		var widget: RuneNodeWidget = node_widgets[connect_from_node]
		var start_pos: Vector2 = widget.get_port_global_position(connect_from_port) - global_position
		var end_pos: Vector2 = get_local_mouse_position()
		_draw_connection(start_pos, end_pos, Color(1, 1, 1, 0.5))

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var cp_offset: float = maxf(absf(to.x - from.x) * 0.5, 50.0)
	var cp1: Vector2 = from + Vector2(cp_offset, 0)
	var cp2: Vector2 = to - Vector2(cp_offset, 0)

	var points: PackedVector2Array = []
	var steps: int = 20
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var p: Vector2 = from.bezier_interpolate(cp1, cp2, to, t)
		points.append(p)

	if points.size() >= 2:
		draw_polyline(points, color, 2.0, true)

func _process(_delta: float) -> void:
	# 持續重繪連線（widget 位置可能變化）
	queue_redraw()
