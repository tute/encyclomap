'use strict'

Data =
  coords: { 'latitude': 40.7142, 'longitude': -74.0064 }
  polygons: {}

  geolozalize: ->
    navigator.geolocation.getCurrentPosition Map.draw

  highlight: (pol_id, opacity = 0.25) ->
    @polygons[pol_id].polygon.setOptions { 'fillOpacity': opacity }


Helpers =
  infoWindow: new google.maps.InfoWindow()

  showInfoWindow: (title, latLng) ->
    Helpers.infoWindow.setContent title
    Helpers.infoWindow.setPosition latLng
    Helpers.infoWindow.open Map.map_el

  setPlaceEvents: ->
    $(document).on(
      'mouseenter',
      'ul#places li',
      () ->
        $(this).attr('style', 'font-weight:bold')
        javascript:Data.highlight($(this).attr('id'), 0.75)
    )
    $(document).on(
      'mouseleave',
      'ul#places li',
      () ->
        $(this).attr('style', 'font-weight:normal')
        javascript:Data.highlight($(this).attr('id'))
    )

  iterateWikimapia: ->
    content = ''
    for place in Wikimapia.places.folder
      pol_id = 'pol_' + place.id

      content += '<li id="' + pol_id + '"><a href="' + place.url + '" target="_blank">' + place.name + '</a></li>'

      points = []
      place.polygon.push(place.polygon[0]) # Close polygon
      for point in place.polygon
        points.push(new google.maps.LatLng(point.y, point.x))

      polygon = new google.maps.Polygon(
        paths: points
        map: Map.map_el
        strokeColor: "#FF0000"
        strokeOpacity: 0.8
        strokeWeight: 2
        fillColor: "#FF0000"
        fillOpacity: 0.25
      )
      Data.polygons[pol_id] = {
        title: place.name,
        polygon: polygon
      }

      google.maps.event.addListener(polygon, 'click', (event) ->
        Helpers.showInfoWindow place.name, event.latLng
      );

    document.getElementById('places').innerHTML = content
    Helpers.setPlaceEvents()


Map =
  map_el: undefined
  marker: undefined

  current_location: ->
    new google.maps.LatLng(Data.coords.latitude, Data.coords.longitude)

  draw: (position) ->
    Map.updateCoords(position.coords)

    Map.map_el = new google.maps.Map(document.getElementById('map_canvas'),
      zoom: 16
      mapTypeId: google.maps.MapTypeId.ROADMAP
      center: Map.current_location()
    )
    Map.marker = new google.maps.Marker(
      position: Map.current_location()
      draggable: true
      map: Map.map_el
    )
    google.maps.event.addListener(Map.marker, 'dragend', () ->
      position = Map.marker.getPosition()
      console.log position
      Map.updateCoords { 'latitude': position.Ya, 'longitude': position.Za }
    )


  updateCoords: (coords) ->
    Data.coords = coords
    Wikimapia.bringPlaces()
    if Map.marker
      Map.marker.setPosition(Map.current_location())
      Map.map_el.setCenter(Map.marker.getPosition())
      Map.map_el.setZoom(16)


Wikimapia =
  key: 'C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539'

  url: (count = 30, radius = 0.003) ->
    'http://api.wikimapia.org/?function=box&format=json&key=' + @key +
    '&lat_min=' + String(Data.coords.latitude - radius) +
    '&lat_max=' + String(Data.coords.latitude + radius) +
    '&lon_min=' + String(Data.coords.longitude - radius) +
    '&lon_max=' + String(Data.coords.longitude + radius) +
    '&count=' + String(count)

  bringPlaces: () ->
    $.getJSON(Wikimapia.url(), ((data) ->
      Wikimapia.places = data
      Helpers.iterateWikimapia()
    ))


window.onload = ->
  Data.geolozalize()
