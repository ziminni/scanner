import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import 'viewmodels/create_school_year_viewmodel.dart';
import 'viewmodels/school_year_viewmodel.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/school_year_card.dart';
part 'widgets/school_year_meta.dart';
part 'widgets/school_year_details.dart';
part 'widgets/status_pill.dart';
part 'widgets/yellow_badge.dart';
part 'widgets/term_chip.dart';
part 'widgets/card_list_skeleton.dart';
part 'widgets/school_year_box.dart';

part 'widgets/create_school_year_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status enum derived from Firestore fields
// ─────────────────────────────────────────────────────────────────────────────

enum _SYStatus { active, completed, inactive }

extension _SYStatusX on SchoolYear {
  _SYStatus get displayStatus {
    if (isActive && !archived) return _SYStatus.active;
    if (archived) return _SYStatus.completed;
    return _SYStatus.inactive;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SchoolYearPage extends StatefulWidget {
  const SchoolYearPage({super.key});

  @override
  State<SchoolYearPage> createState() => _SchoolYearPageState();
}

class _SchoolYearPageState extends State<SchoolYearPage> {
  late final SchoolYearViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = SchoolYearViewModel(SchoolAdminViewModelScope.of(context).app);
    _viewModelReady = true;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AdminPage(
          title: 'School Year',
          actions: [
            FutureBuilder<SchoolYear?>(
              future: _viewModel.activeSchoolYear(),
              builder: (context, snapshot) {
                // Only show the Create button when there is no active year
                if (snapshot.data != null) return const SizedBox.shrink();
                return FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create school year'),
                  onPressed: () async {
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (_) => const CreateSchoolYearDialog(),
                    );
                    if (created == true && mounted) setState(() {});
                  },
                );
              },
            ),
          ],
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository
                .rootCollection('school_years')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _CardListSkeleton();
              }

              final schoolYears =
                  (snapshot.data?.docs ?? []).map(SchoolYear.fromDoc).toList()
                    ..sort(_sortDescending);

              if (schoolYears.isEmpty) {
                return const EmptyState(
                  title: 'No school years yet',
                  subtitle:
                      'Create a school year to start tracking attendance.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schoolYears.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sy = schoolYears[index];
                  return _SchoolYearCard(
                    schoolYear: sy,
                    onArchive: sy.isActive
                        ? () async {
                            await _viewModel.archiveActive(sy);
                            if (mounted) setState(() {});
                          }
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  static int _sortDescending(SchoolYear a, SchoolYear b) {
    if (a.isActive && !b.isActive) return -1;
    if (!a.isActive && b.isActive) return 1;
    final aEnd = a.finalTermEnd ?? DateTime(0);
    final bEnd = b.finalTermEnd ?? DateTime(0);
    final cmp = bEnd.compareTo(aEnd);
    if (cmp != 0) return cmp;
    return b.name.compareTo(a.name);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic accordion card — active, completed, or inactive
// ─────────────────────────────────────────────────────────────────────────────

class _SYCounts {
  const _SYCounts({required this.enrollments, required this.sections});

  final int enrollments;
  final int sections;

  static Future<_SYCounts> load(AppController app, String schoolYearId) async {
    final results = await Future.wait([
      app.repository
          .schoolYearCollection(schoolYearId, 'students')
          .where('archived', isEqualTo: false)
          .count()
          .get(),
      app.repository
          .rootCollection('sections')
          .where('archived', isEqualTo: false)
          .count()
          .get(),
    ]);
    return _SYCounts(
      enrollments: results[0].count ?? 0,
      sections: results[1].count ?? 0,
    );
  }
}
