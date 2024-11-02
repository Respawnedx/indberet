import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class LocationService {
  final Logger _logger = Logger();

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled; log a message to enable it.
      _logMessage('Location services are disabled.');
      return null;
    }

    // Check location permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied; log a message.
        _logMessage('Location permissions are denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied; log a message.
      _logMessage('Location permissions are permanently denied.');
      return null;
    }

    // Get current position.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _logMessage(String message) {
    _logger.i(message); // Logs information-level messages
  }
}
