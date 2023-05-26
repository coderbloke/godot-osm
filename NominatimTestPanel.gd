@tool
class_name NominatimTestPanel extends VBoxContainer

@export var base_url: String = NominatimClient.DEFAULT_URL:
	set(new_value):
		base_url = new_value
		if nominatim_client != null:
			nominatim_client.base_url = base_url
@export var nominatim_query: NominatimQueryParameters

@export var auto_query = true:
	set(new_value):
		auto_query = new_value
		if auto_query_checkbutton != null:
			auto_query_checkbutton.button_pressed = auto_query
@export var print_to_console = true
@export var trigger_query = false

@onready var nominatim_client: NominatimClient = $NominatimClient

@onready var query_resource_value_label: RichTextLabel = $QueryContainer/ResourceValueLabel
@onready var query_url_value_label: RichTextLabel = $QueryContainer/URLValueLabel
@onready var auto_query_checkbutton: CheckButton = $QueryContainer/AutoQueryCheckButton
@onready var query_button: Button = $QueryContainer/QueryButton
@onready var result_items_container: VBoxContainer = $ResultContainer/ResultItemsContainer
@onready var result_label: RichTextLabel = $ResultContainer/ResultItemsContainer/ResultLabel
@onready var result_separator: HSeparator = $ResultContainer/ResultItemsContainer/ResultSeparator

func _ready():
	nominatim_client.base_url = base_url
	auto_query_checkbutton.button_pressed = auto_query
	_remove_all_temp_result_children()

func _on_nominatim_query_changed():
	print("_on_nominatim_query_changed()")
	
func get_resource_info(resource: Resource) -> String:
	var info: String
	if resource != null:
		info = resource.resource_name
		if info == null:
			info = ""
		if info.length() > 0:
			info += " "
		if resource.resource_path != null and resource.resource_path.length() > 0:
			info += "(" + resource.resource_path + ")"
		else:
			info += "(unsaved)"
	else:
		info = "(null)"
	return info
	
var _query_url: String
var _last_query_url: String

func _update_query_url():
	if nominatim_query != null:
		_query_url = nominatim_client.get_query_url(nominatim_query)
	else:
		_query_url = ""

func do_query():
	if nominatim_query != null:
		_last_query_url = _query_url
		nominatim_client.cancel_request()
		if print_to_console:
			print_rich("[color=Lightskyblue]" + nominatim_client.get_query_url(nominatim_query) + "[/color]")
		nominatim_client.query(nominatim_query)

func _process(delta):
	query_resource_value_label.text = get_resource_info(nominatim_query)
	_update_query_url()
	query_url_value_label.text = _query_url
	if (auto_query and _query_url != _last_query_url) or trigger_query:
		pass
	trigger_query = false

func _on_query_button_pressed():
	do_query()
	
var _temp_result_item_group_name = "temp_result_item"

func _remove_all_temp_result_children():
	for child in result_items_container.get_children(true):
		if child.is_in_group(_temp_result_item_group_name):
			child.owner = null
			result_items_container.remove_child(child)

func _create_temp_result_label() -> RichTextLabel:
	var temp: RichTextLabel = result_label.duplicate()
	result_items_container.add_child(temp)
	#temp.owner = result_label.owner
	temp.add_to_group(_temp_result_item_group_name)
	temp.visible = true
	return temp

func _create_temp_result_separator() -> HSeparator:
	var temp: HSeparator = result_separator.duplicate()
	result_items_container.add_child(temp)
	#temp.owner = result_label.owner
	temp.add_to_group(_temp_result_item_group_name)
	temp.visible = true
	return temp

func _on_query_completed(result: Array):
	_remove_all_temp_result_children()
	result_label.visible = false
	for i in result.size():
		var place: Dictionary = result[i]
		var place_info = place["display_name"] + " (" + place["type"] + " #"+ str(place["osm_id"]) + " @ " + place["lat"] + "," + place["lon"] + ")"
		var temp_result_label = _create_temp_result_label()
		temp_result_label.text = "[color=LightSlateGray]" + str(place) + "[/color]\n"
		temp_result_label.text += "[lb]" + str(i) + "[rb] " + place_info
		_create_temp_result_separator()
		if print_to_console:
			print_rich("[color=Lightslategray]" + str(place) + "[/color]")
			print("[" + str(i) + "] " + place_info)

func _on_auto_query_check_button_toggled(button_pressed):
	auto_query = button_pressed
