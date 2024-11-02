import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'geofence_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GeofenceService _geofenceService = GeofenceService();

  @override
  void initState() {
    super.initState();
    _initializeGeofence();
  }

  Future<void> _initializeGeofence() async {
    await _geofenceService.loadGeofence();
    if (mounted) {
      _checkGeofenceSet();
    }
  }

  void _checkGeofenceSet() {
    if (_geofenceService.geofenceLatitude == null || _geofenceService.geofenceLongitude == null) {
      _promptSetGeofence();
    } else {
      _geofenceService.startTracking();
    }
  }

  void _promptSetGeofence() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _exportToCSV() async {
    await _geofenceService.exportDataToCSV();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported to CSV successfully!')),
      );
    }
  }

  Future<void> _exportToExcel() async {
    await _geofenceService.exportDataToExcel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported to Excel successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user?.email ?? 'User'}!'),
            const SizedBox(height: 20),
            const Text('Geofencing is active. Entry and exit times will be logged.'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _exportToCSV,
              child: const Text('Export to CSV'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _exportToExcel,
              child: const Text('Export to Excel'),
            ),
          ],
        ),
      ),
    );
  }
}
