'use strict'

Data =
  coords: { 'latitude': 40.783333, 'longitude': -73.966667 }
  infoWindow: new google.maps.InfoWindow()
  wikimapiaPlaces: []
  gmapsPolygons: {}


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
  showInfoWindow: (place, latLng) ->
    Data.infoWindow.setContent '<strong>' + place.name + '</strong><br>' +
      '<a href="' + place.url + '" target="_blank">See in Wikimapia</a>'
    Data.infoWindow.setPosition latLng
    Data.infoWindow.open GMap.map_el

  highlight: (pol_id, opacity = 0.25) ->
    Data.gmapsPolygons[pol_id].polygon.setOptions { 'fillOpacity': opacity }


GMap =
  map_el: null
  marker: null
  defaultZoom: 16

  draw: ->
    return if @map_el
    @map_el = new google.maps.Map(document.getElementById('map_canvas'),
      zoom: @defaultZoom
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
      center: @currentLocation()
    )
    @marker = new google.maps.Marker(
      position: @currentLocation()
      map: @map_el
    )

    # Click on map
    google.maps.event.addListener(GMap.map_el, 'click', (event) ->
      GMap.updateCoords { 'latitude': event.latLng.Ya, 'longitude': event.latLng.Za }
    )

  addPolygonFor: (place) ->
    return if Data.gmapsPolygons['pol_' + place.id]

    polygon = new google.maps.Polygon(
      paths: $.map(place.polygon, (p,i) -> new google.maps.LatLng(p.y, p.x))
      map: @map_el
      strokeColor: "#FF0000"
      strokeOpacity: 0.8
      strokeWeight: 2
      fillColor: "#FF0000"
      fillOpacity: 0.25
    )
    Data.gmapsPolygons['pol_' + place.id] = {
      place:
        id: place.id
        name: place.name,
        url: place.url
      polygon: polygon
    }

    google.maps.event.addListener(polygon, 'click', (event) ->
      Helpers.showInfoWindow place, event.latLng
    )

  currentLocation: ->
    new google.maps.LatLng(Data.coords.latitude, Data.coords.longitude)

  updateCoords: (coords) ->
    Data.coords = coords
    Wikimapia.getPlaces()
    if @marker
      @marker.setPosition @currentLocation()
      @map_el.setCenter @marker.getPosition()
      @map_el.setZoom @defaultZoom

  # Leave some space for iPhones to move over the page, and not only the map
  setSize: ->
    $('#map_canvas').css
      width: window.innerWidth - 20
      height: window.innerHeight


Wikimapia =
  key: 'C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539'

  url: (count = 40, radius = 0.0032) ->
    'http://api.wikimapia.org/?function=box&format=json&key=' + @key +
    '&lat_min=' + String(Data.coords.latitude - radius) +
    '&lat_max=' + String(Data.coords.latitude + radius) +
    '&lon_min=' + String(Data.coords.longitude - radius) +
    '&lon_max=' + String(Data.coords.longitude + radius) +
    '&count=' + String(count)

  getPlaces: ->
    $.getJSON(@url(), ((data) ->
      Data.wikimapiaPlaces = data.folder
      Wikimapia.draw()
    ))

  draw: ->
    for place in Data.wikimapiaPlaces
      GMap.addPolygonFor place


window.onload = ->
  GMap.draw()
  GMap.setSize()
  Geolocalize.start()
  $(window).bind 'orientationchange resize', GMap.setSize
