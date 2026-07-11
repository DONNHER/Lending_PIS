import 'package:flutter/material.dart';
import '../models/shareholder_model.dart';

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
        TextField(
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (results.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final shareholder = results[index];
                return ListTile(
                  title: Text(shareholder.fullName),
                  subtitle: Text(shareholder.email),
                  onTap: () {
                    onSelected(shareholder);
                    onSearch('');
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
