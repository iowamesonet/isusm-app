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
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    return Station(
      id: properties['id'] as String,
      name: (properties['name'] ?? properties['plot_name'] ?? '') as String,
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }
}
