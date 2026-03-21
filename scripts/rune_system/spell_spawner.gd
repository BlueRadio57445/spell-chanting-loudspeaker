class_name SpellSpawner extends Node2D

func spawn_spell(spell_data: Dictionary, caster: Node2D) -> void:
	var spell_type: String = spell_data.get("type", "")
	match spell_type:
		"fireball":
			_spawn_fireball(spell_data, caster)
		"heal":
			_apply_heal(spell_data, caster)
		"debuff":
			_apply_debuff(spell_data, caster)
		_:
			print("[SpellSpawner] 未知法術類型: %s" % spell_type)

func _spawn_fireball(data: Dictionary, caster: Node2D) -> void:
	var damage: float = data.get("damage", 0.0)
	var direction: Vector2 = data.get("direction", Vector2.RIGHT)
	print("[SpellSpawner] 發射火球 — 傷害: %s, 方向: %s, 施法者: %s" % [damage, direction, caster.name])
	# TODO: 實際生成火球投射物

func _apply_heal(data: Dictionary, caster: Node2D) -> void:
	var amount: float = data.get("amount", 0.0)
	print("[SpellSpawner] 治癒 — 回血: %s, 目標: %s" % [amount, caster.name])
	# TODO: 實際回血

func _apply_debuff(data: Dictionary, _caster: Node2D) -> void:
	var power: float = data.get("power", 0.0)
	var target = data.get("target", null)
	print("[SpellSpawner] 詛咒 — 減益: %s, 目標: %s" % [power, target])
	# TODO: 實際施加 debuff
