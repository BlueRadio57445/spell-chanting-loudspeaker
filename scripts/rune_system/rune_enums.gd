class_name RuneEnums

enum PortType { ENERGY, HP, DIRECTION_VECTOR, TARGET, SPELL, SPELL_LIST, FORM }
enum RuneCategory { STARTER, EFFECT, CONVERSION, MODIFIER, ENCHANTMENT, PASSIVE_TRIGGER }

# Port 顏色對照（UI 用）
const PORT_COLORS: Dictionary = {
	PortType.ENERGY: Color.YELLOW,
	PortType.HP: Color.RED,
	PortType.DIRECTION_VECTOR: Color.GREEN,
	PortType.TARGET: Color.PURPLE,
	PortType.SPELL: Color.DODGER_BLUE,
	PortType.SPELL_LIST: Color.CYAN,
	PortType.FORM: Color.ORANGE,
}

static func can_connect(from_type: PortType, to_type: PortType) -> bool:
	return from_type == to_type

static func port_type_name(type: PortType) -> String:
	match type:
		PortType.ENERGY: return "Energy"
		PortType.HP: return "HP"
		PortType.DIRECTION_VECTOR: return "Direction"
		PortType.TARGET: return "Target"
		PortType.SPELL: return "Spell"
		PortType.SPELL_LIST: return "SpellList"
		PortType.FORM: return "Form"
	return "Unknown"
