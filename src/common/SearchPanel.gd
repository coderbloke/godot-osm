@tool
class_name SearchPanel extends VBoxContainer

@export var search_text: String:
	set(new_value):
		search_text = new_value
		if search_text_line_edit != null and search_text_line_edit.text != search_text:
			search_text_line_edit.text = search_text
@export var more_enabled: bool = true:
	set(new_value):
		more_enabled = new_value
		if more_button != null:
			if more_enabled and not cleared:
				more_button.visible = true
			else:
				more_button.visible = false
@export var items_clickable: bool = false:
	set(new_value):
		items_clickable = new_value
		_update_button_properties()
@export var flat_items: bool = false:
	set(new_value):
		flat_items = new_value
		_update_button_properties()

@export_group("Debug")
@export var trigger_search: bool = false:
	set(new_value): if new_value == true: search_requested.emit()
@export var trigger_more: bool = false:
	set(new_value): if new_value == true: more_requested.emit()
			
var cleared := true
var highlighted_item

@onready var search_text_line_edit := $InputContainer/SearchTextLineEdit
@onready var result_item_template := $ResultContainer/ResultList/ResultItemTemplate
@onready var more_button := $ResultContainer/ResultList/MoreButton

signal search_requested
signal more_requested
signal result_pressed(result)

func _ready():
	search_text_line_edit.text = search_text
	_update_button_properties()
	
func _update_button_properties():
	var items_disabled := not items_clickable
	if result_item_template != null:
		result_item_template.disabled = items_disabled
		result_item_template.flat = flat_items
	for r in _get_temporary_result_items():
		r.disabled = items_disabled
		r.flat = flat_items

func _get_temporary_result_items() -> Array[Node]:
	var temporary_result_items: Array[Node] = []
	if result_item_template != null:
		for c in result_item_template.get_parent().get_children():
			if c.get_meta("temporary_result_item", false):
				temporary_result_items.append(c)
	return temporary_result_items
	
func clear_results():
	var children_to_remove := _get_temporary_result_items()
	for c in children_to_remove:
		result_item_template.get_parent().remove_child(c)
	cleared = true
	more_button.visible = false
		
func add_result(text: String, note: String = "", meta: Variant = null):
	var r: RichTextLabel = result_item_template.duplicate()
	r.set_meta("temporary_result_item", true)
	r.clear()
	if note != null and note.length() > 0:
		r.push_font_size(result_item_template.get_theme_font_size("note_font_size"))
		r.push_color(result_item_template.get_theme_color("note_font_color"))
		r.add_text(note + "\n")
		r.pop()
		r.pop()
	r.add_text(text)
	result_item_template.get_parent().add_child(r)
	#r.owner = result_item_template.owner
	r.meta = meta
	r.visible = true
	cleared = false
	more_button.get_parent().move_child(more_button, -1)
	if more_enabled: more_button.visible = true
	
func _on_search_button_pressed():
	search_requested.emit()

func _on_search_text_line_edit_text_changed(new_text):
	search_text = search_text_line_edit.text

func _on_search_text_line_edit_text_submitted(new_text):
	search_requested.emit()

func _on_more_button_pressed():
	more_requested.emit()

func _on_result_item_meta_pressed(meta):
	result_pressed.emit(meta)
