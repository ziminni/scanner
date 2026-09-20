import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import 'app_widgets.dart';
import 'admin_table_skeleton.dart';
import 'bulk_selection_action.dart';
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
    this.queryLimit = 200,
    this.sortComparator,
    this.confirmArchive = false,
    this.enableBulkArchive = false,
    this.showArchiveAction = true,
    this.teacherTableStyle = false,
    this.itemLabel = 'records',
    this.columnLabels = const {},
    this.bulkSecondaryActionLabel,
    this.bulkSecondaryActionIcon,
    this.bulkSecondaryActions = const [],
    this.onBulkSecondaryAction,
    this.onRowTap,
    this.onEdit,
    this.onDownload,
  });

  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;
  final String search;
  final Map<String, String> filters;
  final int itemsPerPage;
  final int? queryLimit;
  final int Function(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  )?
  sortComparator;
  final bool confirmArchive;
  final bool enableBulkArchive;
  final bool showArchiveAction;
  final bool teacherTableStyle;
  final String itemLabel;
  final Map<String, String> columnLabels;
  final String? bulkSecondaryActionLabel;
  final IconData? bulkSecondaryActionIcon;
  final List<BulkSelectionAction> bulkSecondaryActions;
  final Future<bool> Function(List<String> docIds)? onBulkSecondaryAction;
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
  final Future<void> Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onDownload;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (schoolYearScoped) {
      return FutureBuilder(
        future: app.attendance.activeSchoolYear(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdminTableSkeleton(columns: columns.length + 2);
          }
          final schoolYear = snapshot.data;
          if (schoolYear == null) {
            return const EmptyState(
              title: 'Create an active school year first',
            );
          }
          return CollectionTableBody(
            collection: collection,
            columns: columns,
            stream: _applyLimit(
              app.repository.schoolYearCollection(schoolYear.id, collection),
            ).snapshots(),
            initialItemsPerPage: itemsPerPage,
            schoolYearId: schoolYear.id,
            search: search,
            filters: filters,
            sortComparator: sortComparator,
            confirmArchive: confirmArchive,
            enableBulkArchive: enableBulkArchive,
            showArchiveAction: showArchiveAction,
            teacherTableStyle: teacherTableStyle,
            itemLabel: itemLabel,
            columnLabels: columnLabels,
            bulkSecondaryActionLabel: bulkSecondaryActionLabel,
            bulkSecondaryActionIcon: bulkSecondaryActionIcon,
            bulkSecondaryActions: bulkSecondaryActions,
            onBulkSecondaryAction: onBulkSecondaryAction,
            onRowTap: onRowTap,
            onEdit: onEdit,
            onDownload: onDownload,
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
      stream: _applyLimit(
        app.repository.rootCollection(collection),
      ).snapshots(),
      search: search,
      filters: filters,
      sortComparator: sortComparator,
      confirmArchive: confirmArchive,
      enableBulkArchive: enableBulkArchive,
      showArchiveAction: showArchiveAction,
      teacherTableStyle: teacherTableStyle,
      itemLabel: itemLabel,
      columnLabels: columnLabels,
      bulkSecondaryActionLabel: bulkSecondaryActionLabel,
      bulkSecondaryActionIcon: bulkSecondaryActionIcon,
      bulkSecondaryActions: bulkSecondaryActions,
      onBulkSecondaryAction: onBulkSecondaryAction,
      onRowTap: onRowTap,
      initialItemsPerPage: itemsPerPage,
      onEdit: onEdit,
      onDownload: onDownload,
      onArchive: (docId) =>
          app.admin.archiveRecord(collection, docId, app.currentUser!),
      onBulkArchive: (docIds) async {
        for (final docId in docIds) {
          await app.admin.archiveRecord(collection, docId, app.currentUser!);
        }
      },
    );
  }

  Query<Map<String, dynamic>> _applyLimit(Query<Map<String, dynamic>> query) {
    final limit = queryLimit;
    return limit == null ? query : query.limit(limit);
  }
}
