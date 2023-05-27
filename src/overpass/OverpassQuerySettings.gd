@tool
class_name OverpassQuerySettings extends Resource

@export var global_bounds: GeoBoundary

@export_group("Filter by datetime", "datetime_")
enum DateFilter {
	DEFAULT, CURRENT_STATE, ATTIC_STATE, DIFFERENCES, AUGMENTED_DIFFERENCES
}
@export var datetime_filter: DateFilter = DateFilter.DEFAULT
const default_datetime_from := "2004-01-01T00:00:00"
@export var datetime_from: String
@export var datetime_to: String

@export_group("Output format", "output_")
enum OutputFormat {
	DEFAULT, XML, JSON, CSV, CUSTOM, POPUP
}
@export var output_format: OutputFormat = OutputFormat.DEFAULT
@export var output_csv_fields: PackedStringArray
enum OutputCSVHeader {
	DEFAULT, INCLUDED, EXCLUDED
}
@export var output_csv_header: OutputCSVHeader = OutputCSVHeader.DEFAULT
@export var output_csv_separator: String

@export_group("Server limits", "server_max_")
const default_server_max_query_time = 180
@export var server_max_query_time: int = 0
const default_server_max_memory_size = 536870912
@export var server_max_memory_size: int = 0

func overriden_with(override: OverpassQuerySettings) -> OverpassQuerySettings:
	var settings: OverpassQuerySettings = self.duplicate(true) as OverpassQuerySettings
	if override == null:
		return settings
	if override.global_bounds != null:
		settings.global_bounds =  override.global_bounds
	if override.datetime_filter != DateFilter.DEFAULT:
		settings.datetime_filter = override.datetime_filter
		if override.datetime_from != null and override.datetime_from.length() > 0:
			settings.datetime_from = settings.datetime_from
		if override.datetime_to != null and override.datetime_to.length() > 0:
			settings.datetime_to = settings.datetime_to
	if override.output_format != OutputFormat.DEFAULT:
		settings.output_format = override.output_format
		if override.output_csv_fields != null and override.output_csv_fields.size() > 0:
			settings.output_csv_fields = override.output_csv_fields
		if override.output_csv_separator != null and override.output_csv_separator.length() > 0:
			settings.output_csv_separator = settings.output_csv_separator
	if override.server_max_query_time > 0:
		settings.server_max_query_time = override.server_max_query_time
	if override.server_max_memory_size > 0:
		settings.server_max_memory_size = override.server_max_memory_size
	return settings

