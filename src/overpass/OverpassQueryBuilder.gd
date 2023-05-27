@tool
class_name OverpassQueryBuilder extends Resource

@export var default_settings: OverpassQuerySettings = OverpassQuerySettings.new()
@export var override_settings: OverpassQuerySettings

class QLScript:
	var compact: bool = false
	var indent_string: String = "    "
	var indent_level: int = 0
	var statement_prefixes: PackedStringArray = PackedStringArray()
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
		var prefix = "".join(statement_prefixes)
		append(prefix + statement)
	func push_statement_prefix(prefix: String):
		statement_prefixes.append(prefix)
	func pop_statement_prefix():
		statement_prefixes.remove_at(statement_prefixes.size() - 1)
	func error(message: String):
		var prior_indent_level = indent_level
		indent_level = 0
		append("SCRIPT BUILD ERROR: " + message)
		indent_level = prior_indent_level

func get_overpass_ql_script(query: OverpassQuery, compact: bool = false) -> String:
	var script: QLScript = QLScript.new()
	script.compact = compact
	script.append_statement(_get_settings_statement(script, query))
	query._build_script(script)
	return script.text

func _get_bbox(bounds: GeoBoundary):
	return "%f,%f,%f,%f" % [bounds.from_lat, bounds.from_lon, bounds.to_lat, bounds.to_lon]

func _get_settings_statement(script: QLScript, query: OverpassQuery) -> String:
	var settings := default_settings if default_settings != null else OverpassQuerySettings.new()
	settings = settings.overriden_with(query.settings)
	settings = settings.overriden_with(override_settings)
	
	var settings_statement_parts := PackedStringArray()
	var use_new_lines := true

	if settings.server_max_query_time > 0:
		settings_statement_parts.append("[timeout:%d]" % settings.server_max_query_time)

	if settings.server_max_memory_size > 0:
		settings_statement_parts.append("[maxsize:%d]" % settings.server_max_memory_size)

	match settings.output_format:
		OverpassQuerySettings.OutputFormat.XML:
			settings_statement_parts.append("[out:xml]")
		OverpassQuerySettings.OutputFormat.JSON:
			settings_statement_parts.append("[out:json]")
		OverpassQuerySettings.OutputFormat.CSV:
			var csv_format_parameters = ""
			if settings.output_csv_fields != null and settings.output_csv_fields.size() > 0:
				csv_format_parameters += script.list_separator().join(settings.output_csv_fields)
				csv_format_parameters += ";" + ("false" if settings.output_csv_header == OverpassQuerySettings.OutputCSVHeader.EXCLUDED else "true")
				if settings.output_csv_separator != null and settings.output_csv_separator.length() > 0:
					csv_format_parameters += ";\"" + settings.output_csv_separator + "\""
			if csv_format_parameters.length() > 0:
				if use_new_lines:
					settings_statement_parts.append("[out:csv(\n\t%s\n)]" % csv_format_parameters)
				else:
					settings_statement_parts.append("[out:csv(%s)]" % csv_format_parameters)
			else:
				settings_statement_parts.append("[out:csv]")
		OverpassQuerySettings.OutputFormat.CUSTOM:
			settings_statement_parts.append("[out:custom]")
		OverpassQuerySettings.OutputFormat.POPUP:
			settings_statement_parts.append("[out:popup]")
				
	if settings.global_bounds != null:
		settings_statement_parts.append("[bbox:%s]" % _get_bbox(settings.global_bounds))
		
	match settings.datetime_filter:
		OverpassQuerySettings.DateFilter.ATTIC_STATE:
			var datetime_to = settings.datetime_to if settings.datetime_to != null and settings.datetime_to.length() > 0 \
				else Time.get_datetime_string_from_system()
			settings_statement_parts.append("[date:\"%s\"]" % datetime_to)
		OverpassQuerySettings.DateFilter.DIFFERENCES:
			var datetime_from = settings.datetime_to if settings.datetime_to != null and settings.datetime_to.length() > 0 \
				else OverpassQuerySettings.default_datetime_from
			if settings.datetime_to != null and settings.datetime_to.length() > 0:
				settings_statement_parts.append("[diff:\"%s\"]" % [datetime_from, settings.datetime_to])
			else:
				settings_statement_parts.append("[diff:\"%s\"]" % datetime_from)
		OverpassQuerySettings.DateFilter.AUGMENTED_DIFFERENCES:
			var datetime_from = settings.datetime_to if settings.datetime_to != null and settings.datetime_to.length() > 0 \
				else OverpassQuerySettings.default_datetime_from
			if settings.datetime_to != null and settings.datetime_to.length() > 0:
				settings_statement_parts.append("[adiff:\"%s\"]" % [datetime_from, settings.datetime_to])
			else:
				settings_statement_parts.append("[adiff:\"%s\"]" % datetime_from)
		
	var settings_statement = ("\n" if use_new_lines else "").join(settings_statement_parts)
	
	return settings_statement if settings_statement_parts.size() > 0 else null
