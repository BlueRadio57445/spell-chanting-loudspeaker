extends Node

var _templates: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	_register("starter_q", StarterRunes.StarterQ.new())
	_register("starter_w", StarterRunes.StarterW.new())
	_register("starter_e", StarterRunes.StarterE.new())
	_register("starter_r", StarterRunes.StarterR.new())
	_register("fireball", EffectRunes.Fireball.new())
	_register("energy_ball", EffectRunes.EnergyBall.new())
	_register("ice_ball", EffectRunes.IceBall.new())
	_register("poison_ball", EffectRunes.PoisonBall.new())
	_register("heal", EffectRunes.Heal.new())
	_register("debuff", EffectRunes.Debuff.new())

func _register(id: String, rune: RuneBase) -> void:
	_templates[id] = rune

func create_instance(id: String) -> RuneBase:
	assert(_templates.has(id), "Unknown rune id: " + id)
	return _templates[id].duplicate()

func get_all_ids() -> Array:
	return _templates.keys()

func get_template(id: String) -> RuneBase:
	return _templates.get(id)
