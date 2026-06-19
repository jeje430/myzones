/// Dark neon-inspired Google Maps style for ZONEZ explore screen.
const kZonezDarkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#08080e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#9e9eae"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#08080e"}]},
  {"featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{"color": "#2a2a38"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#6b6b7a"}]},
  {"featureType": "landscape", "elementType": "geometry", "stylers": [{"color": "#0c0c14"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#12121b"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#a020f0"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#0e1418"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#00ffff"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a1a24"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#2a2a38"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#c4c4d0"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#1e1e2a"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#252535"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#a020f0"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#00ffff"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#12121b"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#a020f0"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#050510"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#00ffff"}]}
]
''';
