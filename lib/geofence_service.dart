import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class GeofenceService {
  double? geofenceLatitude;
  double? geofenceLongitude;
  double? radius;
  bool isWithinGeofence = false;
  DateTime? lastEntryTime;
  final int minimumDurationThreshold = 5; // seconds threshold for quick in-and-out
  StreamSubscription<Position>? positionStream;
  final CollectionReference logCollection = FirebaseFirestore.instance.collection('geofence_logs');
  bool notificationsEnabled = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  GeofenceService() {
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
  }

  Future<void> loadGeofence() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    geofenceLatitude = prefs.getDouble('geofenceLatitude');
    geofenceLongitude = prefs.getDouble('geofenceLongitude');
    radius = prefs.getDouble('radius');
  }

  Future<void> saveGeofence(double latitude, double longitude, double radius) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('geofenceLatitude', latitude);
    await prefs.setDouble('geofenceLongitude', longitude);
    await prefs.setDouble('radius', radius);
    geofenceLatitude = latitude;
    geofenceLongitude = longitude;
    this.radius = radius;
  }

  void startTracking() {
    if (geofenceLatitude == null || geofenceLongitude == null || radius == null) return;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofenceLatitude!,
        geofenceLongitude!,
      );

      if (distance <= radius! && !isWithinGeofence) {
        isWithinGeofence = true;
        lastEntryTime = DateTime.now();
        logEvent("entry");
      } else if (distance > radius! && isWithinGeofence) {
        DateTime exitTime = DateTime.now();
        Duration durationInside = exitTime.difference(lastEntryTime!);

        if (durationInside.inSeconds >= minimumDurationThreshold) {
          isWithinGeofence = false;
          logEvent("exit", durationInside);
        }
      }
    });
  }

  void logEvent(String type, [Duration? durationInside]) {
    DateTime timestamp = DateTime.now();
    String formattedTimestamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(timestamp);
    Map<String, dynamic> data = {
      'type': type,
      'timestamp': formattedTimestamp,
    };

    if (type == "exit" && durationInside != null) {
      data['duration'] = durationInside.inSeconds;
    }

    logCollection.add(data);

    if (notificationsEnabled) {
      _sendNotification(type, formattedTimestamp);
    }
  }

  Future<void> _sendNotification(String type, String formattedTimestamp) async {
    final androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Geofence $type',
      'Logged at $formattedTimestamp',
      notificationDetails,
    );
  }

  Future<void> exportDataToCSV() async {
    final snapshot = await logCollection.get();
    List<List<dynamic>> rows = [
      ["Type", "Timestamp", "Duration (seconds)"],
    ];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      rows.add([
        data['type'],
        data['timestamp'],
        data['duration'] ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/geofence_logs.csv";
    final file = File(path);
    await file.writeAsString(csvData);
  }

  Future<void> exportDataToExcel() async {
    final snapshot = await logCollection.get();
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['GeofenceLogs'];

    sheetObject.appendRow(["Type", "Timestamp", "Duration (seconds)"]);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheetObject.appendRow([
        data['type'],
        data['timestamp'],
        data['duration'] ?? '',
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/geofence_logs.xlsx";
    final file = File(path);
    file.writeAsBytesSync(excel.encode()!);
  }

  void stopTracking() {
    positionStream?.cancel();
  }
}
