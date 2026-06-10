import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';

class ShareholderTable extends StatelessWidget {
  final List<ShareholderModel> shareholders;
  final Function(ShareholderModel) onView;

  const ShareholderTable({
    super.key,
    required this.shareholders,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFC06C4D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 4, child: Text('Full Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Share Capital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Account Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: shareholders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No records found', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : ListView.separated(
                  itemCount: shareholders.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    return _buildRow(shareholders[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(ShareholderModel shareholder) {
    final currencyFormat = NumberFormat('#,##0.00');
    
    // Display Shareholder ID if it exists, otherwise fallback to User ID
    final displayId = shareholder.id.isNotEmpty 
        ? (shareholder.id.length > 7 ? '${shareholder.id.substring(0, 7)}...' : shareholder.id)
        : (shareholder.userId.length > 7 ? '${shareholder.userId.substring(0, 7)}...' : shareholder.userId);

    return InkWell(
      onTap: () => onView(shareholder),
      hoverColor: const Color(0xFF32211A).withOpacity(0.01),
      splashColor: const Color(0xFFC06C4D).withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            // ID
            Expanded(
              flex: 2,
              child: Text(
                displayId,
                style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
              ),
            ),

            // Full Name
            Expanded(
              flex: 4,
              child: Text(
                shareholder.fullName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
            ),

            // Contact
            Expanded(
              flex: 3,
              child: Text(
                shareholder.contactNumber,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              ),
            ),

            // Share Capital
            Expanded(
              flex: 3,
              child: Text(
                '₱${currencyFormat.format(shareholder.totalShareCapital)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
            ),

            // 🚀 Account Status Column (Pulled from User Status via Model)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: shareholder.status.toLowerCase() == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shareholder.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: shareholder.status.toLowerCase() == 'active' ? Colors.green : Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Actions
            const Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
