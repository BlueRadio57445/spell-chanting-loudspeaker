extends Node

var _is_paused: bool = false
var _prev_position: Vector2 = Vector2.ZERO
var _initialized: bool = false
var _player_connected: bool = false
var _prev_hp: int = 0

func _ready() -> void:
	var executor: RuneExecutor = get_parent() as RuneExecutor
	executor.casting_started.connect(_on_casting_started)
	executor.casting_finished.connect(_on_casting_finished)

func _process(delta: float) -> void:
	if _is_paused:
		return
	if Player.Instance == null:
		return
	if not _initialized:
		_prev_position = Player.Instance.global_position
		_initialized = true
		return
	if not _player_connected:
		Player.Instance.health_changed.connect(_on_health_changed)
		_prev_hp = Player.Instance.hp
		_player_connected = true

	var current_pos: Vector2 = Player.Instance.global_position
	var distance: float = _prev_position.distance_to(current_pos)
	_prev_position = current_pos

	if distance > 0.0:
		for rune: PassiveRunes.KineticEnergy in _get_runes(PassiveRunes.KineticEnergy):
			rune.accumulate_movement(distance)

	for rune: PassiveRunes.Meditation in _get_runes(PassiveRunes.Meditation):
		rune.accumulate_time(delta)

	if Player.Instance.is_moving:
		for rune: PassiveRunes.Steadfast in _get_runes(PassiveRunes.Steadfast):
			rune.reset_timer()
	else:
		for rune: PassiveRunes.Steadfast in _get_runes(PassiveRunes.Steadfast):
			rune.accumulate_stillness(delta)

func _get_runes(type: Variant) -> Array:
	var result: Array = []
	var executor: RuneExecutor = get_parent() as RuneExecutor
	if executor.graph == null:
		return result
	for node_id: String in executor.graph.nodes:
		var rune: RuneBase = executor.graph.nodes[node_id]["rune"] as RuneBase
		if is_instance_of(rune, type):
			result.append(rune)
	return result

func _on_health_changed(current: int, _maximum: int) -> void:
	if current < _prev_hp:
		var damage: float = float(_prev_hp - current)
		for rune: PassiveRunes.BloodTribute in _get_runes(PassiveRunes.BloodTribute):
			rune.accumulate_damage(damage)
	_prev_hp = current

func _on_casting_started(_starter_id: String) -> void:
	_is_paused = true
	for rune: PassiveRunes.Meditation in _get_runes(PassiveRunes.Meditation):
		rune.reset_timer()

func _on_casting_finished() -> void:
	_is_paused = false
	if Player.Instance:
		_prev_position = Player.Instance.global_position
