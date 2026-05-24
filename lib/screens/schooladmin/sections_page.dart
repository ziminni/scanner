import 'package:flutter/material.dart';

import '../../shared/widgets/crud_page.dart';

class SectionsPage extends StatelessWidget {
  const SectionsPage({super.key});

  @override
  Widget build(BuildContext context) => const CrudPage(
    title: 'Sections',
    collection: 'sections',
    fields: ['name', 'gradeLevel', 'adviser', 'status'],
  );
}
