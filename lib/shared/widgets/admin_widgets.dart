import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import 'app_widgets.dart';

class CollectionTable extends StatelessWidget {
  const CollectionTable({
    super.key,
    required this.collection,
    required this.columns,
    this.schoolYearScoped = false,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;
  final void Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onEdit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (schoolYearScoped) {
      return FutureBuilder(
        future: app.attendance.activeSchoolYear(),
        builder: (context, snapshot) {
          final schoolYear = snapshot.data;
          if (schoolYear == null) {
            return const EmptyState(
              title: 'Create an active school year first',
            );
          }
          return _CollectionTableBody(
            collection: collection,
            columns: columns,
            stream: app.repository
                .schoolYearCollection(schoolYear.id, collection)
                .limit(200)
                .snapshots(),
            schoolYearId: schoolYear.id,
            onEdit: onEdit,
            onArchive: (docId) async {
              await app.repository
                  .schoolYearCollection(schoolYear.id, collection)
                  .doc(docId)
                  .set({
                    'archived': true,
                    'archivedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
              await app.audit.record(
                action: '${collection}_archived',
                actorId: app.currentUser!.id,
                actorName: app.currentUser!.fullName,
                metadata: {'schoolYear': schoolYear.name},
              );
            },
          );
        },
      );
    }
    return _CollectionTableBody(
      collection: collection,
      columns: columns,
      stream: app.repository.rootCollection(collection).limit(200).snapshots(),
      onEdit: onEdit,
      onArchive: (docId) =>
          app.admin.archiveRecord(collection, docId, app.currentUser!),
    );
  }
}

class _CollectionTableBody extends StatelessWidget {
  const _CollectionTableBody({
    required this.collection,
    required this.columns,
    required this.stream,
    required this.onArchive,
    this.schoolYearId,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<void> Function(String docId) onArchive;
  final String? schoolYearId;
  final void Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onEdit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return EmptyState(title: 'No $collection records yet');
        }
        return DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                for (final column in columns)
                  DataColumn(label: Text(adminLabel(column))),
                const DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final doc in docs)
                  DataRow(
                    cells: [
                      for (final column in columns)
                        DataCell(_buildCell(context, doc.data()[column], column)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Archive',
                              icon: const Icon(Icons.archive_outlined),
                              onPressed: () => onArchive(doc.id),
                            ),
                            if (onEdit != null)
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => onEdit!(
                                  context,
                                  doc.id,
                                  doc.data(),
                                  schoolYearId,
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
        );
      },
    );
  }

  Widget _buildCell(BuildContext context, Object? value, String column) {
    final lower = column.toLowerCase();
    if (lower.contains('status')) {
      final label = value?.toString() ?? '-';
      final type = label.toLowerCase().contains('late')
          ? 'late'
          : label.toLowerCase().contains('disabled')
              ? 'disabled'
              : 'active';
      return StatusBadge(label: label, type: type);
    }
    if (value is Timestamp) return TimestampText(value);
    if (value is DateTime) return TimestampText(value);
    return Text(adminFormatValue(value));
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            Row(children: actions),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class DataSurface extends StatelessWidget {
  const DataSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

String adminLabel(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String adminFormatValue(Object? value) {
  if (value == null) {
    return '-';
  }
  if (value is Timestamp) {
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }
  return value.toString();
}
