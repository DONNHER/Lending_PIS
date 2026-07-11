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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFC06C4D),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
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
            hintText: 'Search shareholders...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                return ListTile(
                  title: Text(result.fullName),
                  subtitle: Text(result.id),
                  onTap: () => onResultTap(result),
                );
              },
            ),
          ),
      ],
    );
  }
}
