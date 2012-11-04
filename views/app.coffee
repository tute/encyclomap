'use strict'

Data =
  coords: { 'latitude': 40.7142, 'longitude': -74.0064 }
  infoWindow: new google.maps.InfoWindow()
  wikimapia_places: []
  gmaps_polygons: {}


# Perform geolocalization, or fallback to default coordinates
Geolocalize =
  start: ->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition @success, @error
    else
      @error({ 'code': 'NOT_SUPPORTED' })

  success: (position) ->
    GMap.updateCoords position.coords

  error: (error) ->
    # error.code.{PERMISSION_DENIED|POSITION_UNAVAILABLE|TIMEOUT|UNKNOWN_ERROR}
    GMap.updateCoords Data.coords


Helpers =
  showInfoWindow: (title, latLng) ->
    Data.infoWindow.setContent title
    Data.infoWindow.setPosition latLng
    Data.infoWindow.open GMap.map_el

  highlight: (pol_id, opacity = 0.25) ->
    Data.gmaps_polygons[pol_id].polygon.setOptions { 'fillOpacity': opacity }

  setPlaceEvents: ->
    $(document).on('mouseenter', 'ul#places li', ->
      $(this).attr('style', 'font-weight:bold')
      javascript:Helpers.highlight($(this).attr('id'), 0.75)
    )
    $(document).on('mouseleave', 'ul#places li', ->
      $(this).attr('style', 'font-weight:normal')
      javascript:Helpers.highlight($(this).attr('id'))
    )


GMap =
  map_el: null
  marker: null

  draw: ->
    return if GMap.map_el
    GMap.map_el = new google.maps.Map(document.getElementById('map_canvas'),
      zoom: 16
      mapTypeId: google.maps.MapTypeId.ROADMAP
      center: GMap.current_location()
    )
    GMap.marker = new google.maps.Marker(
      position: GMap.current_location()
      draggable: true
      map: GMap.map_el
    )
    google.maps.event.addListener(GMap.marker, 'dragend', ->
      position = GMap.marker.getPosition()
      GMap.updateCoords { 'latitude': position.Ya, 'longitude': position.Za }
    )

  add_polygon_for: (place) ->
    return if Data.gmaps_polygons['pol_' + place.id]

    polygon = new google.maps.Polygon(
      paths: $.map(place.polygon, (p,i) -> new google.maps.LatLng(p.y, p.x))
      map: GMap.map_el
      strokeColor: "#FF0000"
      strokeOpacity: 0.8
      strokeWeight: 2
      fillColor: "#FF0000"
      fillOpacity: 0.25
    )
    Data.gmaps_polygons['pol_' + place.id] = {
      title: place.name,
      polygon: polygon
    }

    # FIXME: Only grabbing last place
    google.maps.event.addListener(polygon, 'click', (event) ->
      Helpers.showInfoWindow place.name, event.latLng
    );

  current_location: ->
    new google.maps.LatLng(Data.coords.latitude, Data.coords.longitude)

  updateCoords: (coords) ->
    Data.coords = coords
    Wikimapia.getPlaces()
    if GMap.marker
      GMap.marker.setPosition(GMap.current_location())
      GMap.map_el.setCenter(GMap.marker.getPosition())
      GMap.map_el.setZoom(16)


Wikimapia =
  key: 'C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539'

  url: (count = 30, radius = 0.003) ->
    'http://api.wikimapia.org/?function=box&format=json&key=' + @key +
    '&lat_min=' + String(Data.coords.latitude - radius) +
    '&lat_max=' + String(Data.coords.latitude + radius) +
    '&lon_min=' + String(Data.coords.longitude - radius) +
    '&lon_max=' + String(Data.coords.longitude + radius) +
    '&count=' + String(count)

  getPlaces: ->
    $.getJSON(@url(), ((data) ->
      Data.wikimapia_places = data.folder
      Wikimapia.draw()
    ))

  draw: ->
    $('#places').html ''
    for place in Data.wikimapia_places
      $('#places').append '<li id="pol_' + place.id + '"><a href="' + place.url + '" target="_blank">' + place.name + '</a></li>'
      GMap.add_polygon_for place


window.onload = ->
  GMap.draw()
  Helpers.setPlaceEvents()
  Geolocalize.start()
