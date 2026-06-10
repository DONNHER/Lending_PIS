import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';

class UserTable extends StatelessWidget {
  final List<ShareholderModel> users;
  final Function(ShareholderModel) onView;

  const UserTable({
    super.key,
    required this.users,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFC06C4D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 4, child: Text('Full Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 4, child: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: users.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No user records found', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              : ListView.separated(
                  itemCount: users.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    return _buildRow(users[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRow(ShareholderModel user) {
    final displayId = user.userId.length > 7
        ? user.userId.substring(0, 7)
        : user.userId;

    return InkWell(
      onTap: () => onView(user),
      hoverColor: const Color(0xFF32211A).withOpacity(0.01),
      splashColor: const Color(0xFFC06C4D).withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(displayId, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
            Expanded(
              flex: 4,
              child: Text(
                user.fullName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.status.toLowerCase() == 'active' 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.status,
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: user.status.toLowerCase() == 'active' ? Colors.green : Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
