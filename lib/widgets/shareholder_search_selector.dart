import 'package:flutter/material.dart';
import 'shareholder_search_overlay.dart';
import '../models/shareholder_model.dart';

/// Same behavior as [ShareholderSearchOverlay]: results float in an [Overlay]
/// so the list does not push surrounding form content.
class ShareholderSearchSelector extends StatelessWidget {
  final String hint;
  final List<ShareholderModel> results;
  final Function(String) onSearch;
  final Function(ShareholderModel?)? onSelected;
  final Widget? selectedItem;
  final bool navigateToDetail;
  final String? initialValue;

  const ShareholderSearchSelector({
    super.key,
    required this.hint,
    required this.results,
    required this.onSearch,
    this.onSelected,
    this.selectedItem,
    this.navigateToDetail = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return ShareholderSearchOverlay(
      hint: hint,
      results: results,
      onSearch: onSearch,
      onSelected: onSelected,
      selectedItem: selectedItem,
      navigateToDetail: navigateToDetail,
      initialValue: initialValue,
    );
  }
}
