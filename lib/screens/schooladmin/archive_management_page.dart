import 'package:flutter/material.dart';

import '../../shared/widgets/admin_widgets.dart';

class SchoolArchiveManagementPage extends StatelessWidget {
  const SchoolArchiveManagementPage({super.key});

  @override
  Widget build(BuildContext context) => const AdminPage(
    title: 'Archives',
    child: CollectionTable(
      collection: 'archives',
      columns: ['type', 'title', 'schoolYear', 'createdAt'],
    ),
  );
}
