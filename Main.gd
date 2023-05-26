@tool
class_name Main extends TabContainer

@onready var osm_tile_display: OSMTileDisplay = $"Slippy map/OSMTileDisplay"

func _on_nominatim_result_pressed(result):
	var result_boundary := NominatimClient.get_result_geo_boundary(result)
	if result_boundary != null:
		osm_tile_display.gizmo_option_boundary_higlight = OSMTileDisplay.GizmoOption.ON_WITH_LABEL
		osm_tile_display.highlighted_boundary = result_boundary
		osm_tile_display.zoom_to_region(result_boundary)
	else:
		osm_tile_display.geo_center = NominatimClient.get_result_geo_location(result)
		osm_tile_display.zoom = 18
