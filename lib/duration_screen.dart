import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DurationScreen extends StatelessWidget {
  const DurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Spent in Zone')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('geofence_logs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var log = snapshot.data!.docs[index];
              DateTime entryTime = (log['entryTime'] as Timestamp).toDate();
              DateTime exitTime = (log['exitTime'] as Timestamp).toDate();
              int duration = (log['duration'] as num).toInt(); // Cast duration to int if stored as num

              return ListTile(
                title: Text('Entry: $entryTime - Exit: $exitTime'),
                subtitle: Text('Duration: $duration minutes'),
              );
            },
          );
        },
      ),
    );
  }
}
