extends PanelContainer

@onready var _bar: ProgressBar = $HBoxContainer/ProgressBar

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Player 在 SubViewport 內，可能比此節點晚初始化，延遲一幀再連接
	await get_tree().process_frame
	var p: Player = Player.Instance
	if p:
		_bar.max_value = p.max_hp
		_bar.value = p.hp
		p.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, maximum: int) -> void:
	_bar.max_value = maximum
	_bar.value = current
