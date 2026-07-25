import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/user_model.dart';

class UserTable extends StatefulWidget {
  final List<UserModel> users;
  final Function(UserModel) onView;
  final Function(UserModel)? onImpersonate;
  final Function(List<UserModel>)? onDelete;
  final bool isLoading;

  const UserTable({
    super.key,
    required this.users,
    required this.onView,
    this.onImpersonate,
    this.onDelete,
    this.isLoading = false,
  });

  @override
  State<UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  final Set<String> _selectedIds = {};

  bool get isAllSelected =>
      widget.users.isNotEmpty &&
          _selectedIds.length == widget.users.length;

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.clear();
        for (final user in widget.users) {
          _selectedIds.add(user.id);
        }
      } else {
        _selectedIds.clear();
      }
    });
  }

  void toggleSelect(UserModel user, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(user.id);
      } else {
        _selectedIds.remove(user.id);
      }
    });
  }

  Future<void> confirmDelete(BuildContext context) async {
    final selectedUsers = widget.users
        .where((u) => _selectedIds.contains(u.id))
        .toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text(
            "Are you sure you want to move ${selectedUsers.length} selected user(s) to trash?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              label: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      widget.onDelete?.call(selectedUsers);
      setState(() {
        _selectedIds.clear();
      });
    }
  }

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
          child: Row(
            children: [
              // Checkbox + Header Delete count text (Actions column left untouched)
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: toggleSelectAll,
                      side: const BorderSide(color: Colors.white),
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.white.withOpacity(0.2),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      InkWell(
                        onTap: () => confirmDelete(context),
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Delete (${_selectedIds.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Select All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const Expanded(
                flex: 3,
                child: Text('Full Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const Expanded(
                flex: 3,
                child: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const Expanded(
                flex: 2,
                child: Text('Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const Expanded(
                flex: 2,
                child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: widget.users.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No users found', style: TextStyle(color: AppTheme.textMuted)),
            ),
          )
              : ListView.separated(
            itemCount: widget.users.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (context, index) {
              final user = widget.users[index];
              return _buildRow(context, user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, UserModel user) {
    return InkWell(
      onTap: () {
        if (_selectedIds.isEmpty) {
          widget.onView(user);
        }
      },
      hoverColor: const Color(0xFFC06C4D).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Checkbox(
                  value: _selectedIds.contains(user.id),
                  onChanged: (value) => toggleSelect(user, value),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(user.email, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.role.name.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusChip(user.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onImpersonate != null && user.role != UserRole.admin)
                    IconButton(
                      icon: Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: user.status == UserStatus.active ? const Color(0xFFC06C4D) : Colors.grey.withOpacity(0.5),
                      ),
                      onPressed: user.status == UserStatus.active
                          ? () => widget.onImpersonate!(user)
                          : () {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.hideCurrentSnackBar();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Cannot impersonate ${user.status.name} accounts. Please activate the user first.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                      tooltip: user.status == UserStatus.active ? 'Impersonate' : 'Cannot impersonate ${user.status.name} user',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    Color color;
    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        break;
      case UserStatus.inactive:
        color = Colors.orange;
        break;
      case UserStatus.suspended:
        color = Colors.red;
        break;
      case UserStatus.pending:
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}