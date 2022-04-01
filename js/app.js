(function() {
  'use strict';
  var Data, Helpers, Retina, Wikimapia;

  Data = {
    coords: {
      'latitude': 40.783333,
      'longitude': -73.966667
    },
    cityName: 'New York',
    infoWindow: new google.maps.InfoWindow(),
    wikimapiaPlaces: [],
    gmapsPolygons: {}
  };

  Retina = {
    updateSources: function() {
      var photos;
      if (!(window.devicePixelRatio > 1)) {
        return;
      }
      photos = ['back-to-top', 'help', 'logo', 'map-me', 'search'];
      return $.each(photos, function(i, photoName) {
        var newSrc, oldSrc;
        oldSrc = "/encyclomap/images/" + photoName + ".png";
        newSrc = "/encyclomap/images/" + photoName + "-retina.png";
        return $("[src='" + oldSrc + "']").attr('src', newSrc);
      });
    }
  };

  window.Geolocalize = {
    start: function() {
      if (navigator.geolocation) {
        return navigator.geolocation.getCurrentPosition(this.success, this.error);
      } else {
        return this.error({
          'code': 'NOT_SUPPORTED'
        });
      }
    },
    success: function(position) {
      return GMap.updateCoords(position.coords);
    },
    error: function(error) {
      return GMap.updateCoords(Data.coords);
    }
  };

  Helpers = {
    showInfoWindow: function(place, latLng) {
      Data.infoWindow.setContent('<strong>' + place.name + '</strong>' + '<br><br>' + '<a href="' + this.googleItUrl(place) + '" target="_blank">In Google</a>' + ' &nbsp; – &nbsp; ' + '<a href="' + place.url + '" target="_blank">In Wikimapia</a>');
      Data.infoWindow.setPosition(latLng);
      return Data.infoWindow.open(GMap.map_el);
    },
    googleItUrl: function(place) {
      return 'https://www.google.com/search?q=' + place.name + ', ' + Data.cityName;
    },
    highlight: function(pol_id, opacity) {
      if (opacity == null) {
        opacity = 0.25;
      }
      return Data.gmapsPolygons[pol_id].polygon.setOptions({
        'fillOpacity': opacity
      });
    }
  };

  window.GMap = {
    map_el: null,
    marker: null,
    defaultZoom: 16,
    geocoder: new google.maps.Geocoder(),
    draw: function() {
      if (this.map_el) {
        return;
      }
      this.map_el = new google.maps.Map(document.getElementById('map_canvas'), {
        zoom: this.defaultZoom,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        scrollwheel: false,
        center: this.latLng()
      });
      this.marker = new google.maps.Marker({
        position: this.latLng(),
        draggable: true,
        map: this.map_el
      });
      return google.maps.event.addListener(GMap.marker, 'dragend', function() {
        var position;
        position = GMap.marker.getPosition();
        return GMap.updateCoords({
          'latitude': position.lat(),
          'longitude': position.lng()
        });
      });
    },
    addPolygonFor: function(place) {
      var polygon;
      if (Data.gmapsPolygons['pol_' + place.id]) {
        return;
      }
      polygon = new google.maps.Polygon({
        paths: $.map(place.polygon, function(p, i) {
          return new google.maps.LatLng(p.y, p.x);
        }),
        map: this.map_el,
        strokeColor: "#FF0000",
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: "#FF0000",
        fillOpacity: 0.25
      });
      Data.gmapsPolygons['pol_' + place.id] = {
        place: {
          id: place.id,
          name: place.name,
          url: place.url
        },
        polygon: polygon
      };
      return google.maps.event.addListener(polygon, 'click', function(event) {
        return Helpers.showInfoWindow(place, event.latLng);
      });
    },
    search: function() {
      return this.geocoder.geocode({
        address: $('#search_address').val()
      }, function(results, status) {
        var loc;
        if (status === google.maps.GeocoderStatus.OK) {
          loc = results[0].geometry.location;
          return GMap.updateCoords({
            'latitude': loc.lat(),
            'longitude': loc.lng()
          });
        } else {
          return alert('Not found, please try other search terms.');
        }
      });
    },
    updateCoords: function(coords) {
      Data.coords = coords;
      this.setCity();
      Wikimapia.getPlaces();
      if (this.marker) {
        this.marker.setPosition(this.latLng());
        this.map_el.setCenter(this.marker.getPosition());
        return this.map_el.setZoom(this.defaultZoom);
      }
    },
    setCity: function() {
      return this.geocoder.geocode({
        latLng: this.latLng()
      }, function(results, status) {
        var place, _i, _len, _ref;
        if (status === google.maps.GeocoderStatus.OK) {
          _ref = results[0].address_components;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            place = _ref[_i];
            if (GMap.isCity(place.types[0])) {
              Data.cityName = place.long_name;
              return;
            }
            null;
          }
        }
      });
    },
    latLng: function() {
      return new google.maps.LatLng(Data.coords.latitude, Data.coords.longitude);
    },
    isCity: function(placeType) {
      return placeType === 'administrative_area_level_1' || placeType === 'locality';
    },
    setSize: function() {
      return $('#map_canvas').css({
        width: window.innerWidth - 10,
        height: window.innerHeight
      });
    }
  };

  Wikimapia = {
    key: 'C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539',
    url: function(count, radius) {
      if (count == null) {
        count = 40;
      }
      if (radius == null) {
        radius = 0.0032;
      }
      return 'http://api.wikimapia.org/?function=box&format=json&key=' + this.key + '&lat_min=' + String(Data.coords.latitude - radius) + '&lat_max=' + String(Data.coords.latitude + radius) + '&lon_min=' + String(Data.coords.longitude - radius) + '&lon_max=' + String(Data.coords.longitude + radius) + '&count=' + String(count);
    },
    getPlaces: function() {
      return $.getJSON(this.url(), function(data) {
        Data.wikimapiaPlaces = data.folder;
        return Wikimapia.draw();
      });
    },
    draw: function() {
      var place, _i, _len, _ref, _results;
      _ref = Data.wikimapiaPlaces;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        place = _ref[_i];
        _results.push(GMap.addPolygonFor(place));
      }
      return _results;
    }
  };

  window.onload = function() {
    Retina.updateSources();
    GMap.draw();
    GMap.setSize();
    Geolocalize.start();
    return $(window).bind('orientationchange resize', GMap.setSize);
  };

}).call(this);
