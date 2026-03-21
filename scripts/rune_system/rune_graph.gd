class_name RuneGraph extends RefCounted

# node_id -> { "rune": RuneBase, "position": Vector2 }
var nodes: Dictionary = {}
# Array of { "from_node": String, "from_port": String, "to_node": String, "to_port": String }
var edges: Array[Dictionary] = []

func add_node(id: String, rune: RuneBase, pos: Vector2) -> void:
	nodes[id] = {"rune": rune, "position": pos}

func remove_node(id: String) -> void:
	nodes.erase(id)
	# 移除所有相關 edge
	edges = edges.filter(func(e: Dictionary) -> bool:
		return e["from_node"] != id and e["to_node"] != id
	)

func move_node(id: String, pos: Vector2) -> void:
	if nodes.has(id):
		nodes[id]["position"] = pos

func add_edge(from_node: String, from_port: String, to_node: String, to_port: String) -> bool:
	# 檢查節點存在
	if not nodes.has(from_node) or not nodes.has(to_node):
		return false
	# 不能自連
	if from_node == to_node:
		return false
	# 檢查 port 存在且型別匹配
	var out_port: RunePort = _find_output_port(from_node, from_port)
	var in_port: RunePort = _find_input_port(to_node, to_port)
	if out_port == null or in_port == null:
		return false
	if not RuneEnums.can_connect(out_port.port_type, in_port.port_type):
		return false
	# 檢查 output port 連線數上限
	if out_port.max_out_connections >= 0:
		var out_count: int = 0
		for e in edges:
			if e["from_node"] == from_node and e["from_port"] == from_port:
				out_count += 1
		if out_count >= out_port.max_out_connections:
			return false
	# 檢查重複
	for e in edges:
		if e["from_node"] == from_node and e["from_port"] == from_port \
				and e["to_node"] == to_node and e["to_port"] == to_port:
			return false
	# 檢查是否會形成環
	var edge: Dictionary = {"from_node": from_node, "from_port": from_port, "to_node": to_node, "to_port": to_port}
	edges.append(edge)
	if _has_cycle():
		edges.pop_back()
		return false
	return true

func remove_edge(from_node: String, from_port: String, to_node: String, to_port: String) -> void:
	for i in range(edges.size() - 1, -1, -1):
		var e := edges[i]
		if e["from_node"] == from_node and e["from_port"] == from_port \
				and e["to_node"] == to_node and e["to_port"] == to_port:
			edges.remove_at(i)
			return

func remove_edges_for_port(node_id: String, port_name: String, is_input: bool) -> void:
	for i in range(edges.size() - 1, -1, -1):
		var e := edges[i]
		if is_input and e["to_node"] == node_id and e["to_port"] == port_name:
			edges.remove_at(i)
		elif not is_input and e["from_node"] == node_id and e["from_port"] == port_name:
			edges.remove_at(i)

func get_topological_order(start_node_id: String) -> Array[String]:
	# 找出從 start_node 可達的所有節點，然後拓樸排序
	var reachable: Dictionary = {}
	_collect_reachable(start_node_id, reachable)

	# Kahn's algorithm（入度法）只在可達子圖上
	var in_degree: Dictionary = {}
	for id in reachable:
		in_degree[id] = 0
	for e in edges:
		if reachable.has(e["from_node"]) and reachable.has(e["to_node"]):
			in_degree[e["to_node"]] = in_degree.get(e["to_node"], 0) + 1

	var queue: Array[String] = []
	for id: String in in_degree:
		if in_degree[id] == 0:
			queue.append(id)

	var result: Array[String] = []
	while queue.size() > 0:
		var current: String = queue.pop_front() as String
		result.append(current)
		for e in edges:
			if e["from_node"] == current and reachable.has(e["to_node"]):
				var to_id: String = e["to_node"]
				in_degree[to_id] -= 1
				if in_degree[to_id] == 0:
					queue.append(to_id)

	return result

func collect_inputs(node_id: String, port_data: Dictionary) -> Dictionary:
	var inputs: Dictionary = {}
	for e in edges:
		if e["to_node"] == node_id:
			var from_id: String = e["from_node"]
			var from_port_name: String = e["from_port"]
			var to_port_name: String = e["to_port"]
			if port_data.has(from_id):
				var from_outputs: Dictionary = port_data[from_id]
				if from_outputs.has(from_port_name):
					inputs[to_port_name] = from_outputs[from_port_name]
	return inputs

func get_edges_to_node(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e in edges:
		if e["to_node"] == node_id:
			result.append(e)
	return result

func get_edges_from_node(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e in edges:
		if e["from_node"] == node_id:
			result.append(e)
	return result

# --- Private ---

func _collect_reachable(node_id: String, visited: Dictionary) -> void:
	if visited.has(node_id):
		return
	visited[node_id] = true
	for e in edges:
		if e["from_node"] == node_id:
			_collect_reachable(e["to_node"], visited)

func _has_cycle() -> bool:
	var visited: Dictionary = {}
	var in_stack: Dictionary = {}
	for id in nodes:
		if not visited.has(id):
			if _dfs_cycle(id, visited, in_stack):
				return true
	return false

func _dfs_cycle(node_id: String, visited: Dictionary, in_stack: Dictionary) -> bool:
	visited[node_id] = true
	in_stack[node_id] = true
	for e in edges:
		if e["from_node"] == node_id:
			var neighbor: String = e["to_node"]
			if not visited.has(neighbor):
				if _dfs_cycle(neighbor, visited, in_stack):
					return true
			elif in_stack.has(neighbor):
				return true
	in_stack.erase(node_id)
	return false

func _find_output_port(node_id: String, port_name: String):
	var node_data: Dictionary = nodes[node_id]
	var rune: RuneBase = node_data["rune"]
	for port in rune.ports_out:
		if port.port_name == port_name:
			return port
	return null

func _find_input_port(node_id: String, port_name: String):
	var node_data: Dictionary = nodes[node_id]
	var rune: RuneBase = node_data["rune"]
	for port in rune.ports_in:
		if port.port_name == port_name:
			return port
	return null
