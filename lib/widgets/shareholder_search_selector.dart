import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';
import 'shareholder_search_overlay.dart';

class ShareholderSearchSelector extends StatelessWidget {
  final String hint;
  final List<ShareholderModel> results;
  final Function(String) onSearch;
  final Function(ShareholderModel?) onSelected;
  final bool navigateToDetail;
  final String? initialValue;
  final Widget? selectedItem;

  const ShareholderSearchSelector({
    super.key,
    required this.hint,
    required this.results,
    required this.onSearch,
    required this.onSelected,
    this.navigateToDetail = false,
    this.initialValue,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedItem != null) selectedItem!,
        ShareholderSearchOverlay(
          hint: hint,
          results: results,
          initialValue: initialValue,
          navigateToDetail: navigateToDetail,
          onSearch: onSearch,
          onSelected: (shareholder) {
            onSelected(shareholder);
            if (shareholder == null) {
              onSearch('');
            }
          },
        ),
      ],
    );
  }
}
