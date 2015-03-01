'use strict'

Data =
  coords: { 'latitude': 40.783333, 'longitude': -73.966667 }
  cityName: 'New York'
  infoWindow: new google.maps.InfoWindow()
  wikimapiaPlaces: []
  gmapsPolygons: {}


Retina =
  updateSources: ->
    return unless window.devicePixelRatio > 1
    photos = ['back-to-top', 'help', 'logo', 'map-me', 'search']
    $.each photos, (i, photoName) ->
      oldSrc = "/images/#{photoName}.png"
      newSrc = "/images/#{photoName}-retina.png"
      $("[src='#{oldSrc}']").attr('src', newSrc)


# Perform geolocalization, or fallback to default coordinates
Geolocalize =
  start: ->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition @success, @error
    else
      @error('code': 'NOT_SUPPORTED')

  success: (position) ->
    GMap.updateCoords position.coords

  error: (error) ->
    # error.code.{PERMISSION_DENIED|POSITION_UNAVAILABLE|TIMEOUT|UNKNOWN_ERROR}
    GMap.updateCoords Data.coords


Helpers =
  showInfoWindow: (place, latLng) ->
    Data.infoWindow.setContent '<strong>' + place.name + '</strong>' +
      '<br><br>' +
      '<a href="' + @googleItUrl(place) + '" target="_blank">In Google</a>' +
      ' &nbsp; – &nbsp; ' +
      '<a href="' + place.url + '" target="_blank">In Wikimapia</a>'
    Data.infoWindow.setPosition latLng
    Data.infoWindow.open GMap.map_el

  googleItUrl: (place) ->
    'https://www.google.com/search?q=' + place.name + ', ' + Data.cityName

  highlight: (pol_id, opacity = 0.25) ->
    Data.gmapsPolygons[pol_id].polygon.setOptions { 'fillOpacity': opacity }


GMap =
  map_el: null
  marker: null
  defaultZoom: 16
  geocoder: new google.maps.Geocoder()

  draw: ->
    return if @map_el
    @map_el = new google.maps.Map(document.getElementById('map_canvas'),
      zoom: @defaultZoom
      mapTypeId: google.maps.MapTypeId.ROADMAP
      scrollwheel: false
      center: @latLng()
    )
    @marker = new google.maps.Marker(
      position: @latLng()
      draggable: true
      map: @map_el
    )
    google.maps.event.addListener(GMap.marker, 'dragend', ->
      position = GMap.marker.getPosition()
      GMap.updateCoords
        'latitude': position.lat()
        'longitude': position.lng()
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

  search: ->
    @geocoder.geocode
      address: $('#search_address').val(),
      (results, status) ->
        if status is google.maps.GeocoderStatus.OK
          loc = results[0].geometry.location
          GMap.updateCoords { 'latitude': loc.lat(), 'longitude': loc.lng() }
        else
          alert 'Not found, please try other search terms.'

  updateCoords: (coords) ->
    Data.coords = coords
    @setCity()
    Wikimapia.getPlaces()
    if @marker
      @marker.setPosition @latLng()
      @map_el.setCenter @marker.getPosition()
      @map_el.setZoom @defaultZoom

  setCity: ->
    @geocoder.geocode latLng: @latLng(), (results, status) ->
      if status is google.maps.GeocoderStatus.OK
        for place in results[0].address_components
          if GMap.isCity(place.types[0])
            Data.cityName = place.long_name
            return
          null

  latLng: ->
    new google.maps.LatLng(Data.coords.latitude, Data.coords.longitude)

  isCity: (placeType) ->
    placeType == 'administrative_area_level_1' || placeType == 'locality'

  # Leave some space for iPhones to move over the page, and not only the map
  setSize: ->
    $('#map_canvas').css
      width: window.innerWidth - 10
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
    $.getJSON @url(), (data) ->
      Data.wikimapiaPlaces = data.folder
      Wikimapia.draw()

  draw: ->
    for place in Data.wikimapiaPlaces
      GMap.addPolygonFor place


window.onload = ->
  Retina.updateSources()
  GMap.draw()
  GMap.setSize()
  Geolocalize.start()
  $(window).bind 'orientationchange resize', GMap.setSize
