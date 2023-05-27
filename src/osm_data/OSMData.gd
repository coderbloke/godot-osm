@tool
class_name OSMData extends Resource

@export var nodes: Array[OSMNode]
@export var ways: Array[OSMWay]
@export var relations: Array[OSMRelation]

var nodes_by_id = { }
var ways_by_id = { }
var relations_by_id = { }

func _init_lists():
	if nodes == null:
		nodes = [ ]
	if ways == null:
		ways = [ ]
	if relations == null:
		relations = [ ]
	if nodes_by_id == null:
		nodes_by_id = { }
	if ways_by_id == null:
		ways_by_id = { }
	if relations_by_id == null:
		relations_by_id = { }
	
func rebuild_hashmaps():
	_init_lists()
	nodes_by_id.clear()
	for e in nodes:
		nodes_by_id[e.id] = e
	ways_by_id.clear()
	for e in ways:
		ways_by_id[e.id] = e
	
func add_node(e: OSMNode) -> OSMNode:
	nodes.append(e)
	nodes_by_id[e.id] = e
	return e
	
func get_node_by_id(id: int, create_if_not_exists: bool = false) -> OSMNode:
	var e: OSMNode = nodes_by_id.get(id)
	if e == null and create_if_not_exists:
		e = add_node(OSMNode.new(id))
	return e

func add_way(e: OSMWay) -> OSMWay:
	ways.append(e)
	ways_by_id[e.id] = e
	return e
	
func get_way_by_id(id: int, create_if_not_exists: bool = false) -> OSMWay:
	var e: OSMWay = ways_by_id.get(id)
	if e == null and create_if_not_exists:
		e = add_way(OSMWay.new(id))
	return e
	
func add_relation(e: OSMRelation) -> OSMRelation:
	relations.append(e)
	relations_by_id[e.id] = e
	return e
	
func get_relation_by_id(id: int, create_if_not_exists: bool = false) -> OSMRelation:
	var e: OSMRelation = relations_by_id.get(id)
	if e == null and create_if_not_exists:
		e = add_relation(OSMRelation.new(id))
	return e
	
func get_boundary() -> GeoBoundary:
	var boundary: GeoBoundary
	if nodes.size() > 0:
		boundary = GeoBoundary.new(
		nodes[0].location.lat, nodes[0].location.lon,
		nodes[0].location.lat, nodes[0].location.lon)
		for n in nodes:
			boundary.extend(n.location)
	else:
		boundary = GeoBoundary.new(0, 0, 0, 0)
	return boundary

