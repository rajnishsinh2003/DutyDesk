import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class GeofenceResult {
  final bool isVerified;
  final double distanceMeters;
  final int allowedRadiusMeters;
  final String status; // 'verified', 'outside', 'no_coords'
  final String message;

  GeofenceResult({
    required this.isVerified,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    required this.status,
    required this.message,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} meters';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
  }
}

class LocationStatusResult {
  final bool isServiceEnabled;
  final LocationPermission permission;
  final bool isReady;
  final String? message;

  LocationStatusResult({
    required this.isServiceEnabled,
    required this.permission,
    required this.isReady,
    this.message,
  });
}

class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String? locationString;
  final String? mapsUrl;
  final String? errorMessage;
  final GeofenceResult? geofence;

  LocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.locationString,
    this.mapsUrl,
    this.errorMessage,
    this.geofence,
  });
}

class LocationService {
  /// Open native device GPS / Location settings
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open application permission settings
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Check whether GPS service is enabled and location permission is granted
  static Future<LocationStatusResult> checkLocationStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatusResult(
          isServiceEnabled: false,
          permission: LocationPermission.denied,
          isReady: false,
          message: 'Location / GPS service is disabled on device.',
        );
      }

      final permission = await Geolocator.checkPermission();
      final isGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      return LocationStatusResult(
        isServiceEnabled: true,
        permission: permission,
        isReady: isGranted,
        message: isGranted
            ? 'Location is active and ready.'
            : (permission == LocationPermission.deniedForever
                ? 'Location permission is permanently denied in device settings.'
                : 'Location permission is required.'),
      );
    } catch (e) {
      return LocationStatusResult(
        isServiceEnabled: false,
        permission: LocationPermission.denied,
        isReady: false,
        message: 'Could not check location status: $e',
      );
    }
  }

  /// Proactively request location permissions and check service activation
  static Future<LocationStatusResult> requestLocationAccess() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatusResult(
          isServiceEnabled: false,
          permission: LocationPermission.denied,
          isReady: false,
          message: 'Location services are disabled. Please turn on GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final isGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      return LocationStatusResult(
        isServiceEnabled: true,
        permission: permission,
        isReady: isGranted,
        message: isGranted
            ? 'Location permission granted.'
            : (permission == LocationPermission.deniedForever
                ? 'Location permission is permanently denied. Please enable in App Settings.'
                : 'Location permission is mandatory to mark duty attendance.'),
      );
    } catch (e) {
      return LocationStatusResult(
        isServiceEnabled: false,
        permission: LocationPermission.denied,
        isReady: false,
        message: 'Permission request failed: $e',
      );
    }
  }

  /// Calculate distance and verify geofence between staff coordinates and exam center
  static GeofenceResult verifyGeofence({
    required double staffLat,
    required double staffLng,
    double? centerLat,
    double? centerLng,
    int allowedRadiusMeters = 200,
  }) {
    if (centerLat == null || centerLng == null) {
      return GeofenceResult(
        isVerified: true,
        distanceMeters: 0,
        allowedRadiusMeters: allowedRadiusMeters,
        status: 'no_coords',
        message: 'Center GPS coordinates not configured (Standard GPS recorded).',
      );
    }

    final distance = Geolocator.distanceBetween(staffLat, staffLng, centerLat, centerLng);
    final isInside = distance <= allowedRadiusMeters;

    if (isInside) {
      final distStr = distance < 1000 ? '${distance.toStringAsFixed(0)} meters' : '${(distance / 1000).toStringAsFixed(2)} km';
      return GeofenceResult(
        isVerified: true,
        distanceMeters: distance,
        allowedRadiusMeters: allowedRadiusMeters,
        status: 'verified',
        message: 'Location Verified! You are within $distStr of the examination center.',
      );
    } else {
      final distStr = distance < 1000 ? '${distance.toStringAsFixed(0)} meters' : '${(distance / 1000).toStringAsFixed(2)} km';
      return GeofenceResult(
        isVerified: false,
        distanceMeters: distance,
        allowedRadiusMeters: allowedRadiusMeters,
        status: 'outside',
        message: 'You appear to be $distStr away from the examination center (Allowed radius: ${allowedRadiusMeters}m).',
      );
    }
  }

  /// Request GPS permission and fetch current device location (MANDATORY GPS CAPTURE)
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          errorMessage: 'Location services are disabled on your device. Please turn on GPS to proceed.',
        );
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            errorMessage: 'Location permission was denied. Active GPS location is mandatory for all users to record duty reached.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          errorMessage: 'Location permission is permanently denied. Please enable location access in your device app settings.',
        );
      }

      // 3. Retrieve high-accuracy GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final latStr = lat >= 0 ? '${lat.toStringAsFixed(5)}° N' : '${(-lat).toStringAsFixed(5)}° S';
      final lngStr = lng >= 0 ? '${lng.toStringAsFixed(5)}° E' : '${(-lng).toStringAsFixed(5)}° W';
      final locationString = '$latStr, $lngStr';
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      return LocationResult(
        success: true,
        latitude: lat,
        longitude: lng,
        locationString: locationString,
        mapsUrl: mapsUrl,
      );
    } catch (e) {
      log('Location capture failed: $e');
      return LocationResult(
        success: false,
        errorMessage: 'Unable to acquire GPS location ($e). Location is mandatory to record duty attendance.',
      );
    }
  }

  /// Open Google Maps URL in external maps app or browser.
  ///
  /// Optionally pass raw [latitude] and [longitude] so we can build a `geo:`
  /// intent URI, which is the most reliable way to open native map apps on
  /// Android devices.
  static Future<bool> openMapLocation(
    String mapsUrl, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      // 0. If we have raw coords, try the geo: URI first (opens native map picker on Android)
      if (latitude != null && longitude != null) {
        try {
          final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
          final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        } catch (e) {
          log('Geo URI launch error: $e');
        }
      }

      final uri = Uri.parse(mapsUrl);

      // 1. Try launching directly in external application (Google Maps App)
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (e) {
        log('External application launch error: $e');
      }

      // 2. Fallback to platform default browser / viewer
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) return true;
      } catch (e) {
        log('Platform default launch error: $e');
      }

      // 3. Last fallback: In-app browser
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
      return false;
    } catch (e) {
      log('Open map error: $e');
      return false;
    }
  }
}
