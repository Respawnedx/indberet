import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  LatLng selectedLocation = LatLng(55.6761, 12.5683); // Default location (Copenhagen)
  final MapController mapController = MapController();

  void _onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;
    });
  }

  void _saveLocation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialLatitude: selectedLocation.latitude,
          initialLongitude: selectedLocation.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Geofence Location')),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: selectedLocation,
          zoom: 12.0,
          onTap: (tapPosition, point) => _onMapTap(point), // Corrected to use LatLng `point`
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                builder: (ctx) => const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveLocation,
        child: const Icon(Icons.check),
      ),
    );
  }
}
