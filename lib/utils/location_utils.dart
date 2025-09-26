// lib/utils/location_utils.dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocha_point/config/app_config.dart';

class LocationUtils {
  static const LatLng _grazCenter = LatLng(47.0707, 15.4395);

  /// Get the default center point (Graz, Austria)
  static LatLng get defaultCenter => _grazCenter;

  /// Check if location services are enabled and permissions are granted
  static Future<LocationPermissionStatus> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  /// Request location permission from user
  static Future<LocationPermissionStatus> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ LocationUtils: Error requesting permission: $e');
      }
      return LocationPermissionStatus.denied;
    }
  }

  /// Get current user location with error handling
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // Check permission first
      final permissionStatus = await checkLocationPermission();

      if (permissionStatus != LocationPermissionStatus.granted) {
        // Try to request permission
        final requestResult = await requestLocationPermission();
        if (requestResult != LocationPermissionStatus.granted) {
          return LocationResult.error(
            'Location permission is required to find nearby coffee shops',
            permissionStatus,
          );
        }
      }

      // Get position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final location = LatLng(position.latitude, position.longitude);

      if (AppConfig.enableLogging) {
        print('📍 LocationUtils: Got location: ${location.latitude}, ${location.longitude}');
      }

      return LocationResult.success(location);

    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ LocationUtils: Error getting location: $e');
      }

      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Location permission denied.';
      } else {
        errorMessage = 'Unable to get your location. Showing default area.';
      }

      return LocationResult.error(errorMessage, LocationPermissionStatus.denied);
    }
  }

  /// Calculate distance between two points
  static double calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Get walking time estimate based on distance
  static String getWalkingTimeEstimate(double distanceKm) {
    // Average walking speed: 5 km/h
    const double walkingSpeedKmh = 5.0;
    final double timeHours = distanceKm / walkingSpeedKmh;
    final int timeMinutes = (timeHours * 60).round();

    if (timeMinutes < 1) {
      return '< 1 min';
    } else if (timeMinutes < 60) {
      return '$timeMinutes min';
    } else {
      final int hours = timeMinutes ~/ 60;
      final int remainingMinutes = timeMinutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Check if location is within Graz area (rough bounds)
  static bool isWithinGrazArea(LatLng location) {
    // Rough bounds for Graz metropolitan area
    const double minLat = 46.9;
    const double maxLat = 47.2;
    const double minLng = 15.2;
    const double maxLng = 15.7;

    return location.latitude >= minLat &&
        location.latitude <= maxLat &&
        location.longitude >= minLng &&
        location.longitude <= maxLng;
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationResult {
  final bool isSuccess;
  final LatLng? location;
  final String? errorMessage;
  final LocationPermissionStatus? permissionStatus;

  LocationResult._({
    required this.isSuccess,
    this.location,
    this.errorMessage,
    this.permissionStatus,
  });

  factory LocationResult.success(LatLng location) {
    return LocationResult._(
      isSuccess: true,
      location: location,
    );
  }

  factory LocationResult.error(String message, LocationPermissionStatus status) {
    return LocationResult._(
      isSuccess: false,
      errorMessage: message,
      permissionStatus: status,
    );
  }
}