import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';
import 'shareholder_search_overlay.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String currentDate;
  final List<ShareholderModel> searchResults;
  final Function(String) onSearch;
  final Function(ShareholderModel?) onResultTap;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.currentDate,
    required this.searchResults,
    required this.onSearch,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentDate,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SizedBox(
      width: 400,
      child: ShareholderSearchOverlay(
        hint: 'Search shareholders by name or email...',
        results: searchResults,
        navigateToDetail: true,
        onSearch: onSearch,
        onSelected: (shareholder) {
          if (shareholder != null) {
            onResultTap(shareholder);
          }
        },
      ),
    );
  }
}
