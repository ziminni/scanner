import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/utils/download_file.dart';
import '../../core/utils/section_qr_worker_client.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/gender_dropdown_field.dart';
import 'viewmodels/import_students_viewmodel.dart';
import 'viewmodels/students_viewmodel.dart';
import 'viewmodels/school_admin_viewmodel.dart';

part 'widgets/students_filter_bar.dart';
part 'widgets/unassigned_students_notice.dart';
part 'widgets/students_filter_select.dart';

part 'widgets/add_student_dialog.dart';
part 'widgets/import_students_dialog.dart';
part 'widgets/edit_student_dialog.dart';
part 'widgets/transfer_students_section_dialog.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _search = TextEditingController();
  late StudentsViewModel _viewModel;
  bool _viewModelReady = false;
  String _sectionFilter = '';
  String _studentSortFilter = 'lastNameAsc';
  String _studentGroup = 'regular';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = StudentsViewModel(SchoolAdminViewModelScope.of(context).app);
    _viewModelReady = true;
  }

  @override
  void dispose() {
    _search.dispose();
    if (_viewModelReady) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Students',
      titleTrailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'regular', label: Text('Regular')),
          ButtonSegment(value: 'aral', label: Text('Aral')),
        ],
        selected: {_studentGroup},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          setState(() => _studentGroup = selection.first);
        },
      ),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archives'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const ArchivedRecordsDialog(
              title: 'Archived Students',
              collection: 'students',
              schoolYearScoped: true,
              columns: [
                'lrn',
                'fullName',
                'gender',
                'birthdate',
                'section',
                'archivedAt',
              ],
            ),
          ),
        ),
        MenuAnchor(
          alignmentOffset: const Offset(-27, 0),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.person_add_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _AddStudentDialog(),
              ),
              child: const Text('Add student'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.upload_file_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _ImportStudentsDialog(),
              ),
              child: const Text('Import students'),
            ),
          ],
          builder: (context, controller, child) => FilledButton(
            onPressed: controller.isOpen ? controller.close : controller.open,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add student'),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: SchoolAdminViewModelScope.of(
              context,
            ).repository.activeSectionsStream(),
            builder: (context, snapshot) {
              final sections =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => doc.data()['name'] as String? ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              final sectionOptions = ['Unassigned', ...sections];
              if (_sectionFilter.isNotEmpty &&
                  !sectionOptions.contains(_sectionFilter)) {
                _sectionFilter = '';
              }

              return _StudentsFilterBar(
                search: _search,
                sortFilter: _studentSortFilter,
                sectionFilter: _sectionFilter,
                sections: sectionOptions,
                onSearchChanged: () => setState(() {}),
                onSortFilterChanged: (value) => setState(() {
                  _studentSortFilter = value;
                  if (value != 'section') _sectionFilter = '';
                }),
                onSectionChanged: (value) =>
                    setState(() => _sectionFilter = value),
              );
            },
          ),
          const SizedBox(height: 12),
          _UnassignedStudentsNotice(
            isAral: _studentGroup == 'aral',
            onView: () => setState(() {
              _search.clear();
              _studentSortFilter = 'section';
              _sectionFilter = 'Unassigned';
            }),
          ),
          const SizedBox(height: 12),
          CollectionTable(
            key: ValueKey('students-$_studentGroup'),
            collection: 'students',
            columns: studentTableFields,
            schoolYearScoped: true,
            queryLimit: null,
            confirmArchive: true,
            enableBulkArchive: true,
            showArchiveAction: false,
            bulkSecondaryActionLabel: 'Transfer student/s',
            bulkSecondaryActionIcon: Icons.swap_horiz,
            bulkSecondaryActions: [
              BulkSelectionAction(
                label: _studentGroup == 'regular'
                    ? 'Transfer to Aral'
                    : 'Transfer to Regular',
                icon: Icons.swap_horiz,
                onSelected: _studentGroup == 'regular'
                    ? _transferSelectedToAral
                    : _transferSelectedToRegular,
              ),
              BulkSelectionAction(
                label: 'Transfer section',
                icon: Icons.meeting_room_outlined,
                onSelected: _transferSelectedToSection,
              ),
            ],
            teacherTableStyle: true,
            itemLabel: 'students',
            columnLabels: const {
              'lrn': 'LRN',
              'fullName': 'Name',
              'guardianName': 'Guardian',
              'guardianContact': 'Guardian Contact',
            },
            search: _search.text,
            filters: {
              if (_studentSortFilter == 'section' && _sectionFilter.isNotEmpty)
                'section': _sectionFilter,
              if (_studentSortFilter == 'genderMale') 'gender': 'Male',
              if (_studentSortFilter == 'genderFemale') 'gender': 'Female',
              if (_studentSortFilter == 'blankFields') 'blankFields': 'true',
              'isAral': (_studentGroup == 'aral').toString(),
            },
            sortComparator: _studentComparator,
            onRowTap: (context, _, data, _) => showDialog<void>(
              context: context,
              builder: (_) => RecordDetailsDialog(
                title: 'Student Details',
                data: data,
                columns: studentDetailFields,
              ),
            ),
            onEdit: _openEditStudentDialog,
            onDownload: _downloadStudentQr,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadStudentQr(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  ) async {
    final app = SchoolAdminViewModelScope.of(context).app;
    final messenger = ScaffoldMessenger.of(context);
    final student = Student(
      id: docId,
      lrn: (data['lrn'] as String? ?? docId).trim(),
      lastName: (data['lastName'] as String? ?? '').trim(),
      firstName: (data['firstName'] as String? ?? '').trim(),
      middleName: (data['middleName'] as String? ?? '').trim(),
      gender: data['gender'] as String? ?? '',
      birthdate: switch (data['birthdate']) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
      address: data['address'] as String? ?? '',
      guardianName: data['guardianName'] as String? ?? '',
      guardianContact: data['guardianContact'] as String? ?? '',
      section: data['section'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      isAral: data['isAral'] as bool? ?? false,
    );

    try {
      final schoolYear = await app.attendance.activeSchoolYear();
      if (schoolYear == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Create an active school year first.')),
        );
        return;
      }

      final bytes = await buildSectionQrZipInWorker(
        sectionName: student.section.isEmpty ? 'students' : student.section,
        gradeSection: student.section.isEmpty ? 'Students' : student.section,
        students: [
          SectionQrWorkerStudent(
            lrn: student.lrn,
            lastName: student.lastName,
            firstName: student.firstName,
            middleName: student.middleName,
            isAral: student.isAral,
          ),
        ],
      );

      final fileName = '${_safeStudentFileName(student)}.zip';
      downloadBytes(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
      );

      await app.audit.record(
        action: 'student_qr_downloaded',
        actorId: app.currentUser!.id,
        actorName: app.currentUser!.fullName,
        target: student.fullName,
        metadata: {
          'schoolYear': schoolYear.name,
          'studentId': student.id,
          'studentLrn': student.lrn,
        },
      );

      messenger.showSnackBar(
        SnackBar(content: Text('QR downloaded for ${student.fullName}')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download student QR: $error')),
      );
    }
  }

  String _safeStudentFileName(Student student) {
    final base = student.fullName.trim();
    if (base.isEmpty) return 'student_qr';
    return base
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<bool> _transferSelectedToAral(List<String> studentIds) async {
    return _transferSelectedStudents(
      studentIds: studentIds,
      transferToAral: true,
      destinationName: 'Aral',
      auditAction: 'students_transferred_to_aral',
    );
  }

  int _studentComparator(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aData = a.data();
    final bData = b.data();
    final fallback = _compareStudentNames(aData, bData);
    return switch (_studentSortFilter) {
      'lastNameDesc' => -fallback,
      'firstNameAsc' => _compareText(aData['firstName'], bData['firstName']),
      'birthdateOldest' => _compareBirthdates(
        aData['birthdate'],
        bData['birthdate'],
      ),
      'birthdateNewest' => -_compareBirthdates(
        aData['birthdate'],
        bData['birthdate'],
      ),
      'section' => _compareText(
        aData['section'],
        bData['section'],
      ).nonZeroOr(fallback),
      _ => fallback,
    };
  }

  int _compareStudentNames(Map<String, dynamic> a, Map<String, dynamic> b) {
    return _compareText(
      a['lastName'],
      b['lastName'],
    ).nonZeroOr(_compareText(a['firstName'], b['firstName']));
  }

  int _compareText(Object? a, Object? b) {
    return (a?.toString().trim().toLowerCase() ?? '').compareTo(
      b?.toString().trim().toLowerCase() ?? '',
    );
  }

  int _compareBirthdates(Object? a, Object? b) {
    final aDate = _dateValue(a);
    final bDate = _dateValue(b);
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  DateTime? _dateValue(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime date => date,
      _ => null,
    };
  }

  Future<bool> _transferSelectedToRegular(List<String> studentIds) async {
    return _transferSelectedStudents(
      studentIds: studentIds,
      transferToAral: false,
      destinationName: 'Regular',
      auditAction: 'students_transferred_to_regular',
    );
  }

  Future<bool> _transferSelectedToSection(List<String> studentIds) async {
    if (!mounted) return false;
    try {
      final students = await _viewModel.loadTransferStudents(studentIds);
      if (!mounted) return false;

      final transfer = await showDialog<_TransferSectionResult>(
        context: context,
        builder: (_) => _TransferStudentsSectionDialog(students: students),
      );
      if (transfer == null ||
          transfer.section.trim().isEmpty ||
          transfer.studentIds.isEmpty ||
          !mounted) {
        return false;
      }
      final targetSection = transfer.section.trim();
      final selectedStudentIds = transfer.studentIds;

      await _viewModel.transferStudentsToSection(
        studentIds: selectedStudentIds,
        section: targetSection,
      );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedStudentIds.length} students transferred to $targetSection.',
          ),
        ),
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Section transfer failed: $error')),
        );
      }
      return false;
    }
  }

  Future<bool> _transferSelectedStudents({
    required List<String> studentIds,
    required bool transferToAral,
    required String destinationName,
    required String auditAction,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Transfer selected students to $destinationName?'),
        content: Text(
          'Transfer ${studentIds.length} selected students to $destinationName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.swap_horiz),
            label: Text('Transfer to $destinationName'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    try {
      await _viewModel.transferStudentsAralStatus(
        studentIds: studentIds,
        isAral: transferToAral,
        auditAction: auditAction,
      );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${studentIds.length} students transferred to $destinationName.',
          ),
        ),
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transfer failed: $error')));
      }
      return false;
    }
  }
}
