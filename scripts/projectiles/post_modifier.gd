# 後修飾基類，掛在投射物上作為子節點
# 子類在 _ready() 裡連接投射物的 signal 或覆寫行為
class_name PostModifier extends Node

# 子類覆寫此方法，回傳一個帶有相同設定的新實例（供 MultiShot 複製子彈時使用）
func clone() -> PostModifier:
	return duplicate() as PostModifier
