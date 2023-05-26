@tool
class_name NominatimQueryParameters extends Resource

enum QueryType {
	FREEFORM_SEARCH,
	STRUCTURED_SEARCH,
	REVERSE_GEOCODING,
	ADDRESS_LOOKUP,
}

@export var query_type: QueryType

#@export_category("Freeform search")
@export_group("Freeform search")
@export var freeform_query: String

#@export_category("Structured search")
@export_group("Structured search")
@export var house_number: String
@export var street_name: String
@export var city: String
@export var county: String
@export var state: String
@export var country: String
@export var postal_code: String

#@export_category("Reverse geocoding")
@export_group("Reverse geocoding")
@export var coordinate: GeoLocation = GeoLocation.new(0, 0)

#@export_category("Address lookup")
@export_group("Address lookup")
@export var osm_ids: PackedStringArray

#@export_category("Output details")
@export_group("Output details")
@export var address_details: bool = false
@export var extra_tags: bool = false
@export var name_details: bool = false

#@export_category("Result limitation")
@export_group("Result limitation")
@export var country_codes: PackedStringArray
@export var exclude_place_ids: PackedInt64Array
@export var limit: int = 10
@export var viewbox: GeoBoundary
@export_range(0, 18, 1) var zoom: int = 18

