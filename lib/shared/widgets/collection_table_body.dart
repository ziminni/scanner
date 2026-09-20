import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart'
    show PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_formatters.dart';
import 'admin_pagination_controls.dart';
import 'admin_table_footer.dart';
import 'admin_table_skeleton.dart';
import 'app_widgets.dart';
import 'bulk_archive_selection_bar.dart';
import 'bulk_selection_action.dart';
import 'counts_cell.dart';
import 'data_surface.dart';
import 'full_width_horizontal_table.dart';

class CollectionTableBody extends StatefulWidget {
  const CollectionTableBody({
    super.key,
    required this.collection,
    required this.columns,
    required this.stream,
    required this.onArchive,
    this.search = '',
    this.filters = const {},
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
    required this.initialItemsPerPage,
    this.schoolYearId,
    this.onEdit,
    this.onDownload,
    this.onBulkArchive,
    this.onRowTap,
  });

  final String collection;
  final List<String> columns;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Future<void> Function(String docId) onArchive;
  final String search;
  final Map<String, String> filters;
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
  final int initialItemsPerPage;
  final String? schoolYearId;
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
  final Future<void> Function(List<String> docIds)? onBulkArchive;
  final void Function(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String? schoolYearId,
  )?
  onRowTap;

  @override
  State<CollectionTableBody> createState() => CollectionTableBodyState();
}

