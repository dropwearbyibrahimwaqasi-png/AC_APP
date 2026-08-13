import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

const Duration trackInterval = Duration(minutes: 5);

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

Future<void> startLocationTracking() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'ac_tracker_location',
      initialNotificationTitle: 'AC Field Tracker',
      initialNotificationContent: "Tracking today's visits",
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

void stopLocationTracking() {
  FlutterBackgroundService().invoke('stopService');
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((_) => service.stopSelf());

  // Points that failed to upload stay here and are retried next tick,
  // instead of being lost on a network hiccup.
  final List<Map<String, dynamic>> pending = [];

  Timer.periodic(trackInterval, (timer) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      pending.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'recorded_at': DateTime.now().toIso8601String(),
      });

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
      // try again on the next tick.
    }
  });
}
