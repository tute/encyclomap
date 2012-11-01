(function () {
    'use strict';

    var Helpers = {
        iterateWikimapia: function () {
            var i,
                arr = GeoPos.wikimapia_places.folder,
                len = arr.length,
                content = '';
            for (i = 0; i < len; ++i) {
                content += '<li>' + arr[i].name + '</li>';
            }
            document.getElementById('places').innerHTML = content;
        }
    };

    var GeoPos = {
        key: 'C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539',
        map_canvas: document.getElementById('map_canvas'),
        coords: null,
        wikimapia_places: null,
        errHandler: function (virheKoodi) {
            if (virheKoodi.code >= 0) {
                console.log(virheKoodi.code);
                return false;
            }
        },
        getCoords: function (position) {
            GeoPos.coords = position.coords;
            var center = new google.maps.LatLng(
                    GeoPos.coords.latitude,
                    GeoPos.coords.longitude
                ),
                map = new google.maps.Map(GeoPos.map_canvas, {
                    zoom: 16,
                    mapTypeId: google.maps.MapTypeId.ROADMAP,
                    center: center
                }),
                circle = new google.maps.Circle({
                    center: center,
                    radius: GeoPos.coords.accuracy,
                    map: map,
                    fillColor: 'blue',
                    strokeColor: 'blue'
                }),
                marker = new google.maps.Marker({
                    position: center,
                    map: map
                });
        },
        getPosition: function () {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    this.getCoords,
                    this.errHandler,
                    { maximumAge: 60000 }
                );
            } else {
                console.log("Your browser does not support Geolocation");
            }
        },
        askWikimapia: function () {
            var url = 'http://api.wikimapia.org/?function=box&key=' + GeoPos.key +
                '&lat_min=40.6&lat_max=40.7&lon_min=-74&lon_max=-73.8' +
                '&count=20&format=json'
            jx.load(
                url,
                function (data) {
                    GeoPos.wikimapia_places = data;
                    Helpers.iterateWikimapia();
                },
                'json'
            );
        }
    };

    window.onload = function () {
        GeoPos.getPosition();
        GeoPos.askWikimapia();
    };
}());
