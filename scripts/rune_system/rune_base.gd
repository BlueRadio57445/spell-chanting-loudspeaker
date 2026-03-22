class_name RuneBase extends Resource

@export var rune_name: String = ""
@export var description: String = ""
@export var type_description: String = ""
@export var category: RuneEnums.RuneCategory = RuneEnums.RuneCategory.EFFECT
@export var icon_color: Color = Color.WHITE
@export var audio: AudioStream = null

var ports_in: Array[RunePort] = []
var ports_out: Array[RunePort] = []

func execute(inputs: Dictionary, context: Node) -> Dictionary:
	return {}

func get_display_name() -> String:
	return rune_name
