import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import 'admin_formatters.dart';
import 'app_widgets.dart';
import 'archive_selection_bar.dart';
import 'full_width_horizontal_table.dart';

class ArchivedRecordsTable extends StatefulWidget {
  const ArchivedRecordsTable({
    super.key,
    required this.stream,
    required this.collection,
    required this.columns,
    required this.schoolYearId,
    required this.schoolYearName,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String collection;
  final List<String> columns;
  final String? schoolYearId;
  final String? schoolYearName;

  @override
  State<ArchivedRecordsTable> createState() => ArchivedRecordsTableState();
}

class ArchivedRecordsTableState extends State<ArchivedRecordsTable> {
  final Set<String> _selectedArchiveIds = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            [
              ...(snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
            ]..sort((a, b) {
              final aTime = a.data()['archivedAt'];
              final bTime = b.data()['archivedAt'];
              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.toDate().compareTo(aTime.toDate());
              }
              return 0;
            });
        _selectedArchiveIds.removeWhere(
          (id) => docs.every((doc) => doc.id != id),
        );
        final selectedCount = docs
            .where((doc) => _selectedArchiveIds.contains(doc.id))
            .length;
        final selectedDocs = docs
            .where((doc) => _selectedArchiveIds.contains(doc.id))
            .toList();

        if (docs.isEmpty) {
          return SizedBox(
            height: 180,
            child: EmptyState(title: 'No archived ${widget.collection} yet'),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedCount > 0) ...[
                  ArchiveSelectionBar(
                    selectedCount: selectedCount,
                    onClear: () => setState(_selectedArchiveIds.clear),
                    onRestore: () =>
                        _restoreSelectedRecords(context, selectedDocs),
                    onDelete: () =>
                        _deleteSelectedRecords(context, selectedDocs),
                  ),
                  const SizedBox(height: 12),
                ],
                FullWidthHorizontalTable(
                  child: DataTable(
                    onSelectAll: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedArchiveIds
                            ..clear()
                            ..addAll(docs.map((doc) => doc.id));
                        } else {
                          _selectedArchiveIds.clear();
                        }
                      });
                    },
                    headingRowHeight: 48,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 56,
                    columns: [
                      const DataColumn(label: Text('#')),
                      for (final column in widget.columns)
                        DataColumn(
                          label: Text(
                            column == 'fullName'
                                ? 'Full Name'
                                : adminLabel(column),
                          ),
                        ),
                    ],
                    rows: [
                      for (var index = 0; index < docs.length; index++)
                        DataRow(
                          selected: _selectedArchiveIds.contains(
                            docs[index].id,
                          ),
                          onSelectChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedArchiveIds.add(docs[index].id);
                              } else {
                                _selectedArchiveIds.remove(docs[index].id);
                              }
                            });
                          },
                          cells: [
                            DataCell(Text('${index + 1}')),
                            for (final column in widget.columns)
                              DataCell(
                                Text(
                                  column == 'fullName'
                                      ? adminPersonName(docs[index].data())
                                      : adminFormatValue(
                                          docs[index].data()[column],
                                        ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restoreSelectedRecords(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore selected records?'),
        content: Text(
          'Restore ${docs.length} selected ${widget.collection} records to the active list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Restore'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final app = AppScope.of(context);
    await _commitInBatches(app, docs, (batch, doc) {
      batch.set(doc.reference, {
        'archived': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'archivedAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    });
    await app.audit.record(
      action: '${widget.collection}_restored',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: '${docs.length} ${widget.collection} records',
      metadata: {
        'recordCount': docs.length,
        if (widget.schoolYearId != null) 'schoolYearId': widget.schoolYearId,
        if (widget.schoolYearName != null) 'schoolYear': widget.schoolYearName,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${docs.length} records restored.')));
  }

  Future<void> _deleteSelectedRecords(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final choice = await _showDeleteConfirmation(context, docs.length);
    if (choice == null || !choice.deleteRecords || !context.mounted) return;

    final app = AppScope.of(context);
    final relatedLogRefs = choice.deleteRelatedLogs
        ? await _relatedLogRefs(app, docs)
        : <DocumentReference<Map<String, dynamic>>>[];
    await _commitDeleteRefsInBatches(app, [
      ...docs.map((doc) => doc.reference),
      ...relatedLogRefs,
    ]);
    await app.audit.record(
      action: '${widget.collection}_deleted_from_archive',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: '${docs.length} ${widget.collection} records',
      metadata: {
        'recordCount': docs.length,
        'relatedLogCount': relatedLogRefs.length,
        'relatedLogsDeleted': choice.deleteRelatedLogs,
        if (widget.schoolYearId != null) 'schoolYearId': widget.schoolYearId,
        if (widget.schoolYearName != null) 'schoolYear': widget.schoolYearName,
      },
    );
    if (!context.mounted) return;
    final logMessage = relatedLogRefs.isEmpty
        ? ''
        : ' ${relatedLogRefs.length} related logs deleted.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${docs.length} records permanently deleted.$logMessage'),
      ),
    );
  }

  Future<_ArchiveDeleteChoice?> _showDeleteConfirmation(
    BuildContext context,
    int recordCount,
  ) {
    var deleteRelatedLogs = false;
    final canDeleteRelatedLogs =
        widget.schoolYearId != null &&
        (widget.collection == 'students' || widget.collection == 'teachers');

    return showDialog<_ArchiveDeleteChoice>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete selected records?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete $recordCount selected ${widget.collection} records from the archive. This cannot be undone.',
              ),
              if (canDeleteRelatedLogs) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deleteRelatedLogs,
                  title: const Text('Also delete related logs'),
                  subtitle: const Text(
                    'Delete attendance and gate pass logs involving the selected records.',
                  ),
                  onChanged: (value) {
                    setDialogState(() => deleteRelatedLogs = value ?? false);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(
                _ArchiveDeleteChoice(
                  deleteRecords: true,
                  deleteRelatedLogs: canDeleteRelatedLogs && deleteRelatedLogs,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _relatedLogRefs(
    AppController app,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final schoolYearId = widget.schoolYearId;
    if (schoolYearId == null) return [];
    final personIds = docs
        .map(_personIdForArchiveDoc)
        .where((id) => id.isNotEmpty)
        .toSet();
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final personId in personIds) {
      for (final collection in const ['attendance_logs', 'gate_pass_logs']) {
        final snapshot = await app.repository
            .schoolYearCollection(schoolYearId, collection)
            .where('personId', isEqualTo: personId)
            .get();
        refs.addAll(snapshot.docs.map((doc) => doc.reference));
      }
    }
    return refs;
  }

  String _personIdForArchiveDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (widget.collection == 'students') {
      return (data['lrn'] as String? ?? doc.id).trim();
    }
    if (widget.collection == 'teachers') {
      return (data['teacherId'] as String? ?? doc.id).trim();
    }
    return '';
  }

  Future<void> _commitDeleteRefsInBatches(
    AppController app,
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    for (var start = 0; start < refs.length; start += 450) {
      final batch = app.firestore.batch();
      for (final ref in refs.skip(start).take(450)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _commitInBatches(
    AppController app,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    void Function(
      WriteBatch batch,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    )
    write,
  ) async {
    for (var start = 0; start < docs.length; start += 450) {
      final batch = app.firestore.batch();
      for (final doc in docs.skip(start).take(450)) {
        write(batch, doc);
      }
      await batch.commit();
    }
  }
}

class _ArchiveDeleteChoice {
  const _ArchiveDeleteChoice({
    required this.deleteRecords,
    required this.deleteRelatedLogs,
  });

  final bool deleteRecords;
  final bool deleteRelatedLogs;
}
