# 新增節點 SOP

本文件是給 LLM Coding Agent 的標準作業程序。**在新增任何節點前，先完整讀完對應章節，依樣畫葫蘆，不要自己發明新模式。**

---

## 目錄

1. [新增符文 (Rune)](#1-新增符文)
2. [新增投射物場景 (Projectile Scene)](#2-新增投射物場景)
3. [新增移動模組 (MovementModule)](#3-新增移動模組)
4. [新增後修飾器 (PostModifier)](#4-新增後修飾器)
5. [新增傷害區域變體 (DamageArea)](#5-新增傷害區域變體)
6. [MCP 工具使用指南](#6-mcp-工具使用指南)

---

## 0. Port 輸入輸出規範（必讀）

### 可選輸入一定要有預設值

`ports_in` 裡 `is_required = false` 的 port，**在 `execute()` 裡必須用 `.get(key, 預設值)` 讀取，不可直接索引**。

各型別的標準預設值：

| PortType | key 範例 | 標準預設值 | 說明 |
|----------|---------|-----------|------|
| `ENERGY` | `"energy"` | `1.0` | 能量最小單位 |
| `DIRECTION_VECTOR` | `"direction"` | `[Main.Instance._get_aim_direction()]` | **滑鼠瞄準方向**，注意是 Array |
| `FORM` | `"form"` | `{}` | 空字典，代表無修飾 |
| `TARGET` | `"target"` | `null` | 無目標 |

### Direction 是 Array，永遠用迴圈處理

`direction` 的值型別是 `Array`（可能含多個 `Vector2`，例如霰彈符文會展開成 3 個方向）。**永遠用 `for dir: Vector2 in directions` 迴圈**，不要直接取第一個元素。

```gdscript
# 正確
var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
for dir: Vector2 in directions:
    # 對每個方向生成一發
    ...

# 錯誤 ❌
var dir: Vector2 = inputs.get("direction", Main.Instance._get_aim_direction())
```

### Required vs Optional 的 port 宣告

```gdscript
# required（必須接線才能執行）
RunePort.create("energy", RuneEnums.PortType.ENERGY)           # is_required 預設 true

# optional（未接線時用預設值）
RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false)
RunePort.create("form",      RuneEnums.PortType.FORM,             false)
```

---

## 1. 新增符文

### 1.1 判斷符文類型

| 類型 | `RuneCategory` | 你要做的事 |
|------|---------------|-----------|
| 起始（按鍵觸發）| `STARTER` | 輸出 `energy` |
| 效果（發射法術）| `EFFECT` | 吃 `energy`，輸出 `spell` |
| 修飾（改 form/direction）| `MODIFIER` | 吃並輸出同類型 |
| 修飾（改飛行中的 spell）| `MODIFIER` | 吃並輸出 `spell`，掛 PostModifier |
| 被動（遊戲事件蓄能）| `PASSIVE_TRIGGER` | 繼承 `PassiveRuneBase`，輸出 `energy` |

### 1.2 腳本放哪裡

| 類型 | 加入的檔案 |
|------|-----------|
| STARTER | `scripts/rune_system/runes/starter_runes.gd` |
| EFFECT | `scripts/rune_system/runes/effect_runes.gd` |
| MODIFIER | `scripts/rune_system/runes/modifier_runes.gd` |
| PASSIVE_TRIGGER | `scripts/rune_system/runes/passive_runes.gd` |

每個檔案都是 inner class 集合，在對應檔案末尾新增即可。

### 1.3 程式碼模板

#### STARTER 符文
```gdscript
class MyStarterRune extends RuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.STARTER
        icon_color = Color(1.0, 0.9, 0.3)
        ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

    func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
        return {"energy": 1.0}
```

#### EFFECT 符文（發射投射物）
```gdscript
class MyEffectRune extends RuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.EFFECT
        icon_color = Color(1.0, 0.3, 0.1)
        audio = preload("res://resources/Audio/符文音檔1.wav")
        ports_in = [
            RunePort.create("energy", RuneEnums.PortType.ENERGY),
            RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false),
            RunePort.create("form", RuneEnums.PortType.FORM, false),
        ]
        ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

    func execute(inputs: Dictionary, _context: Node) -> Dictionary:
        var energy: float = inputs.get("energy", 1.0)
        var damage: float = energy * 10.0
        var form: Dictionary = inputs.get("form", {})
        var scene: PackedScene = preload("res://scenes/projectiles/YOUR_SCENE.tscn")
        var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
        var player: Node2D = Player.Instance
        var spell_list: Array = []

        for dir: Vector2 in directions:
            var proj: ProjectileBase = scene.instantiate()
            proj.global_position = player.global_position
            proj.setup(player, dir, 400.0, damage, "YOUR_EFFECT", 3.0)
            proj.apply_form(form)
            Main.Instance.world.add_child(proj)
            spell_list.append({
                "node": proj, "scene": scene, "form": form,
                "direction": dir, "damage": damage,
                "speed": 400.0, "effect": "YOUR_EFFECT", "effect_time": 3.0
            })

        return {"spell": spell_list}
```

> **重要：** `spell_list` 裡的每個 dict 必須包含 `node`, `scene`, `form`, `direction`, `damage`, `speed`, `effect`, `effect_time` 這 8 個 key，MultiShot 複製子彈時依賴這份快照。

#### MODIFIER 符文（修改 form，pre-cast）
```gdscript
class MyFormModifier extends RuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.MODIFIER
        icon_color = Color(1.0, 0.6, 0.0)
        ports_in = [
            RunePort.create("energy", RuneEnums.PortType.ENERGY),
            RunePort.create("form", RuneEnums.PortType.FORM, false),
        ]
        ports_out = [
            RunePort.create("energy", RuneEnums.PortType.ENERGY),
            RunePort.create("form", RuneEnums.PortType.FORM),
        ]

    func execute(inputs: Dictionary, _context: Node) -> Dictionary:
        var energy: float = inputs.get("energy", 1.0)
        var form: Dictionary = inputs.get("form", {})
        form["your_key"] = your_value  # 直接改 form dict
        return {"energy": energy, "form": form}
```

#### MODIFIER 符文（修改方向，pre-fire）
```gdscript
class MyDirectionModifier extends RuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.MODIFIER
        icon_color = Color(1.0, 0.7, 0.2)
        ports_in = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false)]
        ports_out = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR)]

    func execute(inputs: Dictionary, _context: Node) -> Dictionary:
        var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
        var result: Array = []
        for dir: Vector2 in directions:
            result.append(dir)  # 展開或變換方向
        return {"direction": result}
```

#### MODIFIER 符文（掛後修飾器到已生成的 spell，post-fire）
```gdscript
class MySpellModifier extends RuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.MODIFIER
        icon_color = Color(0.9, 0.9, 0.2)
        ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
        ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

    func execute(inputs: Dictionary, _context: Node) -> Dictionary:
        var spell_list: Array = inputs.get("spell", [])
        for spell: Dictionary in spell_list:
            var node_obj: Variant = spell.get("node")
            var scene: PackedScene = spell.get("scene")
            if not is_instance_valid(node_obj) or scene == null:
                continue
            var proj: SpellNodeBase = node_obj as SpellNodeBase
            var modifier: MyPostModifier = MyPostModifier.new()
            proj.add_child(modifier)
            if not spell.has("post_modifiers"):
                spell["post_modifiers"] = []
            (spell["post_modifiers"] as Array).append("my_modifier_id")
        return {"spell": spell_list}
```

> **同時**要去 `modifier_runes.gd` 的 `MultiShot.execute()` 裡的 `match modifier_id` 區塊加上新 id 的分支，否則 MultiShot 複製時不會帶出這個 PostModifier。

#### PASSIVE_TRIGGER 符文
```gdscript
class MyPassiveRune extends PassiveRuneBase:
    func _init() -> void:
        rune_name = "名稱"
        description = "說明\n\"台詞\""
        category = RuneEnums.RuneCategory.PASSIVE_TRIGGER
        icon_color = Color(0.9, 0.7, 0.2)
        max_charges = 3
        ports_out = [
            RunePort.create("energy",  RuneEnums.PortType.ENERGY),
            RunePort.create("energy2", RuneEnums.PortType.ENERGY),
            RunePort.create("energy3", RuneEnums.PortType.ENERGY),
        ]

    # 由遊戲系統（Player、Main 等）在對應事件發生時呼叫
    func accumulate_something(value: float) -> void:
        if stored_charges >= max_charges:
            return
        # 累積邏輯 ...
        stored_charges += 1

    func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
        return _drain_charges()  # 繼承自 PassiveRuneBase，全部榨出
```

### 1.4 注冊到 Registry

編輯 `scripts/rune_system/rune_registry.gd`，在 `_register_all()` 末尾加一行：

```gdscript
_register("my_rune_id", MyRunes.MyRune.new())
```

id 規則：`snake_case`，全小寫，和腳本 class 名稱語義對應。

### 1.5 加入一鍵獲取清單

編輯 `scripts/main.gd`，在 `_give_all_runes()` 的 `all_runes` 陣列末尾加上新 id：

```gdscript
var all_runes: Array[String] = [
    ...,
    "my_rune_id",  # ← 新增這行
]
```

> **注意：** STARTER 類型符文（`starter_q/w/e/r`）不加入此清單，只加 EFFECT / MODIFIER / PASSIVE_TRIGGER。

按遊戲中的 **F1** 即可一鍵獲得清單內所有符文。

---

## 2. 新增投射物場景

### 2.1 何時需要新場景

> **此規則通用於所有場景類型（投射物、DamageArea 等），不專屬於投射物。**

需要新場景：
- 需要不同的外觀（Sprite 材質不同）
- 需要不同的碰撞形狀大小

**不需要**新場景：改傷害、速度、效果 → 直接在 EFFECT 符文的 `setup()` 參數調整。

### 2.2 使用 MCP 建立場景

```
# Step 1：建立新場景，根節點繼承 projectile_base.tscn
mcp__godot__create_scene
  name: "my_projectile"
  root_type: "Area2D"

# Step 2：加入 Sprite2D
mcp__godot__add_node
  scene_path: "res://scenes/projectiles/my_projectile.tscn"
  node_type: "Sprite2D"
  node_name: "Sprite2D"
  parent_path: "."

# Step 3：加入 CollisionShape2D
mcp__godot__add_node
  scene_path: "res://scenes/projectiles/my_projectile.tscn"
  node_type: "CollisionShape2D"
  node_name: "CollisionShape2D"
  parent_path: "."

# Step 4：儲存
mcp__godot__save_scene
  scene_path: "res://scenes/projectiles/my_projectile.tscn"
```

> **注意：** MCP 建立的場景根節點不會自動綁腳本。建立後，**手動在 .tscn 檔案裡**確認 `[ext_resource]` 指向正確的 `.gd`，或用 Godot Editor 手動綁定。

### 2.3 腳本選擇

| 行為 | 使用腳本 |
|------|---------|
| 命中即消失 | `projectile_base.gd` |
| 穿透多個敵人 | `penetrating_projectile.gd`（也可以在 form 設 `penetrating: true`） |

### 2.4 場景結構範本（參考現有場景）

所有投射物場景結構：
```
ProjectileBase (Area2D)
  script = projectile_base.gd
  collision_mask = 5
  ├── Sprite2D
  │     texture = <你的圖>
  │     scale = Vector2(0.109375, 0.109375)  ← 慣例縮放值
  └── CollisionShape2D
        shape = CircleShape2D(radius=8.0)     ← 慣例碰撞半徑
```

> 根節點 `collision_mask = 5` = layer 1（玩家）+ layer 4（敵人）+ ？，保持和現有一致。

---

## 3. 新增移動模組

### 3.1 腳本放哪裡

`scripts/projectiles/movements/my_movement.gd`

### 3.2 程式碼模板

```gdscript
extends MovementModule
class_name MyMovement

# 如果需要初始化狀態，覆寫 init
func init(projectile: ProjectileBase) -> void:
    pass  # 讀取 projectile 的屬性，初始化自身狀態

func move(projectile: ProjectileBase, delta: float) -> void:
    # 每幀修改 projectile.position 或 projectile.direction
    projectile.position += projectile.direction * projectile.speed * delta
```

### 3.3 讓 form 可以觸發這個移動模組

在 `scripts/projectiles/projectile_base.gd` 的 `apply_form()` 的 `match movement_type` 區塊新增：

```gdscript
"my_movement_key":
    set_movement_module(MyMovement.new())
```

接著在對應的 MODIFIER 符文的 `execute()` 裡設定：

```gdscript
form["movement"] = "my_movement_key"
```

---

## 4. 新增後修飾器

### 4.1 腳本放哪裡

`scripts/projectiles/post_modifiers/my_post_modifier.gd`

### 4.2 三種觸發時機，選一種

| 觸發時機 | 實作方式 | 範例 |
|---------|---------|------|
| 命中時 | `_ready()` 連接 `hit_body` signal | QuadShot、PoisonPool |
| 每幀（飛行中）| `_process(delta)` | Trail |
| 消失時 | `_ready()` 連接 `tree_exiting` signal | PoisonPool |

### 4.3 程式碼模板

```gdscript
class_name MyPostModifier extends PostModifier

func clone() -> PostModifier:
    return MyPostModifier.new()  # 必須覆寫，供 MultiShot 複製用

func _ready() -> void:
    var parent: SpellNodeBase = get_parent() as SpellNodeBase
    parent.hit_body.connect(_on_hit)
    # 若也要在消失時觸發：parent.tree_exiting.connect(_on_expire)

func _on_hit(body: Node2D) -> void:
    var proj: SpellNodeBase = get_parent() as SpellNodeBase
    if body == proj.owner_node:
        return
    # 在此觸發效果，例如生成 DamageArea 或新投射物
```

### 4.4 產生 DamageArea 的標準寫法

```gdscript
const DAMAGE_AREA_SCENE: PackedScene = preload("res://scenes/damage_areas/damage_area.tscn")

func _spawn_area(pos: Vector2, area_owner: Node2D) -> void:
    var area: DamageAreaBase = DAMAGE_AREA_SCENE.instantiate() as DamageAreaBase
    area.global_position = pos
    area.setup(
        area_owner,   # owner_node
        5.0,          # damage per tick
        "burn",       # effect ("burn" / "slow" / "poison" / "None")
        3.0,          # effect_time
        3.0,          # duration（area 存活秒數）
        0.5,          # tick_interval
        "fire"        # visual ("fire" / "poison")
    )
    Main.Instance.world.add_child(area)
```

### 4.5 在 MultiShot 裡登記

編輯 `scripts/rune_system/runes/modifier_runes.gd`，`MultiShot.execute()` 裡的 `match modifier_id` 加一行：

```gdscript
"my_modifier_id": copy.add_child(MyPostModifier.new())
```

---

## 5. 新增傷害區域變體

### 5.1 何時需要新場景

同 Section 2.1 的通用規則：

- **需要新場景**：有不同外觀（Sprite 材質不同）→ 用 MCP 建新 .tscn，流程同 Section 2.2，存放於 `scenes/damage_areas/`，使用腳本 `damage_area_base.gd`，`collision_mask = 4`
- **不需要新場景**：只改傷害、tick 間隔、duration、效果等參數 → 直接在符文的 `setup()` 參數調整

### 5.2 新增純粒子 visual 效果（不需要新場景時）

在 `damage_area_base.gd` 的 `_ready()` 的 `match visual` 裡加分支，並新增對應的 `_create_xxx_particles()` 方法（參考 `_create_fire_particles()` 的寫法）。

`visual` 參數目前支援 `"fire"` 和 `"poison"`。

### 5.3 DamageArea 場景結構範本

```
FireDamageArea (Area2D)
  script = damage_area_base.gd
  collision_layer = 0
  collision_mask = 4
  monitoring = true
  monitorable = false
  ├── Sprite2D
  │     texture = <你的圖>
  │     scale = <依圖片解析度調整，應比粒子範圍小>
  └── CollisionShape2D
        shape = CircleShape2D(radius=32.0)  ← 慣例碰撞半徑
```

---

## 6. MCP 工具使用指南

### 6.1 可用工具速查

| 工具 | 用途 |
|------|------|
| `mcp__godot__get_project_info` | 確認專案狀態，取得場景清單 |
| `mcp__godot__create_scene` | 建立新 .tscn 場景 |
| `mcp__godot__add_node` | 向場景加入節點 |
| `mcp__godot__save_scene` | 儲存場景到磁碟 |
| `mcp__godot__get_uid` | 取得資源的 UID（在 .tscn 手動引用時需要） |
| `mcp__godot__launch_editor` | 啟動 Godot Editor |
| `mcp__godot__run_project` | 執行遊戲 |
| `mcp__godot__stop_project` | 停止執行中的遊戲 |
| `mcp__godot__get_debug_output` | 讀取執行時的 debug 輸出 |

### 6.2 建立新場景的標準流程

```
1. mcp__godot__get_project_info          → 確認專案路徑正確
2. mcp__godot__create_scene              → 建立場景
3. mcp__godot__add_node (重複N次)        → 加入子節點
4. mcp__godot__save_scene                → 儲存
5. 用 Read 工具讀取 .tscn 確認結構正確
6. 手動在 .tscn 設定 script 綁定（如 MCP 未支援）
```

### 6.3 驗證場景是否正確

建立場景後，用 `Read` 工具讀取 `.tscn` 檔案，核對：

- `[ext_resource]` 裡有正確的 `.gd` 腳本路徑
- 根節點有 `script = ExtResource("...")` 屬性
- `collision_mask` 和現有同類場景一致（投射物 = 5）
- 若有疑問，對照現有場景：`scenes/projectiles/fireball.tscn`

### 6.4 MCP 工具已知限制

- `add_node` 不一定能設定 Shape 的細部屬性（如 CircleShape2D radius），需要建立後在 .tscn 手動編輯或在 Editor 調整
- 腳本綁定可能需要手動處理
- 複雜節點屬性（SpriteFrames、AudioStream）建議直接在 Editor 操作

---

## 附錄：碰撞層定義

| Layer | 意義 |
|-------|------|
| 1 | 玩家 |
| 4 | 敵人 |
| 5 | 障礙物 |

投射物 `collision_mask = 5` 代表偵測 layer 1（玩家）和 layer 4（敵人）。

傷害區域 `collision_mask = 4` 代表只偵測 layer 4（敵人）。
