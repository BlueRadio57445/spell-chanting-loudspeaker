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
	var skipped_nodes: Dictionary = {}  # 被跳過的節點，其下游也全部斷鏈

	for node_id: String in order:
		var node_info: Dictionary = graph.nodes[node_id]
		var rune: RuneBase = node_info["rune"] as RuneBase

		# 斷鏈檢查：如果任何上游節點被跳過，此節點也跳過
		var upstream_skipped: bool = false
		for edge: Dictionary in graph.get_edges_to_node(node_id):
			if skipped_nodes.has(edge["from_node"]):
				upstream_skipped = true
				break
		if upstream_skipped:
			skipped_nodes[node_id] = true
			print("[RuneExecutor] 斷鏈跳過 %s：上游節點未執行" % rune.rune_name)
			continue

		# 收集上游輸出作為此節點的輸入
		var inputs: Dictionary = graph.collect_inputs(node_id, port_data)

		# 檢查所有必要輸入是否滿足，未滿足則跳過並斷鏈
		var missing_required: bool = false
		for port: RunePort in rune.ports_in:
			if port.is_required and not inputs.has(port.port_name):
				missing_required = true
				break
		if missing_required:
			skipped_nodes[node_id] = true
			print("[RuneExecutor] 跳過 %s：必要輸入未滿足" % rune.rune_name)
			continue

		# 播放音檔
		if rune.audio:
			audio_player.stream = rune.audio
			audio_player.play()
			await audio_player.finished

		# 執行符文
		var outputs: Dictionary = rune.execute(inputs, get_parent())
		port_data[node_id] = outputs
		rune_executed.emit(node_id, rune)
		print("[RuneExecutor] 執行: %s -> %s" % [rune.rune_name, outputs])

	is_casting = false
	casting_finished.emit()
