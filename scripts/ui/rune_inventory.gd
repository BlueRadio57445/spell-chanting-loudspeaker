class_name RuneInventory extends PanelContainer

const WIDGET_X: float = 8.0
const WIDGET_Y_START: float = 8.0
const WIDGET_GAP: float = 8.0

var _runes: Array[RuneBase] = []
var _widgets: Dictionary = {}  # RuneBase -> RuneNodeWidget

var canvas: RuneCanvas  # 由 main.gd 注入
var _widget_area: Control
var _scroll_container: ScrollContainer # 新增：滾動容器

# 拖動背包相關變數
var _is_dragging_view: bool = false
var _last_mouse_pos: Vector2

func _ready() -> void:
	# 1. 基礎設定
	clip_contents = true # 必須剪裁內容，否則滾動沒意義
	custom_minimum_size = Vector2(180, 0)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.9) # 稍微加深透明度
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	add_theme_stylebox_override("panel", bg_style)

	# 2. 佈局結構
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var title := Label.new()
	title.text = "符文背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 3. 建立滾動區域 (這是解決問題的核心)
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED # 關閉橫向滾動
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER # 隱藏醜醜的滾動條
	vbox.add_child(_scroll_container)

	# 內容容器
	_widget_area = Control.new()
	_widget_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_widget_area.custom_minimum_size.y = 1000 # 初始高度，會動態調整
	_scroll_container.add_child(_widget_area)

# --- 處理背包整體的拖動邏輯 ---
func _gui_input(event: InputEvent) -> void:
	# 使用滑鼠中鍵或右鍵來拖動背包視角
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_container.scroll_vertical -= 10
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_container.scroll_vertical += 10
			accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			_is_dragging_view = event.pressed
			_last_mouse_pos = event.position
			accept_event()
			
	if event is InputEventMouseMotion and _is_dragging_view:
		var diff = event.position.y - _last_mouse_pos.y
		_scroll_container.scroll_vertical -= diff
		_last_mouse_pos = event.position
		accept_event()

# --- 現有功能的調整 ---

func add_rune(rune: RuneBase) -> void:
	_runes.append(rune)
	var widget := RuneNodeWidget.new()
	# 注意：如果你之前有 .tscn 建議改用：
	# var widget = preload("res://scenes/ui/rune_node_widget.tscn").instantiate()
	widget.setup("inv_%d" % rune.get_instance_id(), rune)
	widget.node_drag_released.connect(_on_widget_drag_released)
	widget.node_delete_requested.connect(_on_widget_delete)
	_widget_area.add_child(widget)
	_widgets[rune] = widget
	_rebuild_positions.call_deferred()

func remove_rune(rune: RuneBase) -> void:
	if _widgets.has(rune):
		_widgets[rune].queue_free()
		_widgets.erase(rune)
	_runes.erase(rune)
	_rebuild_positions.call_deferred()

func _rebuild_positions() -> void:
	var y: float = WIDGET_Y_START
	for rune: RuneBase in _runes:
		if not _widgets.has(rune): continue
		var w: RuneNodeWidget = _widgets[rune]
		w.position = Vector2(WIDGET_X, y)
		# 這裡要確保 widget 有客觀的大小
		var h = w.size.y if w.size.y > 0 else 60 
		y += h + WIDGET_GAP
	
	# 動態更新內容區域高度，讓 ScrollContainer 知道可以滾多遠
	_widget_area.custom_minimum_size.y = y + 50

func _on_widget_drag_released(node_id: String, global_pos: Vector2) -> void:
	# ... (這部分邏輯不變，維持你組員寫的拖拽到畫布的功能) ...
	if canvas and canvas.get_global_rect().has_point(global_pos):
		var rune = _get_rune_by_node_id(node_id)
		if rune:
			var drag_offset = Vector2.ZERO
			if _widgets.has(rune):
				drag_offset = _widgets[rune].drag_offset
				_widgets[rune].queue_free()
				_widgets.erase(rune)
			_runes.erase(rune)
			canvas.add_rune_instance(rune, global_pos - canvas.global_position - drag_offset)
	elif get_global_rect().has_point(global_pos):
		var rune = _get_rune_by_node_id(node_id)
		if rune:
			# 這裡要修正座標，因為有了滾動，local_y 要加上滾動距離
			var local_y = global_pos.y - _widget_area.global_position.y
			var new_index = _get_drop_index(rune, local_y)
			_runes.erase(rune)
			_runes.insert(new_index, rune)
	_rebuild_positions.call_deferred()

# ... (其餘輔助函式 _get_drop_index 等保持不變) ...

func _get_drop_index(dragged_rune: RuneBase, local_y: float) -> int:
	var idx: int = 0
	for rune: RuneBase in _runes:
		if rune == dragged_rune:
			continue
		if not _widgets.has(rune):
			idx += 1
			continue
		var w: RuneNodeWidget = _widgets[rune] as RuneNodeWidget
		if local_y < w.position.y + w.size.y * 0.5:
			return idx
		idx += 1
	return idx


func _on_widget_delete(node_id: String) -> void:
	var rune: RuneBase = _get_rune_by_node_id(node_id)
	if rune:
		remove_rune(rune)


func _get_rune_by_node_id(node_id: String) -> RuneBase:
	for rune: RuneBase in _widgets:
		var w: RuneNodeWidget = _widgets[rune] as RuneNodeWidget
		if w.node_id == node_id:
			return rune
	return null
