class_name RunePort extends RefCounted

var port_name: String
var port_type: RuneEnums.PortType
var is_required: bool
## 此 output port 最多可連幾條線。-1 = 無限，1 = 一對一（預設）。僅對 output port 有意義。
var max_out_connections: int = 1

static func create(p_name: String, p_type: RuneEnums.PortType, p_required: bool = true, p_max_out: int = 1) -> RunePort:
	var port := RunePort.new()
	port.port_name = p_name
	port.port_type = p_type
	port.is_required = p_required
	port.max_out_connections = p_max_out
	return port
