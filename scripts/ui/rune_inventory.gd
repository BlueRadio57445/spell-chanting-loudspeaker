class_name RuneInventory extends PanelContainer

const WIDGET_X: float = 8.0
const WIDGET_Y_START: float = 8.0
const WIDGET_GAP: float = 8.0

var _runes: Array[RuneBase] = []
var _widgets: Dictionary = {}  # RuneBase -> RuneNodeWidget

var canvas: RuneCanvas  # 由 main.gd 注入
var _widget_area: Control


func _ready() -> void:
	clip_contents = false
	custom_minimum_size = Vector2(180, 0)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0.3, 0.3, 0.4)
	bg_style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", bg_style)

	var vbox := VBoxContainer.new()
	add_child(vbox)

	var title := Label.new()
	title.text = "背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_widget_area = Control.new()
	_widget_area.clip_contents = false
	_widget_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_widget_area)


func add_rune(rune: RuneBase) -> void:
	_runes.append(rune)
	var widget := RuneNodeWidget.new()
	widget.setup("inv_%d" % rune.get_instance_id(), rune)
	widget.node_drag_released.connect(_on_widget_drag_released)
	widget.node_delete_requested.connect(_on_widget_delete)
	_widget_area.add_child(widget)
	_widgets[rune] = widget
	_rebuild_positions.call_deferred()


func remove_rune(rune: RuneBase) -> void:
	if _widgets.has(rune):
		(_widgets[rune] as RuneNodeWidget).queue_free()
		_widgets.erase(rune)
	_runes.erase(rune)
	_rebuild_positions.call_deferred()


func _rebuild_positions() -> void:
	var y: float = WIDGET_Y_START
	for rune: RuneBase in _runes:
		if not _widgets.has(rune):
			continue
		var w: RuneNodeWidget = _widgets[rune] as RuneNodeWidget
		w.position = Vector2(WIDGET_X, y)
		y += maxf(w.size.y, w.custom_minimum_size.y) + WIDGET_GAP


func _on_widget_drag_released(node_id: String, global_pos: Vector2) -> void:
	if canvas and canvas.get_global_rect().has_point(global_pos):
		var rune: RuneBase = _get_rune_by_node_id(node_id)
		if rune:
			# 移除背包 widget
			if _widgets.has(rune):
				(_widgets[rune] as RuneNodeWidget).queue_free()
				_widgets.erase(rune)
			_runes.erase(rune)
			# 在畫布上放置
			canvas.add_rune_instance(rune, global_pos - canvas.global_position)
	_rebuild_positions.call_deferred()


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
