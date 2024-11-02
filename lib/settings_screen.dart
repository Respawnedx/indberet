import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_service.dart';
import 'map_search_screen.dart';

class SettingsScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const SettingsScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GeofenceService _geofenceService = GeofenceService();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  bool notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadGeofenceSettings();
    _loadNotificationSetting();
  }

  Future<void> _loadGeofenceSettings() async {
    await _geofenceService.loadGeofence();
    setState(() {
      _latitudeController.text = widget.initialLatitude?.toString() ?? _geofenceService.geofenceLatitude?.toString() ?? '';
      _longitudeController.text = widget.initialLongitude?.toString() ?? _geofenceService.geofenceLongitude?.toString() ?? '';
      _radiusController.text = _geofenceService.radius?.toString() ?? '';
    });
  }

  Future<void> _loadNotificationSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _saveGeofenceSettings() async {
    double latitude = double.parse(_latitudeController.text);
    double longitude = double.parse(_longitudeController.text);
    double radius = double.parse(_radiusController.text);

    await _geofenceService.saveGeofence(latitude, longitude, radius);
    _geofenceService.startTracking();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = value;
    });
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _openMapScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapSearchScreen(
          onLocationSelected: (latitude, longitude) {
            setState(() {
              _latitudeController.text = latitude.toString();
              _longitudeController.text = longitude.toString();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Geofence')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _radiusController,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openMapScreen,
              child: const Text('Select Location on Map'),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGeofenceSettings,
              child: const Text('Save Geofence'),
            ),
          ],
        ),
      ),
    );
  }
}
