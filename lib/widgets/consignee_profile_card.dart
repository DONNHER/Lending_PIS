import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';

/// Displays consignee's full profile information
/// Shows avatar, contact details, and document status
class ConsigneeProfileCard extends StatelessWidget {
  final ConsigneeModel consignee;

  const ConsigneeProfileCard({super.key, required this.consignee});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar and basic info ──────────────────────────────
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consignee.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone_rounded, consignee.phone),
                    const SizedBox(height: 3),
                    _infoRow(Icons.location_on_rounded, consignee.address),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Stats row ──────────────────────────────────────────
          Row(
            children: [
              _statBox(
                label: 'Consignments',
                value: '...', // Will be populated by parent
                icon: Icons.inventory_2_rounded,
                color: AppTheme.secondary,
              ),
              _vDivider(),
              _statBox(
                label: 'Total Stock',
                value: '...',
                icon: Icons.storage_rounded,
                color: AppTheme.success,
              ),
              _vDivider(),
              _statBox(
                label: 'Active',
                value: '...',
                icon: Icons.check_circle_rounded,
                color: AppTheme.primary,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Document status ────────────────────────────────────
          Row(
            children: [
              _documentStatus(
                label: 'Health Card',
                hasDocument: consignee.healthCardUrl != null,
                onView: consignee.healthCardUrl != null
                    ? () => _viewDocument(context, consignee.healthCardUrl!, 'Health Card')
                    : null,
              ),
              const SizedBox(width: 12),
              _documentStatus(
                label: 'Food Handler Card',
                hasDocument: consignee.foodHandlerCardUrl != null,
                onView: consignee.foodHandlerCardUrl != null
                    ? () => _viewDocument(context, consignee.foodHandlerCardUrl!, 'Food Handler Card')
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Avatar with initials
  Widget _buildAvatar() {
    final initials = consignee.fullName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.secondary.withOpacity(0.15),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondary,
        ),
      ),
    );
  }

  // Icon + text row
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Stat box
  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // Vertical divider
  Widget _vDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.primary.withOpacity(0.1),
    );
  }

  // Document status chip with view option
  Widget _documentStatus({
    required String label,
    required bool hasDocument,
    VoidCallback? onView,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasDocument
              ? AppTheme.success.withOpacity(0.05)
              : AppTheme.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDocument
                ? AppTheme.success.withOpacity(0.2)
                : AppTheme.error.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasDocument
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasDocument ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: hasDocument ? AppTheme.success : AppTheme.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDocument ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                  if (hasDocument)
                    GestureDetector(
                      onTap: onView,
                      child: const Text(
                        'Tap to view',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
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

  // View document in full screen
  void _viewDocument(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text('Failed to load image', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}