import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../models/observation.dart';
import '../models/station.dart';

/// Client for the Iowa Environmental Mesonet (IEM) ISUSM data feeds.
class MesonetService {
  static const String stationsUrl =
      'https://mesonet.agron.iastate.edu/api/1/network/ISUSM.geojson';
  static const String observationsUrl =
      'https://mesonet.agron.iastate.edu/geojson/agclimate.geojson';

  final http.Client _client;

  MesonetService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the list of ISUSM stations, sorted alphabetically by name.
  Future<List<Station>> fetchStations() async {
    final response = await _client.get(Uri.parse(stationsUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load stations (HTTP ${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final stations = <Station>[];
    for (final feature in features) {
      try {
        stations.add(
          Station.fromGeoJsonFeature(feature as Map<String, dynamic>),
        );
      } on FormatException catch (e) {
        // Skip a single malformed station rather than failing the whole list.
        developer.log(
          'Skipping malformed station feature: $e',
          name: 'MesonetService',
        );
      }
    }
    stations.sort((a, b) => a.name.compareTo(b.name));
    return stations;
  }

  /// Fetches the latest observations for all stations, keyed by station id.
  Future<Map<String, Observation>> fetchObservations() async {
    final response = await _client.get(Uri.parse(observationsUrl));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load observations (HTTP ${response.statusCode})',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    final observations = <String, Observation>{};
    for (final feature in features) {
      try {
        final observation = Observation.fromGeoJsonFeature(
          feature as Map<String, dynamic>,
        );
        observations[observation.stationId] = observation;
      } on FormatException catch (e) {
        // Skip a single malformed observation rather than failing the whole batch.
        developer.log(
          'Skipping malformed observation feature: $e',
          name: 'MesonetService',
        );
      }
    }
    return observations;
  }

  void dispose() => _client.close();
}
