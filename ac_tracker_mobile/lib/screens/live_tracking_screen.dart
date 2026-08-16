import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/location_service.dart' as tracker;
import '../models/day_summary.dart';
import '../theme.dart';
import 'location_details_screen.dart';
import 'all_locations_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final ApiService _api = ApiService();
  late Future<DaySummary> _dataFuture;
  bool _tracking = true;

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

  void _toggleTracking() async {
    if (_tracking) {
      tracker.stopLocationTracking();
      setState(() => _tracking = false);
      return;
    }
    final granted = await tracker.requestLocationPermissions();
    if (granted) {
      await tracker.startLocationTracking();
      setState(() => _tracking = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission not granted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'All locations',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllLocationsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DaySummary>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          // Stays are the (approximate) route: markers connected in time
          // order. This traces place-to-place, not the raw GPS trail.
          final points = (summary?.stays ?? [])
              .map((s) => LatLng(s.latitude, s.longitude))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, color: _tracking ? Colors.green : Colors.grey, size: 12),
                        const SizedBox(width: 6),
                        Text(_tracking ? 'Tracking Active' : 'Tracking Paused',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Tracking your location in background', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statChip('Today\'s Distance', '${summary?.distanceKm ?? '-'} km'),
                        const SizedBox(width: 10),
                        _statChip('Locations', '${summary?.stays.length ?? '-'}'),
                        const SizedBox(width: 10),
                        _statChip('Time Tracked', _formatMinutes(summary?.trackedMinutes)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: points.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No location data yet today.'),
                            const SizedBox(height: 6),
                            Text(
                              summary == null
                                  ? ''
                                  : summary.rawPointCount == 0
                                      ? 'No GPS fixes received yet — check location permission is set to "Allow all the time".'
                                      : '${summary.rawPointCount} GPS fix(es) received, none have stayed in one place for 5+ min yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
                        options: MapOptions(initialCenter: points.last, initialZoom: 13),
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
                                    MaterialPageRoute(
                                      builder: (_) => LocationDetailsScreen(stay: summary!.stays[i]),
                                    ),
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.redAccent, size: 34),
                                ),
                              ),
                          ]),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tracking ? Colors.redAccent : AppColors.primary,
                  ),
                  icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_tracking ? 'Stop Tracking' : 'Resume Tracking'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatMinutes(int? minutes) {
    if (minutes == null) return '-';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Widget _statChip(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
