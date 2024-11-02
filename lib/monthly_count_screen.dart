import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthlyCountScreen extends StatelessWidget {
  const MonthlyCountScreen({super.key});

  void _logError(String message) {
    // You can replace this with a more sophisticated logging system if needed
    debugPrint(message); // Uses Flutter's debugPrint, which is safe for production
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Entry Count')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('geofence_logs')
            .where('type', isEqualTo: 'entry') // Only count entries
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Create a map to store unique days for each month
          Map<String, Set<int>> daysPerMonth = {};

          for (var log in snapshot.data!.docs) {
            try {
              // Parse timestamp and extract year, month, and day
              DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
              String monthKey = DateFormat('yyyy-MM').format(timestamp);
              int day = timestamp.day;

              // Group days by month key (yyyy-MM)
              daysPerMonth.putIfAbsent(monthKey, () => <int>{}).add(day);
            } catch (e) {
              // Error handling if a document is missing fields
              _logError('Error processing log: $e');
            }
          }

          // Display monthly counts of unique entry days
          return ListView(
            children: daysPerMonth.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: Text('Days in zone: ${entry.value.length}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
