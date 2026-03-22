# 所有 Spell 節點的基類（投射物、傷害區域等）
# 定義共用介面，讓後修飾符文可以不區分節點類型運作
extends Area2D
class_name SpellNodeBase

signal hit_body(body: Node2D)

var owner_node: Node2D = null

# 子類覆寫：根據 form 字典套用形體設定
func apply_form(_form: Dictionary) -> void:
	pass
