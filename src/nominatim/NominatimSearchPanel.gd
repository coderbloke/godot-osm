@tool
class_name NominatimSearchPanel extends VBoxContainer

@export var search_text: String:
	set(new_value):
		search_text = new_value
		if search_panel != null:
			search_panel.search_text = new_value
	get:
		return search_text

@export_group("Debug")
@export var trigger_search: bool = false:
	set(new_value): if new_value == true: _on_search_requested()
@export var trigger_more: bool = false:
	set(new_value): if new_value == true: _on_more_requested()
@export var trigger_clear: bool = false:
	set(new_value): if new_value == true: search_panel.clear_results()
@export var click_index: int = 0:
	set(new_value): click_index = clamp(new_value, 0, results.size())
@export var trigger_click: bool = false:
	set(new_value): _on_result_pressed(results[clamp(click_index, 0, results.size())])
	
@onready var search_panel := $SearchPanel
@onready var nominatim := $NominatimClient

var query_parameters := NominatimQueryParameters.new()
var results = []

signal result_pressed(result)

func _ready():
	search_panel.search_text = search_text
	
func query():
	results = []
	search_panel.clear_results()
	query_parameters.query_type = NominatimQueryParameters.QueryType.FREEFORM_SEARCH
	query_parameters.freeform_query = search_panel.search_text
	query_parameters.exclude_place_ids.clear()
	nominatim.query(query_parameters)
	
func query_more():
	query_parameters.exclude_place_ids.clear()
	for r in results:
		query_parameters.exclude_place_ids.append(r["place_id"])
	nominatim.query(query_parameters)

func _on_search_requested():
	query()

func _on_more_requested():
	query_more()

func _on_query_completed(result: Array):
	for r in result:
		var note := NominatimClient.get_result_type(r) \
			+ " (" + NominatimClient.get_result_category(r) + ")"
		search_panel.add_result(NominatimClient.get_result_display_name(r), note, r)
	results.append_array(result)

func _on_result_pressed(result):
	result_pressed.emit(result)
