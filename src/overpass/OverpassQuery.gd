@tool
class_name OverpassQuery extends Resource

@export var global_bounds: GeoBoundary

@export var statements: Array[OverpassStatement]

@export_group("Output format", "output_")
enum OutputFormat {
	DEFAULT, XML, JSON, CSV, CUSTOM, POPUP
}
@export var output_format: OutputFormat = OutputFormat.DEFAULT
@export var output_csv_fields: PackedStringArray
@export var output_csv_header_included: bool = true
@export var output_csv_separator: String

@export_group("Server limits", "server_max_")
const default_server_max_query_time = 180
@export var server_max_query_time: int = 0
const default_server_max_memory_size = 536870912
@export var server_max_memory_size: int = 0

func _init():
	pass

func _build_script(script: OverpassQueryBuilder.QLScript):
	for statement in statements:
		if statement != null:
			statement._build_script(script)


