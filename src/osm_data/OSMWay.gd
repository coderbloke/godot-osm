@tool
class_name OSMWay extends OSMElement

@export var node_ids: PackedInt64Array

# This is not part of the OSM data, but used when the result of multiple queries are updated in
# A query result can contain only a part of they way
# It can happen that a previous result contained not the whole road,
# in which case it is hard to fin out where to put the nodes from the next result.
# (- Find if any of the nodes from the new result is already in the node list?
#    What if the previous result had gaps in the nodes? What if the new one?
#  - What if none of the nodes of the new result is in the previous node list?
#    Then where to put the new ones? Before? After? They can be all be in a gap of the previous result)
# TODO: Handle somehow later
@export var _section_start_indices: PackedInt64Array
@export var _section_end_indices: PackedInt64Array

func _init(id: int = -1, node_ids: PackedInt64Array = PackedInt64Array()):
	super._init(id)
