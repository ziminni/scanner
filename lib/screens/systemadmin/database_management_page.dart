import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin.dart';

class DatabaseManagementPage extends StatelessWidget {
  const DatabaseManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AdminPage(
      title: 'Database Management',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.backup_outlined),
          label: const Text('Backup database'),
          onPressed: () => app.admin.backupDatabase(app.currentUser!),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup records'),
          SizedBox(height: 12),
          CollectionTable(
            collection: 'backups',
            columns: ['createdByName', 'status', 'counts'],
          ),
        ],
      ),
    );
  }
}
