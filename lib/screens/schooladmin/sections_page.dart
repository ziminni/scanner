import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_controller.dart';
import '../../core/utils/download_file.dart';
import '../../core/utils/section_qr_worker_client.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/gender_dropdown_field.dart';
import 'viewmodels/crud_viewmodel.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/add_section_dialog.dart';
part 'widgets/edit_section_dialog.dart';
part 'widgets/sections_by_grade.dart';
part 'widgets/grade_tab.dart';
part 'widgets/sections_table_header.dart';
part 'widgets/section_toolbar.dart';
part 'widgets/section_card.dart';
part 'widgets/section_details_dialog.dart';
part 'widgets/section_qr_exporter.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage sections by grade level',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Open a section to view its students, or use the menu to edit, archive, and download QR IDs.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth < 600
                  ? double.infinity
                  : constraints.maxWidth * .52,
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search section, grade, or adviser',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionsByGrade(search: _search.text),
        ],
      ),
    );
  }
}
