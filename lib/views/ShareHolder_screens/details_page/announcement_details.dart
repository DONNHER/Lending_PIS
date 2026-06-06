import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final String title;
  final String content;
  final DateTime date;

  const AnnouncementDetailsScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Announcement", 
          style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "IMPORTANT",
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(date),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF0F1F5)),
            const SizedBox(height: 24),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            // Placeholder for an image or additional info if needed
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "For further inquiries, please contact the cooperative office.",
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
