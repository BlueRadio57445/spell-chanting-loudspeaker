class_name RuneExecutor extends Node

signal casting_started(starter_id: String)
signal rune_executed(node_id: String, rune: RuneBase)
signal casting_finished
signal casting_failed(reason: String)

var is_casting: bool = false
var graph: RuneGraph

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# starter_slot 0~3 對應 starter_q ~ starter_r
const STARTER_IDS: Array[String] = ["starter_0", "starter_1", "starter_2", "starter_3"]

func trigger_starter(slot: int) -> void:
	if is_casting:
		casting_failed.emit("正在施法中")
		return
	if slot < 0 or slot >= STARTER_IDS.size():
		return
	var starter_id := STARTER_IDS[slot]
	if not graph or not graph.nodes.has(starter_id):
		casting_failed.emit("起始符文不存在")
		return
	_execute_chain(starter_id)

func _execute_chain(starter_id: String) -> void:
	is_casting = true
	casting_started.emit(starter_id)

	var order := graph.get_topological_order(starter_id)
	var port_data: Dictionary = {}

	for node_id: String in order:
		var node_info: Dictionary = graph.nodes[node_id]
		var rune: RuneBase = node_info["rune"] as RuneBase

		# 收集上游輸出作為此節點的輸入
		var inputs: Dictionary = graph.collect_inputs(node_id, port_data)

		# 播放音檔
		if rune.audio:
			audio_player.stream = rune.audio
			audio_player.play()
			await audio_player.finished

		# 執行符文
		var outputs: Dictionary = rune.execute(inputs)
		port_data[node_id] = outputs
		rune_executed.emit(node_id, rune)
		print("[RuneExecutor] 執行: %s -> %s" % [rune.rune_name, outputs])

	is_casting = false
	casting_finished.emit()
