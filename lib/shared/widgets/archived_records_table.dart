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

        final docs = [...snapshot.data?.docs ?? []]
          ..sort((a, b) {
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
                      const DataColumn(label: Text('Actions')),
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
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Restore',
                                    icon: const Icon(Icons.restore_outlined),
                                    onPressed: () => _restoreArchivedRecord(
                                      context,
                                      docs[index],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete permanently',
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () => _deleteArchivedRecord(
                                      context,
                                      docs[index],
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restoreArchivedRecord(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final title = _recordTitle(doc);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore archived record?'),
        content: Text('Restore $title to the active records?'),
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
    await doc.reference.set({
      'archived': false,
      'restoredAt': FieldValue.serverTimestamp(),
      'archivedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
    await app.audit.record(
      action: '${widget.collection}_restored',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: title,
      metadata: {
        if (widget.schoolYearId != null) 'schoolYearId': widget.schoolYearId,
        if (widget.schoolYearName != null) 'schoolYear': widget.schoolYearName,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title restored.')));
  }

  Future<void> _deleteArchivedRecord(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final title = _recordTitle(doc);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete archived record?'),
        content: Text(
          'This will permanently delete $title from the archive. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final app = AppScope.of(context);
    await doc.reference.delete();
    await app.audit.record(
      action: '${widget.collection}_deleted_from_archive',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: title,
      metadata: {
        if (widget.schoolYearId != null) 'schoolYearId': widget.schoolYearId,
        if (widget.schoolYearName != null) 'schoolYear': widget.schoolYearName,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title permanently deleted.')));
  }

  String _recordTitle(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = adminPersonName(data);
    if (name != '-') return name;
    for (final key in ['name', 'teacherId', 'lrn', 'title']) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return doc.id;
  }
}
