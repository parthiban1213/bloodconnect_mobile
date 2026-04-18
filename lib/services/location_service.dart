import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Represents a user's location (GPS or fallback).
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isGps; // true = from GPS, false = from profile/manual

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isGps = false,
  });
}

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  UserLocation? _cachedLocation;
  bool _permissionDenied = false;

  /// Whether location permission was denied by the user.
  bool get isPermissionDenied => _permissionDenied;

  /// Last known location (GPS or fallback).
  UserLocation? get currentLocation => _cachedLocation;

  /// Try to get the user's GPS location.
  /// Returns null if permission denied or location unavailable.
  /// Call this once when the feed screen loads.
  Future<UserLocation?> requestGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled');
        _permissionDenied = true;
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Permission denied');
          _permissionDenied = true;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permission denied forever');
        _permissionDenied = true;
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      _cachedLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        isGps: true,
      );
      _permissionDenied = false;
      debugPrint('[LocationService] GPS: ${position.latitude}, ${position.longitude}');
      return _cachedLocation;
    } catch (e) {
      debugPrint('[LocationService] GPS error: $e');
      _permissionDenied = true;
      return null;
    }
  }

  /// Set a manual/fallback location (e.g. from geocoded city name).
  void setFallbackLocation(double lat, double lng) {
    _cachedLocation = UserLocation(latitude: lat, longitude: lng, isGps: false);
  }

  /// Clear cached location (e.g. on logout).
  void clear() {
    _cachedLocation = null;
    _permissionDenied = false;
  }

  /// Calculate distance in km between two points using Haversine formula.
  static double haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

/// Well-known city coordinates for fallback geocoding.
/// Used when user provides a city name in their profile but no GPS.
class CityCoordinates {
  static const Map<String, Map<String, double>> _cities = {
    'coimbatore':        {'lat': 11.0168, 'lng': 76.9558},
    'chennai':           {'lat': 13.0827, 'lng': 80.2707},
    'bangalore':         {'lat': 12.9716, 'lng': 77.5946},
    'bengaluru':         {'lat': 12.9716, 'lng': 77.5946},
    'mumbai':            {'lat': 19.0760, 'lng': 72.8777},
    'delhi':             {'lat': 28.6139, 'lng': 77.2090},
    'new delhi':         {'lat': 28.6139, 'lng': 77.2090},
    'hyderabad':         {'lat': 17.3850, 'lng': 78.4867},
    'pune':              {'lat': 18.5204, 'lng': 73.8567},
    'kolkata':           {'lat': 22.5726, 'lng': 88.3639},
    'ahmedabad':         {'lat': 23.0225, 'lng': 72.5714},
    'jaipur':            {'lat': 26.9124, 'lng': 75.7873},
    'lucknow':           {'lat': 26.8467, 'lng': 80.9462},
    'kochi':             {'lat': 9.9312,  'lng': 76.2673},
    'thiruvananthapuram': {'lat': 8.5241,  'lng': 76.9366},
    'madurai':           {'lat': 9.9252,  'lng': 78.1198},
    'trichy':            {'lat': 10.7905, 'lng': 78.7047},
    'tiruchirappalli':   {'lat': 10.7905, 'lng': 78.7047},
    'salem':             {'lat': 11.6643, 'lng': 78.1460},
    'erode':             {'lat': 11.3410, 'lng': 77.7172},
    'tiruppur':          {'lat': 11.1085, 'lng': 77.3411},
    'pollachi':          {'lat': 10.6609, 'lng': 77.0081},
  };

  /// Look up coordinates for a city name (case-insensitive).
  /// Returns null if the city is not in the lookup table.
  static Map<String, double>? lookup(String cityName) {
    final key = cityName.trim().toLowerCase();
    return _cities[key];
  }
}
