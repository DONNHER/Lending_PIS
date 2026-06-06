import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../views/shareholder_detail_page.dart';
import '../models/shareholder_model.dart';

class ShareholderSearchBar extends StatefulWidget {
  final String hint;
  final List<ShareholderModel> results;
  final Function(String) onSearch;
  final Function(ShareholderModel)? onSelected;
  final Widget? selectedItem;
  final bool navigateToDetail;

  const ShareholderSearchBar({
    super.key,
    required this.hint,
    required this.results,
    required this.onSearch,
    this.onSelected,
    this.selectedItem,
    this.navigateToDetail = true,
  });

  @override
  State<ShareholderSearchBar> createState() => _ShareholderSearchBarState();
}

class _ShareholderSearchBarState extends State<ShareholderSearchBar> {
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchAnchor(
          searchController: _searchController,
          builder: (context, controller) {
            return TextField(
              controller: controller,
              onChanged: (value) {
                widget.onSearch(value);
                if (!controller.isOpen) controller.openView();
              },
              onTap: () {
                if (!controller.isOpen) controller.openView();
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFC06C4D)),
                ),
              ),
            );
          },
          suggestionsBuilder: (context, controller) {
            if (widget.results.isEmpty) {
              return [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("No shareholders found", style: TextStyle(color: AppTheme.textMuted))),
                )
              ];
            }

            return widget.results.map((item) {
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      item.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Capital: ₱${NumberFormat('#,##0').format(item.totalShareCapital)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Icon(
                      widget.navigateToDetail ? Icons.chevron_right : Icons.add_circle_outline,
                      size: 20,
                      color: const Color(0xFFC06C4D),
                    ),
                    onTap: () {
                      if (widget.onSelected != null) {
                        widget.onSelected!(item);
                      }

                      if (widget.navigateToDetail) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShareholderDetailPage(shareholderId: item.id),
                          ),
                        );
                      }

                      // Close the overlay and clear
                      controller.closeView(null);
                      widget.onSearch('');
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList();
          },
          viewBackgroundColor: Colors.white,
          viewElevation: 4,
          viewConstraints: const BoxConstraints(maxHeight: 300),
        ),
        if (widget.selectedItem != null) ...[
          const SizedBox(height: 12),
          widget.selectedItem!,
        ],
      ],
    );
  }
}
