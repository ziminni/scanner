import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';

part 'widgets/add_user_dialog.dart';
part 'widgets/users_table.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'User Management',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add user'),
          onPressed: () async {
            final created = await showDialog<bool>(
              context: context,
              builder: (_) => const _AddUserDialog(),
            );
            if (created == true && mounted) {
              setState(() => _message = 'User account created.');
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Administrator can create one School Administrator and up to five Staff Scanner accounts.',
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
          const SizedBox(height: 16),
          const _UsersTable(),
        ],
      ),
    );
  }
}
