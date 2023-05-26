# godot-osm
 
Godot project around [OpenStreetMap](https://www.openstreetmap.org) ecosystem.

It just for personal interest, but everything is done in a way to provide reusable components to the outside world...

Nominatim
---------

A [Nominatim](https://nominatim.org) client is already inluded in a reusable form.

Nominatim is a service for searching in the OpenStreetMap database. OpenStreetMap also uses Nominatim for searching on their main map page.

With Nominatim your can make freeform search or structured search, which results in OpenStreetMap elements with names and coordinates, etc.
But you can also do geocoding, which is a reverse search, trying to return you what you can find in the world at a certian location.

You can define the search query parameters in a `NominatimQueryParameters` resource and pass it to a `NominatimClient` and get the result in JSON.
