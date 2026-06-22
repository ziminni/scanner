part of '../teachers_page.dart';

class _TeachersTable extends StatefulWidget {
  const _TeachersTable({
    required this.search,
    required this.scheduleFilter,
    required this.genderFilter,
  });

  final String search;
  final String scheduleFilter;
  final String genderFilter;

  @override
  State<_TeachersTable> createState() => _TeachersTableState();
}

class _TeachersTableState extends State<_TeachersTable> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  int _currentPage = 0;
  int _itemsPerPage = 10;
  final Set<String> _selectedTeacherIds = {};
  String? _hoveredTeacherId;
  Timer? _hoverResumeTimer;
  bool _hoverPaused = false;

  @override
  void didUpdateWidget(covariant _TeachersTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search ||
        oldWidget.scheduleFilter != widget.scheduleFilter ||
        oldWidget.genderFilter != widget.genderFilter) {
      _currentPage = 0;
      _selectedTeacherIds.clear();
    }
  }

  @override
  void dispose() {
    _hoverResumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
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
            final query = widget.search.trim().toLowerCase();
            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data();
              if (widget.scheduleFilter.isNotEmpty &&
                  _teacherSchedule(data) != widget.scheduleFilter) {
                return false;
              }
              if (widget.genderFilter.isNotEmpty &&
                  (data['gender'] as String? ?? '').toLowerCase() !=
                      widget.genderFilter.toLowerCase()) {
                return false;
              }
              if (query.isEmpty) return true;
              return '${data['teacherId']} ${_teacherName(data)} ${data['contactNumber']}'
                  .toLowerCase()
                  .contains(query);
            }).toList()..sort(_teacherSort);

            if (docs.isEmpty) {
              return const EmptyState(title: 'No teachers found');
            }
            final totalPages = (docs.length / _itemsPerPage).ceil();
            final currentPage = totalPages == 0
                ? 0
                : _currentPage.clamp(0, totalPages - 1).toInt();
            final start = currentPage * _itemsPerPage;
            final end = (start + _itemsPerPage).clamp(0, docs.length).toInt();
            final paginatedDocs = docs.sublist(start, end);
            final selectedDocs = docs
                .where((doc) => _selectedTeacherIds.contains(doc.id))
                .toList();
            final hasSelection = selectedDocs.isNotEmpty;
            return DataSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasSelection) ...[
                    _TeacherBulkArchiveBar(
                      selectedCount: selectedDocs.length,
                      onClear: () => setState(_selectedTeacherIds.clear),
                      onArchive: () => _bulkArchiveTeachers(
                        context,
                        app,
                        schoolYear,
                        selectedDocs,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Listener(
                    onPointerSignal: _pauseHoverForScroll,
                    child: FullWidthHorizontalTable(
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value: selectedDocs.length == docs.length,
                              tristate:
                                  selectedDocs.isNotEmpty &&
                                  selectedDocs.length < docs.length,
                              onChanged: (selected) =>
                                  _setAllSelected(docs, selected == true),
                            ),
                          ),
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('Teacher ID')),
                          const DataColumn(label: Text('Name')),
                          const DataColumn(label: Text('Gender')),
                          const DataColumn(label: Text('Birthdate')),
                          const DataColumn(label: Text('Address')),
                          const DataColumn(label: Text('Contact')),
                          const DataColumn(label: Text('Schedule')),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (
                            var index = 0;
                            index < paginatedDocs.length;
                            index++
                          )
                            DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                final colorScheme = Theme.of(
                                  context,
                                ).colorScheme;
                                if (_hoveredTeacherId ==
                                    paginatedDocs[index].id) {
                                  return colorScheme.primary.withAlpha(20);
                                }
                                if (states.contains(WidgetState.selected)) {
                                  return colorScheme.primary.withAlpha(12);
                                }
                                return null;
                              }),
                              selected: _selectedTeacherIds.contains(
                                paginatedDocs[index].id,
                              ),
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: _selectedTeacherIds.contains(
                                      paginatedDocs[index].id,
                                    ),
                                    onChanged: (selected) =>
                                        _setTeacherSelected(
                                          paginatedDocs[index].id,
                                          selected == true,
                                        ),
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text('${start + index + 1}'),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    paginatedDocs[index].data()['teacherId']
                                            as String? ??
                                        '-',
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    _teacherName(paginatedDocs[index].data()),
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    paginatedDocs[index].data()['gender']
                                            as String? ??
                                        '-',
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    _teacherBirthdate(
                                      paginatedDocs[index].data(),
                                    ),
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  SizedBox(
                                    width: 105,
                                    child: Text(
                                      paginatedDocs[index].data()['address']
                                              as String? ??
                                          '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    paginatedDocs[index].data()['contactNumber']
                                            as String? ??
                                        '-',
                                  ),
                                ),
                                _detailsCell(
                                  context,
                                  paginatedDocs[index].id,
                                  paginatedDocs[index].data(),
                                  Text(
                                    _teacherSchedule(
                                      paginatedDocs[index].data(),
                                    ),
                                  ),
                                ),
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
                                            docId: paginatedDocs[index].id,
                                            data: paginatedDocs[index].data(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminTableFooter(
                    currentPage: currentPage,
                    totalItems: docs.length,
                    itemsPerPage: _itemsPerPage,
                    itemLabel: 'teachers',
                    itemsPerPageOptions: _itemsPerPageOptions,
                    onItemsPerPageChanged: (value) {
                      setState(() {
                        _itemsPerPage = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 8),
                    AdminPaginationControls(
                      currentPage: currentPage,
                      totalPages: totalPages,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTeacherDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder: (_) => RecordDetailsDialog(
        title: 'Teacher Details',
        data: data,
        columns: TeachersPage.fields,
      ),
    );
  }

  DataCell _detailsCell(
    BuildContext context,
    String teacherId,
    Map<String, dynamic> data,
    Widget child,
  ) {
    return DataCell(
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHoveredTeacher(teacherId),
        onExit: (_) => _clearHoveredTeacher(teacherId),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showTeacherDetails(context, data),
          child: child,
        ),
      ),
    );
  }

  void _setHoveredTeacher(String teacherId) {
    if (_hoverPaused) return;
    if (_hoveredTeacherId == teacherId) return;
    setState(() => _hoveredTeacherId = teacherId);
  }

  void _clearHoveredTeacher(String teacherId) {
    if (_hoverPaused) return;
    if (_hoveredTeacherId != teacherId) return;
    setState(() => _hoveredTeacherId = null);
  }

  void _pauseHoverForScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _hoverResumeTimer?.cancel();
    if (!_hoverPaused || _hoveredTeacherId != null) {
      setState(() {
        _hoverPaused = true;
        _hoveredTeacherId = null;
      });
    }
    _hoverResumeTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _hoverPaused = false);
    });
  }

  void _setAllSelected(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedTeacherIds
          ..clear()
          ..addAll(docs.map((doc) => doc.id));
      } else {
        _selectedTeacherIds.clear();
      }
    });
  }

  void _setTeacherSelected(String teacherId, bool selected) {
    setState(() {
      if (selected) {
        _selectedTeacherIds.add(teacherId);
      } else {
        _selectedTeacherIds.remove(teacherId);
      }
    });
  }

  Future<void> _bulkArchiveTeachers(
    BuildContext context,
    SchoolAdminViewModel app,
    SchoolYear schoolYear,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedDocs,
  ) async {
    if (selectedDocs.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive selected teachers?'),
        content: Text(
          'This will archive ${selectedDocs.length} selected teacher ${selectedDocs.length == 1 ? 'record' : 'records'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive selected'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _archiveTeacherDocs(
      app: app,
      schoolYear: schoolYear,
      docs: selectedDocs,
      bulk: true,
    );
    if (!context.mounted) return;
    setState(_selectedTeacherIds.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedDocs.length} teachers archived.')),
    );
  }

  Future<void> _archiveTeacherDocs({
    required SchoolAdminViewModel app,
    required SchoolYear schoolYear,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required bool bulk,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      batch.set(doc.reference, {
        'archived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    await app.audit.record(
      action: bulk ? 'teachers_bulk_archived' : 'teachers_archived',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: bulk
          ? '${docs.length} teacher records'
          : docs.first.data()['teacherId'] as String? ?? docs.first.id,
      metadata: {
        'schoolYear': schoolYear.name,
        if (bulk)
          'teacherIds': docs
              .map((doc) => doc.data()['teacherId'] as String? ?? doc.id)
              .toList(),
      },
    );
  }
}

class _TeacherBulkArchiveBar extends StatelessWidget {
  const _TeacherBulkArchiveBar({
    required this.selectedCount,
    required this.onClear,
    required this.onArchive,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(45)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              FilledButton.icon(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive selected'),
              ),
            ],
          ),
        ],
      ),
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
