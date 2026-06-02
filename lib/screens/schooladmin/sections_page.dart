import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import 'viewmodels/crud_viewmodel.dart';

part 'widgets/add_section_dialog.dart';
part 'widgets/edit_section_dialog.dart';
part 'widgets/sections_by_grade.dart';
part 'widgets/section_card.dart';
part 'widgets/section_details_dialog.dart';
part 'widgets/detail_metric.dart';
part 'widgets/card_line.dart';
part 'widgets/adviser_dropdown.dart';

class SectionsPage extends StatefulWidget {
  const SectionsPage({super.key});

  static const _fields = ['name', 'gradeLevel', 'adviser', 'status'];

  @override
  State<SectionsPage> createState() => _SectionsPageState();
}

class _SectionsPageState extends State<SectionsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Sections',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add section'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _AddSectionDialog(),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search section, grade, or adviser',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          _SectionsByGrade(search: _search.text),
        ],
      ),
    );
  }
}
