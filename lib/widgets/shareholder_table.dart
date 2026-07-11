import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';

class ShareholderTable extends StatelessWidget {
  final List<ShareholderModel> shareholders;
  final Function(ShareholderModel) onView;
  final bool isLoading;

  const ShareholderTable({
    super.key,
    required this.shareholders,
    required this.onView,
    this.isLoading = false,
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
              Expanded(flex: 3, child: Text('Full Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 3, child: Text('Email Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Share Capital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 2, child: Text('Credit Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D)))
            : shareholders.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No shareholders found', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : ListView.separated(
                  itemCount: shareholders.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final person = shareholders[index];
                    return InkWell(
                      onTap: () => onView(person),
                      child: _buildRow(person),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(ShareholderModel person) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    person.firstName[0],
                    style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    person.fullName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(person.email, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text(person.phone ?? 'N/A', style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(flex: 2, child: Text('₱${currencyFormat.format(person.shareCapital)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark))),
          
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                const SizedBox(width: 4),
                Text(
                  person.creditScore.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ],
            ),
          ),

          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
