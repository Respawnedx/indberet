import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSearchScreen extends StatefulWidget {
  final Function(double, double) onLocationSelected;

  const MapSearchScreen({super.key, required this.onLocationSelected});

  @override
  MapSearchScreenState createState() => MapSearchScreenState();
}

class MapSearchScreenState extends State<MapSearchScreen> {
  MapController mapController = MapController();
  LatLng _center = LatLng(55.6761, 12.5683); // Default location (Copenhagen)
  Marker? selectedMarker;
  List<dynamic> searchResults = [];

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (!mounted) return; // Check if the widget is still mounted
        setState(() {
          searchResults = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching location data. Please try again.')),
      );
    }
  }

  void _selectLocation(double lat, double lon) {
    setState(() {
      _center = LatLng(lat, lon);
      selectedMarker = Marker(
        point: _center,
        builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
      );
      mapController.move(_center, 14.0);
      searchResults.clear(); // Clear search results after selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by address or place name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) => _searchLocation(query),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: _center,
                zoom: 12.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _center = point;
                    selectedMarker = Marker(
                      point: point,
                      builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    );
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                if (selectedMarker != null) MarkerLayer(markers: [selectedMarker!]),
              ],
            ),
          ),
          if (searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return ListTile(
                    title: Text(result['display_name']),
                    onTap: () {
                      final lat = double.parse(result['lat']);
                      final lon = double.parse(result['lon']);
                      _selectLocation(lat, lon);
                    },
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedMarker != null) {
            widget.onLocationSelected(_center.latitude, _center.longitude);
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a location on the map.')),
            );
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}