@tool
class_name OverpassQueryBuilder extends Resource

@export var default_global_bounds: GeoBoundary
@export var override_global_bounds: GeoBoundary

enum OverrideOutputCSVHeader {
	NO_OVERRIDE, INCLUDE, EXCLUDE
}

@export_group("Output format override", "override_output_")
@export var override_output_format: OverpassQuery.OutputFormat = OverpassQuery.OutputFormat.DEFAULT
@export var override_output_csv_field: PackedStringArray
@export var override_output_csv_header: OverrideOutputCSVHeader = OverrideOutputCSVHeader.NO_OVERRIDE
@export var override_output_csv_separator: String

@export_group("Default server limits", "default_server_max_")
@export var default_server_max_query_time: int = 0
@export var default_server_max_memory_size: int = 0

class QLScript:
	var compact: bool = false
	var indent_string: String = "    "
	var indent_level: int = 0
	var text: String = ""
	func _init(compact: bool = false):
		self.compact = compact
	func indent():
		indent_level += 1
	func unindent():
		indent_level -= 1
	func list_separator() -> String:
		return ", " if not compact else ","
	func append(code: String):
		var prefix := ""
		if not compact:
			for i in indent_level:
				prefix += indent_string
		var suffix := ""
		if not compact:
			suffix += "\n"
		if not compact:
			code = code.replace("\t", indent_string)
			code = code.replace("\n", suffix)
		else:
			code = code.replace("\t", "")
			code = code.replace("\n", "")
		text += (prefix + code + suffix)
	func append_statement(statement: String):
		if statement == null:
			return
		if not statement.ends_with(";"):
			statement += ";"
		append(statement)

func get_overpass_ql_script(query: OverpassQuery, compact: bool = false) -> String:
	var script: QLScript = QLScript.new()
	script.append_statement(_get_settings_statement(script, query))
	query._build_script(script)
	return script.text

func _get_bbox(bounds: GeoBoundary):
	return "%f,%f,%f,%f" % [bounds.from_lat, bounds.from_lon, bounds.to_lat, bounds.to_lon]

func _get_settings_statement(script: QLScript, query: OverpassQuery) -> String:
	var settings := ""
	var use_new_lines := true

	var server_max_query_time = default_server_max_query_time
	if query.server_max_query_time > 0:
		server_max_query_time = query.server_max_query_time
	if server_max_query_time > 0:
		if use_new_lines and settings.length() > 0: settings += "\n"
		settings += "[timeout:%d]" % server_max_query_time

	var server_max_memory_size = default_server_max_memory_size
	if query.server_max_memory_size > 0:
		server_max_query_time = query.server_max_memory_size
	if server_max_memory_size > 0:
		if use_new_lines and settings.length() > 0: settings += "\n"
		settings += "[maxsize:%d]" % server_max_memory_size

	var output_format = query.output_format
	if override_output_format != OverpassQuery.OutputFormat.DEFAULT:
		output_format = override_output_format
	var output_csv_fields = query.output_csv_fields
	if override_output_csv_field != null and override_output_csv_field.size() > 0:
		output_csv_fields = override_output_csv_field
	var output_csv_header_included = query.output_csv_header_included
	match override_output_csv_header:
		OverrideOutputCSVHeader.INCLUDE:
			output_csv_header_included = true
		OverrideOutputCSVHeader.EXCLUDE:
			output_csv_header_included = false
	var output_csv_separator = query.output_csv_separator
	if override_output_csv_separator != null and override_output_csv_separator.length() > 0:
		output_csv_separator = override_output_csv_separator
	if output_format != OverpassQuery.OutputFormat.DEFAULT:
		if use_new_lines and settings.length() > 0: settings += "\n"
		match output_format:
			OverpassQuery.OutputFormat.XML:
				settings += "[out:xml]"
			OverpassQuery.OutputFormat.JSON:
				settings += "[out:json]"
			OverpassQuery.OutputFormat.CSV:
				var csv_format_parameters = ""
				if output_csv_fields != null and output_csv_fields.size() > 0:
					csv_format_parameters += script.list_separator().join(output_csv_fields)
					csv_format_parameters += ";" + ("true" if output_csv_header_included else "false")
					if output_csv_separator != null and output_csv_separator.length() > 0:
						csv_format_parameters += ";\"" + output_csv_separator + "\""
				if csv_format_parameters.length() > 0:
					if use_new_lines:
						settings += "[out:csv(\n\t%s\n)]" % csv_format_parameters
					else:
						settings += "[out:csv(%s)]" % csv_format_parameters
				else:
					settings += "[out:csv]"
			OverpassQuery.OutputFormat.CUSTOM:
				settings += "[out:custom]"
			OverpassQuery.OutputFormat.POPUP:
				settings += "[out:popup]"
				
	var global_bounds = default_global_bounds
	if query.global_bounds != null:
		global_bounds = query.global_bounds
	if override_global_bounds != null:
		global_bounds = override_global_bounds
	if global_bounds != null:
		if use_new_lines and settings.length() > 0: settings += "\n"
		settings += "[bbox:%s]" % _get_bbox(global_bounds)
	
	return settings if settings.length() > 0 else null
