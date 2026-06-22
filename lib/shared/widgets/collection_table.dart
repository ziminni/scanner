import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import 'app_widgets.dart';
import 'collection_table_body.dart';

class CollectionTable extends StatelessWidget {
  const CollectionTable({
    super.key,
    required this.collection,
    required this.columns,
    this.schoolYearScoped = false,
    this.search = '',
    this.filters = const {},
    this.itemsPerPage = 10,
    this.confirmArchive = false,
    this.enableBulkArchive = false,
    this.showArchiveAction = true,
    this.teacherTableStyle = false,
    this.itemLabel = 'records',
    this.columnLabels = const {},
    this.onRowTap,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;
  final String search;
  final Map<String, String> filters;
  final int itemsPerPage;
  final bool confirmArchive;
  final bool enableBulkArchive;
  final bool showArchiveAction;
  final bool teacherTableStyle;
  final String itemLabel;
  final Map<String, String> columnLabels;
  final void Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onRowTap;
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
          return CollectionTableBody(
            collection: collection,
            columns: columns,
            stream: app.repository
                .schoolYearCollection(schoolYear.id, collection)
                .limit(200)
                .snapshots(),
            initialItemsPerPage: itemsPerPage,
            schoolYearId: schoolYear.id,
            search: search,
            filters: filters,
            confirmArchive: confirmArchive,
            enableBulkArchive: enableBulkArchive,
            showArchiveAction: showArchiveAction,
            teacherTableStyle: teacherTableStyle,
            itemLabel: itemLabel,
            columnLabels: columnLabels,
            onRowTap: onRowTap,
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
            onBulkArchive: (docIds) async {
              final batch = app.firestore.batch();
              for (final docId in docIds) {
                batch.set(
                  app.repository
                      .schoolYearCollection(schoolYear.id, collection)
                      .doc(docId),
                  {
                    'archived': true,
                    'archivedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );
              }
              await batch.commit();
              await app.audit.record(
                action: '${collection}_bulk_archived',
                actorId: app.currentUser!.id,
                actorName: app.currentUser!.fullName,
                target: '${docIds.length} $collection records',
                metadata: {'schoolYear': schoolYear.name, 'recordIds': docIds},
              );
            },
          );
        },
      );
    }
    return CollectionTableBody(
      collection: collection,
      columns: columns,
      stream: app.repository.rootCollection(collection).limit(200).snapshots(),
      search: search,
      filters: filters,
      confirmArchive: confirmArchive,
      enableBulkArchive: enableBulkArchive,
      showArchiveAction: showArchiveAction,
      teacherTableStyle: teacherTableStyle,
      itemLabel: itemLabel,
      columnLabels: columnLabels,
      onRowTap: onRowTap,
      initialItemsPerPage: itemsPerPage,
      onEdit: onEdit,
      onArchive: (docId) =>
          app.admin.archiveRecord(collection, docId, app.currentUser!),
      onBulkArchive: (docIds) async {
        for (final docId in docIds) {
          await app.admin.archiveRecord(collection, docId, app.currentUser!);
        }
      },
    );
  }
}
