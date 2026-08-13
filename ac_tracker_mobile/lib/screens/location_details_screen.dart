import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/stay.dart';
import '../theme.dart';

class LocationDetailsScreen extends StatelessWidget {
  final Stay stay;
  const LocationDetailsScreen({super.key, required this.stay});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(stay.latitude, stay.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Location Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${stay.latitude.toStringAsFixed(5)}, ${stay.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.visited.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${stay.durationMinutes} min',
                    style: const TextStyle(color: AppColors.visited, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${stay.from} - ${stay.to}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          const Text('On Map', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.actracker.mobile',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: point,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Stay Duration', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${stay.from} - ${stay.to} (${stay.durationMinutes} min)'),
          const SizedBox(height: 16),
          const Text('Coordinates', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${stay.latitude}, ${stay.longitude}'),
          const SizedBox(height: 20),
          const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes about this location...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: saving notes on a location isn\'t wired to the backend yet — '
            'this field is a placeholder for now.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
