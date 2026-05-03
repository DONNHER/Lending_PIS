import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';

// Reusable card widget for displaying a consignee in a list
// Shows avatar, contact info, and document status indicators
class ConsigneeCard extends StatelessWidget {
  final ConsigneeModel consignee;
  final VoidCallback? onTap; 
  final VoidCallback onEdit;     // Called when edit button is tapped
  final VoidCallback onDelete;   // Called when delete button is tapped

  const ConsigneeCard({
    super.key,
    required this.consignee,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar with initials ─────────────────────────────────
            _buildAvatar(),
            const SizedBox(width: 14),
      
            // ── Contact Info ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    consignee.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone with icon
                  _infoRow(Icons.phone_rounded, consignee.phone),
                  const SizedBox(height: 2),
                  // Address with icon
                  _infoRow(Icons.location_on_rounded, consignee.address),
                  const SizedBox(height: 8),
                  // Document status chips
                  Row(
                    children: [
                      _docChip(
                        label: 'Health Card',
                        hasDoc: consignee.healthCardUrl != null,
                      ),
                      const SizedBox(width: 6),
                      _docChip(
                        label: 'Food Handler',
                        hasDoc: consignee.foodHandlerCardUrl != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
      
            // ── Action Buttons ───────────────────────────────────────
            Column(
              children: [
                _actionButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primary,
                  onTap: onEdit,
                ),
                const SizedBox(height: 8),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Circle avatar showing first letters of the name
  Widget _buildAvatar() {
    final initials = consignee.fullName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.secondary.withOpacity(0.15),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondary,
        ),
      ),
    );
  }

  // Row with icon + text (for phone and address)
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  // Chip showing if a document is uploaded or missing
  Widget _docChip({required String label, required bool hasDoc}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasDoc
            ? AppTheme.success.withOpacity(0.1)   // Green if uploaded
            : AppTheme.warning.withOpacity(0.1),  // Yellow if missing
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDoc ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 12,
            color: hasDoc ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: hasDoc ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  // Circular icon button for edit/delete
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }
}