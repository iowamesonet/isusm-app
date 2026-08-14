/// Represents an ISU Soil Moisture Network (ISUSM) weather station.
class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final rawProperties = feature['properties'];
    if (rawProperties is! Map<String, dynamic>) {
      throw const FormatException('Feature is missing a "properties" map');
    }
    final properties = rawProperties;

    final id = properties['id'];
    if (id is! String) {
      throw const FormatException('Feature is missing a string "id"');
    }

    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) {
      throw const FormatException('Feature is missing a "geometry" map');
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException(
        'Feature geometry is missing "coordinates" with 2+ elements',
      );
    }
    final rawLon = coordinates[0];
    final rawLat = coordinates[1];
    if (rawLon is! num || rawLat is! num) {
      throw const FormatException('Feature coordinates must be numeric');
    }

    return Station(
      id: id,
      name: (properties['name'] ?? properties['plot_name'] ?? '') as String,
      longitude: rawLon.toDouble(),
      latitude: rawLat.toDouble(),
    );
  }
}
