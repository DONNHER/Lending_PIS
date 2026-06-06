import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'shareholder_search_selector.dart';
import '../models/shareholder_model.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String currentDate;
  final List<ShareholderModel> searchResults;
  final Function(String) onSearch;
  final Function(ShareholderModel?)? onResultTap;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.currentDate,
    required this.searchResults,
    required this.onSearch,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Expanded so it takes remaining space, never overflows
              Expanded(
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ cuts off if still too long
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12), // ✅ gap between text and search
              // ✅ Constrain search box to at most 260px, not a hard 300
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: ShareholderSearchSelector(
                  hint: 'Search members...',
                  results: searchResults,
                  onSearch: onSearch,
                  onSelected: onResultTap,
                  navigateToDetail: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentDate,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
