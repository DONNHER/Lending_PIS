import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/shareholders_viewmodel.dart';

class CustomNavigation extends StatelessWidget {
  const CustomNavigation({super.key});

  static const Color darkBrown = Color(0xFF3A2318);
  static const Color mutedBrown = Color(0xFF8B7365);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Section (Responsive)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 10),
              child: isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lending System',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSearchBar(double.infinity, context),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lending System',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                      _buildSearchBar(280, context),
                    ],
                  ),
            ),

            // 2. Navigation Tabs (Always scrollable for mobile safety)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderLine, width: 1.5)),
              ),
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: terracotta,
                indicatorWeight: 3,
                labelColor: darkBrown,
                unselectedLabelColor: mutedBrown,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.symmetric(horizontal: 16),
                tabs: [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Shareholders'),
                  Tab(text: 'Transactions'),
                  Tab(text: 'Loans'),
                  Tab(text: 'Funds'),
                  Tab(text: 'Logs'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(double width, BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        onChanged: (value) {
          // Use ShareholderViewModel for global shareholder search
          context.read<ShareholderViewModel>().setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Search shareholder...',
          hintStyle: const TextStyle(color: mutedBrown, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: mutedBrown, size: 18),
          filled: true,
          fillColor: const Color(0xFFF2EAE4),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
