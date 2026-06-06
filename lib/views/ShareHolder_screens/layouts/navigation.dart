import 'package:flutter/material.dart';

class CustomNavigation extends StatelessWidget {
  const CustomNavigation({super.key});

  // Theme Colors from your design
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color mutedBrown = Color(0xFF8B7365);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       // 1. Top Section: Title and Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lending System',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  letterSpacing: -0.5,
                ),
              ),
              
              // New Search Bar 
              SizedBox(
                width: 280, // Adjust width to fit your layout
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: mutedBrown, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: mutedBrown, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF2EAE4), // Slightly darker cream for contrast
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none, // Clean look without harsh borders
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Navigation Tabs Section
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderLine, width: 1.5),
            ),
          ),
          child: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            
            // Indicator Styling (The terracotta underline)
            indicatorColor: terracotta,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            
            // Text Styling
            labelColor: darkBrown,
            unselectedLabelColor: mutedBrown,
            dividerColor: Colors.transparent, // Hide default divider
            labelPadding: EdgeInsets.symmetric(horizontal: 20),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
            
            // Tab Labels
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'User Management'),
              Tab(text: 'Transaction Management'),
              Tab(text: 'Loan Request Management'),
              Tab(text: 'Fund Management'),
              Tab(text: 'Activity Logs'),
            ],
          ),
        ),
      ],
    );
  }
}