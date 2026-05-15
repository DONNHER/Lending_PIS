import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lending_models/activity_log.dart';

class ActivityLogDetailsPage extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogDetailsPage({super.key, required this.log});

  static const Color darkBrown = Color(0xFF3A2318);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
          label: const Text("Back to List", style: TextStyle(color: Colors.grey)),
        ),
        title: Text("Activity Log Details: ID ${log.logId}", 
            style: const TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildMainDetailsCard(),
            const SizedBox(height: 24),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _logTile("Log ID", log.logId),
                    _logTile("Created At", DateFormat('MMMM dd, yyyy, hh:mm a').format(log.createdAt)),
                    _logTile("Action Type", log.actionType),
                    _logTile("IP Address", log.ipAddress),
                    _logTile("Processed By", log.processedBy),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _logTile("Subject User ID", log.subjectUserId),
                    _logTile("Subject User Name", log.subjectUserName),
                    _logTile("Affected User ID", log.subjectUserId),
                    _logTile("Affected User Name", log.subjectUserName),
                    _buildAffectedSystems(),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48),
          // Full Description Section
          const Text("Full Description", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(log.fullDescription, 
            style: const TextStyle(height: 1.5, color: darkBrown, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _logTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: darkBrown))),
        ],
      ),
    );
  }

  Widget _buildAffectedSystems() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: Text("Affected Systems", style: TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: log.affectedSystems.map((system) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(system, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Row(
      children: [
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text("Download PDF"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.email_outlined, size: 18),
          label: const Text("Email to Admin"),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.flag, size: 18),
          label: const Text("Flag as anomalous"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }
}