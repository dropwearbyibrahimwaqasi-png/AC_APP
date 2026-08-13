import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/day_summary.dart';
import '../models/stay.dart';
import '../theme.dart';
import 'location_details_screen.dart';

class AllLocationsScreen extends StatefulWidget {
  const AllLocationsScreen({super.key});

  @override
  State<AllLocationsScreen> createState() => _AllLocationsScreenState();
}

class _AllLocationsScreenState extends State<AllLocationsScreen> {
  final ApiService _api = ApiService();
  late Future<DaySummary> _dataFuture;
  bool _mapView = true;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<DaySummary> _load() {
    final today = DateTime.now();
    final dateStr = '${today.year}-${_two(today.month)}-${_two(today.day)}';
    return _api.fetchDaySummary(dateStr);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Locations')),
      body: FutureBuilder<DaySummary>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          final stays = summary?.stays ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Map View')),
                    ButtonSegment(value: false, label: Text('List View')),
                  ],
                  selected: {_mapView},
                  onSelectionChanged: (s) => setState(() => _mapView = s.first),
                ),
              ),
              Expanded(
                child: stays.isEmpty
                    ? const Center(child: Text('No locations recorded for today.'))
                    : _mapView
                        ? _buildMap(stays)
                        : _buildList(stays),
              ),
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _summaryTile('Locations Visited', '${stays.length}')),
                      const SizedBox(width: 12),
                      Expanded(child: _summaryTile('Total Time', _formatMinutes(summary.trackedMinutes))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Stay> stays) {
    final points = stays.map((s) => LatLng(s.latitude, s.longitude)).toList();
    return FlutterMap(
      options: MapOptions(initialCenter: points.last, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.actracker.mobile',
        ),
        PolylineLayer(polylines: [
          Polyline(points: points, strokeWidth: 4, color: AppColors.primary),
        ]),
        MarkerLayer(markers: [
          for (var i = 0; i < points.length; i++)
            Marker(
              point: points[i],
              width: 34,
              height: 34,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LocationDetailsScreen(stay: stays[i])),
                ),
                child: const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildList(List<Stay> stays) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stays.length,
      itemBuilder: (context, i) {
        final s = stays[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.redAccent),
            title: Text('${s.from} - ${s.to}'),
            subtitle: Text('${s.durationMinutes} min  •  ${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LocationDetailsScreen(stay: s)),
            ),
          ),
        );
      },
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Widget _summaryTile(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
