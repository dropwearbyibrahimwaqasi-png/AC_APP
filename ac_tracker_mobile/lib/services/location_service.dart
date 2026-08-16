import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

const Duration trackInterval = Duration(minutes: 5);

StreamSubscription<Position>? _positionSub;
bool _tracking = false;

/// Requests the permissions needed for all-day background tracking. Call
/// this (from a screen, so there's a UI context for the system dialogs)
/// before calling [startLocationTracking].
Future<bool> requestLocationPermissions() async {
  final whileInUse = await Permission.location.request();
  if (!whileInUse.isGranted) return false;

  // Android shows this as a separate "Allow all the time" step — without
  // it, tracking stops as soon as the app isn't the active screen.
  final always = await Permission.locationAlways.request();
  await Permission.notification.request();

  return always.isGranted;
}

/// Checks whether background ("all the time") location access is already
/// granted, without showing any system dialog.
Future<bool> hasLocationPermissions() async {
  return await Permission.locationAlways.isGranted;
}

/// Starts the background tracker using geolocator's own foreground service
/// (its [ForegroundNotificationConfig] keeps a persistent notification and a
/// foreground service of type "location"). This path is accepted by Android
/// 15/16, unlike third-party background-service plugins which get their
/// startForegroundService call denied.
Future<void> startLocationTracking() async {
  if (_tracking) return;
  _tracking = true;

  final settings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    intervalDuration: trackInterval,
    distanceFilter: 0,
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'AC Field Tracker',
      notificationText: "Tracking today's visits",
      notificationChannelName: 'AC Field Tracker Location',
      setOngoing: true,
    ),
  );

  // Points that failed to upload stay here and are retried on the next fix,
  // instead of being lost on a network hiccup.
  final List<Map<String, dynamic>> pending = [];

  _positionSub = Geolocator.getPositionStream(locationSettings: settings)
      .listen(
        (position) async {
          pending.add({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'recorded_at': DateTime.now().toIso8601String(),
          });

          try {
            final response = await http.post(
              Uri.parse('$apiBaseUrl/location-logs'),
              headers: {
                'Content-Type': 'application/json',
                'X-API-Key': apiKey,
              },
              body: jsonEncode({'points': pending}),
            );

            if (response.statusCode == 201) {
              pending.clear();
            }
          } catch (_) {
            // Offline or backend unreachable — keep the point buffered and
            // try again on the next fix.
          }
        },
        onError: (Object _) {
          _tracking = false;
        },
        cancelOnError: true,
      );
}

Future<void> stopLocationTracking() async {
  await _positionSub?.cancel();
  _positionSub = null;
  _tracking = false;
}
