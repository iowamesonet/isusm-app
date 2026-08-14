import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/observation.dart';
import '../models/station.dart';
import '../services/mesonet_service.dart';

const Duration _refreshInterval = Duration(minutes: 5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MesonetService _service = MesonetService();
  Timer? _refreshTimer;

  List<Station> _stations = [];
  Map<String, Observation> _observations = {};
  Station? _selectedStation;

  bool _loadingStations = true;
  bool _loadingObservation = false;
  String? _error;
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => _loadObservations(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loadingStations = true;
      _error = null;
    });
    try {
      final stations = await _service.fetchStations();
      setState(() {
        _stations = stations;
        _selectedStation = stations.isNotEmpty ? stations.first : null;
        _loadingStations = false;
      });
      await _loadObservations();
    } catch (e) {
      setState(() {
        _error = 'Unable to load stations: $e';
        _loadingStations = false;
      });
    }
  }

  Future<void> _loadObservations() async {
    setState(() => _loadingObservation = true);
    try {
      final observations = await _service.fetchObservations();
      setState(() {
        _observations = observations;
        _loadingObservation = false;
        _lastRefreshed = DateTime.now();
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load observations: $e';
        _loadingObservation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final observation = _selectedStation == null
        ? null
        : _observations[_selectedStation!.id];

    return Scaffold(
      appBar: AppBar(title: const Text('ISU Soil Moisture App')),
      body: RefreshIndicator(
        onRefresh: _loadObservations,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStationSelector(),
            const SizedBox(height: 16),
            if (_error != null) _buildError(_error!),
            if (_loadingStations)
              const Center(child: CircularProgressIndicator())
            else if (_selectedStation != null)
              _buildObservationCard(observation),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSelector() {
    return DropdownButtonFormField<Station>(
      initialValue: _selectedStation,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Station',
        border: OutlineInputBorder(),
      ),
      items: _stations
          .map(
            (station) => DropdownMenuItem(
              value: station,
              child: Text(station.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (station) => setState(() => _selectedStation = station),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildObservationCard(Observation? observation) {
    if (_loadingObservation && observation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (observation == null) {
      return const Text('No observation data available for this station.');
    }

    final validLocal = observation.validUtc.toLocal();
    final rows = <(String, String)>[
      ('Observation Time', DateFormat.yMd().add_jm().format(validLocal)),
      ('Air Temperature', _fmt(observation.tmpf, '°F')),
      ('Dew Point', _fmt(observation.dwpf, '°F')),
      ('Relative Humidity', _fmt(observation.rh, '%')),
      ('Today\'s High', _fmt(observation.high, '°F')),
      ('Today\'s Low', _fmt(observation.low, '°F')),
      ('Wind', observation.wind ?? 'M'),
      ('Wind Gust', _fmt(observation.gust, 'mph')),
      ('Solar Radiation', _fmt(observation.sradWm2, 'W/m²')),
      ('Hourly Precip', _fmt(observation.hrprecip, 'in')),
      ('Today\'s Precip', _fmt(observation.pday, 'in')),
      ('Trailing 24hr Precip', _fmt(observation.p24i, 'in')),
      ('Month Precip', _fmt(observation.pmonth, 'in')),
      ('Daily ET', _fmt(observation.dailyet, 'in')),
      ('Soil Temp (4in)', _fmt(observation.soil04t, '°F')),
      ('Soil Temp (12in)', _fmt(observation.soil12t, '°F')),
      ('Soil Temp (24in)', _fmt(observation.soil24t, '°F')),
      ('Soil Temp (50in)', _fmt(observation.soil50t, '°F')),
      ('Soil Moisture (12in)', _fmt(observation.soil12m, '%')),
      ('Soil Moisture (24in)', _fmt(observation.soil24m, '%')),
      ('Soil Moisture (50in)', _fmt(observation.soil50m, '%')),
      ('Battery Voltage', _fmt(observation.bat, 'V')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              observation.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(row.$1), Text(row.$2)],
                ),
              ),
            const SizedBox(height: 8),
            if (_lastRefreshed != null)
              Text(
                'Last refreshed: ${DateFormat.jm().format(_lastRefreshed!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(double? value, String unit) {
    if (value == null) return 'M';
    return '${value.toStringAsFixed(1)} $unit';
  }
}
