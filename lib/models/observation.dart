/// Represents a single hourly observation for an ISUSM station, sourced from
/// the agclimate.geojson feed. Numeric fields may arrive as numbers, numeric
/// strings, or the sentinel string "M" (missing), so all are parsed leniently.
class Observation {
  final String stationId;
  final String name;
  final DateTime validUtc;
  final double? tmpf;
  final double? dwpf;
  final double? rh;
  final double? high;
  final double? low;
  final double? hrprecip;
  final double? pday;
  final double? p24i;
  final double? pmonth;
  final double? dailyet;
  final double? sradWm2;
  final double? bat;
  final double? gust;
  final String? wind;
  final double? soil04t;
  final double? soil12t;
  final double? soil24t;
  final double? soil50t;
  final double? soil12m;
  final double? soil24m;
  final double? soil50m;

  const Observation({
    required this.stationId,
    required this.name,
    required this.validUtc,
    this.tmpf,
    this.dwpf,
    this.rh,
    this.high,
    this.low,
    this.hrprecip,
    this.pday,
    this.p24i,
    this.pmonth,
    this.dailyet,
    this.sradWm2,
    this.bat,
    this.gust,
    this.wind,
    this.soil04t,
    this.soil12t,
    this.soil24t,
    this.soil50t,
    this.soil12m,
    this.soil24m,
    this.soil50m,
  });

  /// Parses a field that may be a number, a numeric string, a string with a
  /// trailing "%" sign, or the sentinel "M" meaning missing data.
  static double? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll('%', '');
      if (cleaned.isEmpty || cleaned.toUpperCase() == 'M') return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// Casts a field to a String if it is one, ignoring other types instead of
  /// throwing (e.g. a stray numeric value where a string is expected).
  static String? _parseString(dynamic value) => value is String ? value : null;

  factory Observation.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final rawProperties = feature['properties'];
    if (rawProperties is! Map<String, dynamic>) {
      throw const FormatException('Feature is missing a "properties" map');
    }
    final properties = rawProperties;

    final stationId = feature['id'];
    if (stationId is! String) {
      throw const FormatException('Feature is missing a string "id"');
    }

    final validUtcRaw = properties['valid_utc'];
    if (validUtcRaw is! String) {
      throw const FormatException('Feature is missing "valid_utc"');
    }
    final validUtc = DateTime.parse(validUtcRaw);

    return Observation(
      stationId: stationId,
      name: _parseString(properties['name']) ?? '',
      validUtc: validUtc,
      tmpf: _parseNum(properties['tmpf']),
      dwpf: _parseNum(properties['dwpf']),
      rh: _parseNum(properties['rh']),
      high: _parseNum(properties['high']),
      low: _parseNum(properties['low']),
      hrprecip: _parseNum(properties['hrprecip']),
      pday: _parseNum(properties['pday']),
      p24i: _parseNum(properties['p24i']),
      pmonth: _parseNum(properties['pmonth']),
      dailyet: _parseNum(properties['dailyet']),
      sradWm2: _parseNum(properties['srad_wm2']),
      bat: _parseNum(properties['bat']),
      gust: _parseNum(properties['gust']),
      wind: _parseString(properties['wind']),
      soil04t: _parseNum(properties['soil04t']),
      soil12t: _parseNum(properties['soil12t']),
      soil24t: _parseNum(properties['soil24t']),
      soil50t: _parseNum(properties['soil50t']),
      soil12m: _parseNum(properties['soil12m']),
      soil24m: _parseNum(properties['soil24m']),
      soil50m: _parseNum(properties['soil50m']),
    );
  }
}
