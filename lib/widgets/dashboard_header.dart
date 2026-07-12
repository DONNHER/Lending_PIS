import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';

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
      child: Column(
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
          const SizedBox(height: 24),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search shareholders by name or email...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFC06C4D)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC06C4D), width: 2),
            ),
          ),
        ),
        if (searchResults.isNotEmpty)
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFC06C4D).withOpacity(0.1),
                      child: Text(
                        result.firstName.isNotEmpty ? result.firstName[0] : '?',
                        style: const TextStyle(
                          color: Color(0xFFC06C4D),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      result.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      result.email,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    onTap: () => onResultTap(result),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