class CollectionTableBodyState extends State<CollectionTableBody> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];

  late int _currentPage;
  late int _itemsPerPage;
  final Set<String> _selectedRecordIds = {};
  String? _hoveredRecordId;
  Timer? _hoverResumeTimer;
  bool _hoverPaused = false;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _itemsPerPage = widget.initialItemsPerPage;
  }

  @override
  void dispose() {
    _hoverResumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AdminTableSkeleton(
            columns: widget.columns.length + (widget.enableBulkArchive ? 3 : 2),
          );
        }
        final query = widget.search.trim().toLowerCase();
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          if (data['archived'] == true) return false;
          if (!_matchesFilters(data, widget.filters)) return false;
          if (query.isEmpty) return true;
          return widget.columns
              .map((column) => adminTableSearchValue(data, column))
              .join(' ')
              .toLowerCase()
              .contains(query);
        }).toList();
        final sortComparator = widget.sortComparator;
        if (sortComparator != null) docs.sort(sortComparator);
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
        _selectedRecordIds.removeWhere(
          (id) => docs.every((doc) => doc.id != id),
        );
        final selectedCount = docs
            .where((doc) => _selectedRecordIds.contains(doc.id))
            .length;
        final hasCountsColumn = widget.columns.any(
          (column) => column.toLowerCase() == 'counts',
        );

        return DataSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.enableBulkArchive && selectedCount > 0) ...[
                BulkArchiveSelectionBar(
                  selectedCount: selectedCount,
                  onClear: () => setState(_selectedRecordIds.clear),
                  onArchive: () => _bulkArchiveRecords(context, selectedCount),
                  secondaryActionLabel: widget.bulkSecondaryActionLabel,
                  secondaryActionIcon: widget.bulkSecondaryActionIcon,
                  secondaryMenuItems: [
                    for (final action in widget.bulkSecondaryActions)
                      BulkSelectionMenuItem(
                        label: action.label,
                        icon: action.icon,
                        onPressed: () => _runBulkSecondaryAction(
                          _selectedRecordIds.toList(),
                          action: action.onSelected,
                        ),
                      ),
                  ],
                  onSecondaryAction: () =>
                      _runBulkSecondaryAction(_selectedRecordIds.toList()),
                ),
                const SizedBox(height: 12),
              ],
              Listener(
                onPointerSignal: _pauseHoverForScroll,
                child: FullWidthHorizontalTable(
                  child: DataTable(
                    headingRowHeight: widget.teacherTableStyle ? 44 : 48,
                    dataRowMinHeight: hasCountsColumn
                        ? 96
                        : widget.teacherTableStyle
                        ? 52
                        : 44,
                    dataRowMaxHeight: hasCountsColumn
                        ? 132
                        : widget.teacherTableStyle
                        ? 64
                        : 44,
                    columns: [
                      if (widget.enableBulkArchive)
                        DataColumn(
                          label: Checkbox(
                            value: selectedCount == docs.length,
                            tristate:
                                selectedCount > 0 &&
                                selectedCount < docs.length,
                            onChanged: (selected) =>
                                _setAllSelected(docs, selected == true),
                          ),
                        ),
                      const DataColumn(label: Text('#')),
                      for (final column in widget.columns)
                        DataColumn(
                          label: Text(
                            widget.columnLabels[column] ??
                                (column == 'fullName'
                                    ? 'Full Name'
                                    : adminLabel(column)),
                          ),
                        ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (var index = 0; index < paginatedDocs.length; index++)
                        DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            final colorScheme = Theme.of(context).colorScheme;
                            if (_hoveredRecordId == paginatedDocs[index].id) {
                              return colorScheme.primary.withAlpha(20);
                            }
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.primary.withAlpha(12);
                            }
                            return null;
                          }),
                          selected: _selectedRecordIds.contains(
                            paginatedDocs[index].id,
                          ),
                          cells: [
                            if (widget.enableBulkArchive)
                              DataCell(
                                Checkbox(
                                  value: _selectedRecordIds.contains(
                                    paginatedDocs[index].id,
                                  ),
                                  onChanged: (selected) => _setRecordSelected(
                                    paginatedDocs[index].id,
                                    selected == true,
                                  ),
                                ),
                              ),
                            _detailsCell(
                              recordId: paginatedDocs[index].id,
                              child: Text('${start + index + 1}'),
                              onTap: () =>
                                  _openRecord(context, paginatedDocs[index]),
                            ),
                            for (final column in widget.columns)
                              _detailsCell(
                                recordId: paginatedDocs[index].id,
                                child: _buildCell(
                                  context,
                                  column == 'fullName'
                                      ? adminPersonName(
                                          paginatedDocs[index].data(),
                                        )
                                      : paginatedDocs[index].data()[column],
                                  column,
                                ),
                                onTap: () =>
                                    _openRecord(context, paginatedDocs[index]),
                              ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.onEdit != null)
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => widget.onEdit!(
                                        context,
                                        paginatedDocs[index].id,
                                        paginatedDocs[index].data(),
                                        widget.schoolYearId,
                                      ),
                                    ),
                                  if (widget.onDownload != null)
                                    IconButton(
                                      tooltip: 'Download QR',
                                      icon: const Icon(Icons.download_outlined),
                                      onPressed: () => widget.onDownload!(
                                        context,
                                        paginatedDocs[index].id,
                                        paginatedDocs[index].data(),
                                        widget.schoolYearId,
                                      ),
                                    ),
                                  if (widget.showArchiveAction)
                                    IconButton(
                                      tooltip: 'Archive',
                                      icon: const Icon(Icons.archive_outlined),
                                      onPressed: () => _archiveRecord(
                                        context,
                                        paginatedDocs[index],
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
                itemLabel: widget.itemLabel,
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

  Future<void> _archiveRecord(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (widget.confirmArchive) {
      final name = adminPersonName(doc.data());
      final label = widget.collection == 'students' ? 'student' : 'record';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Archive $label?'),
          content: Text(
            'This will remove $name from the active ${widget.collection} list. You can restore the record from Archives later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    await widget.onArchive(doc.id);
    if (mounted) setState(() => _selectedRecordIds.remove(doc.id));
  }

  void _openRecord(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    widget.onRowTap?.call(context, doc.id, doc.data(), widget.schoolYearId);
  }

  DataCell _detailsCell({
    required String recordId,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return DataCell(
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHoveredRecord(recordId),
        onExit: (_) => _clearHoveredRecord(recordId),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  void _setHoveredRecord(String recordId) {
    if (_hoverPaused) return;
    if (_hoveredRecordId == recordId) return;
    setState(() => _hoveredRecordId = recordId);
  }

  void _setAllSelected(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedRecordIds
          ..clear()
          ..addAll(docs.map((doc) => doc.id));
      } else {
        _selectedRecordIds.clear();
      }
    });
  }

  void _setRecordSelected(String recordId, bool selected) {
    setState(() {
      if (selected) {
        _selectedRecordIds.add(recordId);
      } else {
        _selectedRecordIds.remove(recordId);
      }
    });
  }

  void _clearHoveredRecord(String recordId) {
    if (_hoverPaused) return;
    if (_hoveredRecordId != recordId) return;
    setState(() => _hoveredRecordId = null);
  }

  void _pauseHoverForScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _hoverResumeTimer?.cancel();
    if (!_hoverPaused || _hoveredRecordId != null) {
      setState(() {
        _hoverPaused = true;
        _hoveredRecordId = null;
      });
    }
    _hoverResumeTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _hoverPaused = false);
    });
  }

  Future<void> _bulkArchiveRecords(
    BuildContext context,
    int selectedCount,
  ) async {
    final archive = widget.onBulkArchive;
    if (archive == null || selectedCount == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive selected ${widget.collection}?'),
        content: Text(
          'This will archive $selectedCount selected ${widget.collection} records. You can restore them from Archives later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive selected'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await archive(_selectedRecordIds.toList());
    if (mounted) setState(_selectedRecordIds.clear);
  }

  Future<void> _runBulkSecondaryAction(
    List<String> docIds, {
    Future<bool> Function(List<String> docIds)? action,
  }) async {
    action ??= widget.onBulkSecondaryAction;
    if (action == null || docIds.isEmpty) return;
    final completed = await action(docIds);
    if (completed && mounted) setState(_selectedRecordIds.clear);
  }

  bool _matchesFilters(Map<String, dynamic> data, Map<String, String> filters) {
    for (final entry in filters.entries) {
      final selected = entry.value.trim();
      if (selected.isEmpty) continue;
      if (entry.key == 'section' && selected.toLowerCase() == 'unassigned') {
        final rawSection = data[entry.key]?.toString().trim() ?? '';
        if (rawSection.isNotEmpty && rawSection != '-') return false;
        continue;
      }
      if (entry.key == 'isAral') {
        final isAral = data['isAral'] as bool? ?? false;
        if (isAral.toString() != selected.toLowerCase()) return false;
        continue;
      }
      if (entry.key == 'blankFields') {
        if (selected.toLowerCase() != 'true') continue;
        if (!_hasBlankDisplayField(data)) return false;
        continue;
      }
      final value = _normalizeFilterValue(adminFormatValue(data[entry.key]));
      if (value != _normalizeFilterValue(selected)) return false;
    }
    return true;
  }

  bool _hasBlankDisplayField(Map<String, dynamic> data) {
    const fields = [
      'lrn',
      'lastName',
      'firstName',
      'gender',
      'birthdate',
      'address',
      'guardianName',
      'guardianContact',
      'section',
    ];
    return fields.any((field) {
      final value = data[field];
      if (value == null) return true;
      if (value is String) {
        final text = value.trim();
        return text.isEmpty || text == '-';
      }
      return false;
    });
  }

  String _normalizeFilterValue(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Widget _buildCell(BuildContext context, Object? value, String column) {
    final lower = column.toLowerCase();
    if (lower == 'counts' && value is Map) {
      return CountsCell(counts: value);
    }
    if (lower == 'birthdate') {
      final date = switch (value) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      };
      return Text(date == null ? '-' : DateFormat('MMM d, yyyy').format(date));
    }
    if (lower == 'address') {
      final address = adminFormatValue(value);
      return SizedBox(
        width: 105,
        child: Text(
          address.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (lower == 'fullname' || lower == 'guardianname') {
      return Text(adminFormatValue(value).toUpperCase());
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
