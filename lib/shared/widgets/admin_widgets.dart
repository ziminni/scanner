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
    this.itemsPerPage = 10,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final bool schoolYearScoped;
  final String search;
  final int itemsPerPage;
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
            initialItemsPerPage: itemsPerPage,
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
      initialItemsPerPage: itemsPerPage,
      onEdit: onEdit,
      onArchive: (docId) =>
          app.admin.archiveRecord(collection, docId, app.currentUser!),
    );
  }
}

class _CollectionTableBody extends StatefulWidget {
  const _CollectionTableBody({
    required this.collection,
    required this.columns,
    required this.stream,
    required this.onArchive,
    this.search = '',
    required this.initialItemsPerPage,
    this.schoolYearId,
    this.onEdit,
  });

  final String collection;
  final List<String> columns;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<void> Function(String docId) onArchive;
  final String search;
  final int initialItemsPerPage;
  final String? schoolYearId;
  final void Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onEdit;

  @override
  State<_CollectionTableBody> createState() => _CollectionTableBodyState();
}

class _CollectionTableBodyState extends State<_CollectionTableBody> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  late int _currentPage;
  late int _itemsPerPage;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _itemsPerPage = widget.initialItemsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        final query = widget.search.trim().toLowerCase();
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          if (query.isEmpty) return true;
          final data = doc.data();
          return widget.columns
              .map((column) => adminFormatValue(data[column]))
              .join(' ')
              .toLowerCase()
              .contains(query);
        }).toList();
        if (docs.isEmpty) {
          return EmptyState(title: 'No ${widget.collection} records yet');
        }
        final totalPages = (docs.length / _itemsPerPage).ceil();
        final currentPage = totalPages == 0
            ? 0
            : _currentPage.clamp(0, totalPages - 1).toInt();
        final start = currentPage * _itemsPerPage;
        final end = (start + _itemsPerPage).clamp(0, docs.length).toInt();
        final paginatedDocs = docs.sublist(start, end);
        final hasCountsColumn = widget.columns.any(
          (column) => column.toLowerCase() == 'counts',
        );

        return DataSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: hasCountsColumn ? 96 : 44,
                        dataRowMaxHeight: hasCountsColumn ? 132 : 44,
                        columns: [
                          for (final column in widget.columns)
                            DataColumn(label: Text(adminLabel(column))),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final doc in paginatedDocs)
                            DataRow(
                              cells: [
                                for (final column in widget.columns)
                                  DataCell(
                                    _buildCell(
                                      context,
                                      doc.data()[column],
                                      column,
                                    ),
                                  ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Archive',
                                        icon: const Icon(
                                          Icons.archive_outlined,
                                        ),
                                        onPressed: () =>
                                            widget.onArchive(doc.id),
                                      ),
                                      if (widget.onEdit != null)
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => widget.onEdit!(
                                            context,
                                            doc.id,
                                            doc.data(),
                                            widget.schoolYearId,
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
              ),
              const SizedBox(height: 12),
              AdminTableFooter(
                currentPage: currentPage,
                totalItems: docs.length,
                itemsPerPage: _itemsPerPage,
                itemLabel: 'records',
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
  }

  Widget _buildCell(BuildContext context, Object? value, String column) {
    final lower = column.toLowerCase();
    if (lower == 'counts' && value is Map) {
      return _CountsCell(counts: value);
    }
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

class _CountsCell extends StatelessWidget {
  const _CountsCell({required this.counts});

  static const int _visibleCount = 4;

  final Map counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final constrainedWidth =
        (screenWidth < 700 ? screenWidth * 0.58 : screenWidth * 0.32)
            .clamp(200.0, 360.0)
            .toDouble();
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    final visibleEntries = entries.take(_visibleCount).toList();
    final hiddenCount = entries.length - visibleEntries.length;

    if (entries.isEmpty) {
      return const Text('-');
    }

    return SizedBox(
      width: constrainedWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in visibleEntries)
              _CountListItem(
                label: adminLabel(entry.key.toString()),
                value: entry.value?.toString() ?? '0',
              ),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+$hiddenCount more collections',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountListItem extends StatelessWidget {
  const _CountListItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTableFooter extends StatelessWidget {
  const AdminTableFooter({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.itemLabel,
    required this.itemsPerPageOptions,
    required this.onItemsPerPageChanged,
  });

  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final String itemLabel;
  final List<int> itemsPerPageOptions;
  final ValueChanged<int> onItemsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = totalItems == 0 ? 0 : currentPage * itemsPerPage + 1;
    final end = (currentPage * itemsPerPage + itemsPerPage)
        .clamp(0, totalItems)
        .toInt();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Showing $start to $end of $totalItems $itemLabel',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rows per page:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: itemsPerPage,
              isDense: true,
              items: itemsPerPageOptions
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option,
                      child: Text(option.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onItemsPerPageChanged(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class AdminPaginationControls extends StatelessWidget {
  const AdminPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
          tooltip: 'First page',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          tooltip: 'Previous page',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${currentPage + 1} of $totalPages'),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage + 1 < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          tooltip: 'Next page',
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: currentPage + 1 < totalPages
              ? () => onPageChanged(totalPages - 1)
              : null,
          tooltip: 'Last page',
        ),
      ],
    );
  }
}

class FullWidthHorizontalTable extends StatelessWidget {
  const FullWidthHorizontalTable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: child,
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
  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}');
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
