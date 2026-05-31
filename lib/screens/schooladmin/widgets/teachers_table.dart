part of '../teachers_page.dart';

class _TeachersTable extends StatelessWidget {
  const _TeachersTable({required this.search});

  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return FutureBuilder(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) {
          return const EmptyState(title: 'Create an active school year first');
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: app.repository
              .schoolYearCollection(schoolYear.id, 'teachers')
              .where('archived', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final query = search.trim().toLowerCase();
            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data();
              if (query.isEmpty) return true;
              return '${data['teacherId']} ${_teacherName(data)} ${data['contactNumber']}'
                  .toLowerCase()
                  .contains(query);
            }).toList()..sort(_teacherSort);

            if (docs.isEmpty) {
              return const EmptyState(title: 'No teachers found');
            }

            return DataSurface(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 64,
                  columns: const [
                    DataColumn(label: Text('Teacher ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Birthdate')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Contact')),
                    DataColumn(label: Text('Schedule')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final doc in docs)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(doc.data()['teacherId'] as String? ?? '-'),
                          ),
                          DataCell(Text(_teacherName(doc.data()))),
                          DataCell(Text(_teacherBirthdate(doc.data()))),
                          DataCell(
                            Text(doc.data()['address'] as String? ?? '-'),
                          ),
                          DataCell(
                            Text(doc.data()['contactNumber'] as String? ?? '-'),
                          ),
                          DataCell(Text(_teacherSchedule(doc.data()))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => _EditTeacherDialog(
                                      schoolYearId: schoolYear.id,
                                      docId: doc.id,
                                      data: doc.data(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Archive',
                                  icon: const Icon(Icons.archive_outlined),
                                  onPressed: () async {
                                    final confirmed =
                                        await _confirmArchiveTeacher(
                                          context,
                                          _teacherName(doc.data()),
                                        );
                                    if (!confirmed || !context.mounted) return;
                                    await app.repository
                                        .schoolYearCollection(
                                          schoolYear.id,
                                          'teachers',
                                        )
                                        .doc(doc.id)
                                        .set({
                                          'archived': true,
                                          'archivedAt':
                                              FieldValue.serverTimestamp(),
                                        }, SetOptions(merge: true));
                                    await app.audit.record(
                                      action: 'teachers_archived',
                                      actorId: app.currentUser!.id,
                                      actorName: app.currentUser!.fullName,
                                      target:
                                          doc.data()['teacherId'] as String? ??
                                          doc.id,
                                      metadata: {'schoolYear': schoolYear.name},
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

int _teacherSort(
  QueryDocumentSnapshot<Map<String, dynamic>> a,
  QueryDocumentSnapshot<Map<String, dynamic>> b,
) {
  final lastCompare = (a.data()['lastName'] as String? ?? '').compareTo(
    b.data()['lastName'] as String? ?? '',
  );
  if (lastCompare != 0) return lastCompare;
  return (a.data()['firstName'] as String? ?? '').compareTo(
    b.data()['firstName'] as String? ?? '',
  );
}

String _teacherName(Map<String, dynamic> data) {
  final lastName = data['lastName'] as String? ?? '';
  final firstName = data['firstName'] as String? ?? '';
  final middleName = data['middleName'] as String? ?? '';
  final middleInitial = middleName.trim().isEmpty
      ? ''
      : ' ${middleName.trim()[0]}.';
  final name = '$lastName, $firstName$middleInitial'.trim();
  return name == ',' ? '-' : name;
}

String _teacherSchedule(Map<String, dynamic> data) {
  final timeIn = data['assignedTimeIn'] as String? ?? '-';
  final timeOut = data['assignedTimeOut'] as String? ?? '-';
  return '$timeIn - $timeOut';
}

String _teacherBirthdate(Map<String, dynamic> data) {
  final value = data['birthdate'];
  if (value is Timestamp) {
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }
  if (value is DateTime) return DateFormat('MMM d, yyyy').format(value);
  return '-';
}

Future<bool> _confirmArchiveTeacher(
  BuildContext context,
  String teacherName,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Archive teacher?'),
          content: Text(
            'This will remove $teacherName from the active teachers list. You can still keep the record for archive/history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ??
      false;
}
