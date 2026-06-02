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
    this.search = '',
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;
  final String search;
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
            search: search,
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
      search: search,
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
    this.search = '',
    this.schoolYearId,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<void> Function(String docId) onArchive;
  final String search;
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
        final query = search.trim().toLowerCase();
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data();
          return columns
              .map((column) => adminFormatValue(data[column]))
              .join(' ')
              .toLowerCase()
              .contains(query);
        }).toList();
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
                        DataCell(Text(adminFormatValue(doc.data()[column]))),
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
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        const SizedBox(height: 16),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
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
