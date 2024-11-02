import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key}); // No change needed here as it's already using super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Logs'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('geofence_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logs available.'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index];
              DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
              String formattedTimestamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(timestamp);
              String type = log['type'];

              return ListTile(
                title: Text('Type: $type'),
                subtitle: Text('Timestamp: $formattedTimestamp'),
              );
            },
          );
        },
      ),
    );
  }
}
