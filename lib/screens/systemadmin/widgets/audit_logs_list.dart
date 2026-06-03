part of '../audit_logs_page.dart';

class AuditLogsList extends StatefulWidget {
  const AuditLogsList({super.key, required this.limit});

  final int limit;

  @override
  State<AuditLogsList> createState() => _AuditLogsListState();
}

class _AuditLogsListState extends State<AuditLogsList> {
  static const List<int> _itemsPerPageOptions = [10, 25, 50, 100];
  static const _all = 'All';

  final _search = TextEditingController();
  int _currentPage = 0;
  int _itemsPerPage = 10;
  String _category = _all;
  String _severity = _all;
  String _actor = _all;
  String _dateRange = _all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.auditLogsStream(widget.limit),
      builder: (context, snapshot) {
        final logs = (snapshot.data?.docs ?? [])
            .map(_AuditLogEntry.fromDoc)
            .toList();
        final actors = logs.map((log) => log.actorName).toSet().toList()
          ..sort();
        final filteredLogs = logs.where(_matchesFilters).toList();
        final totalPages = (filteredLogs.length / _itemsPerPage).ceil();
        final currentPage = totalPages == 0
            ? 0
            : _currentPage.clamp(0, totalPages - 1).toInt();
        final start = currentPage * _itemsPerPage;
        final end = (start + _itemsPerPage)
            .clamp(0, filteredLogs.length)
            .toInt();
        final paginatedLogs = filteredLogs.sublist(start, end);

        if (logs.isEmpty) {
          return const EmptyState(title: 'No audit logs yet');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuditSummary(logs: logs),
            const SizedBox(height: 14),
            _AuditFilters(
              search: _search,
              category: _category,
              severity: _severity,
              actor: _actor,
              dateRange: _dateRange,
              actors: actors,
              onChanged: () => setState(() => _currentPage = 0),
              onCategoryChanged: (value) => setState(() {
                _category = value;
                _currentPage = 0;
              }),
              onSeverityChanged: (value) => setState(() {
                _severity = value;
                _currentPage = 0;
              }),
              onActorChanged: (value) => setState(() {
                _actor = value;
                _currentPage = 0;
              }),
              onDateRangeChanged: (value) => setState(() {
                _dateRange = value;
                _currentPage = 0;
              }),
            ),
            const SizedBox(height: 14),
            DataSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredLogs.isEmpty)
                    const EmptyState(title: 'No audit logs match the filters')
                  else
                    for (
                      var index = 0;
                      index < paginatedLogs.length;
                      index++
                    ) ...[
                      _AuditLogCard(log: paginatedLogs[index]),
                      if (index != paginatedLogs.length - 1)
                        const Divider(height: 20),
                    ],
                  const SizedBox(height: 12),
                  AdminTableFooter(
                    currentPage: currentPage,
                    totalItems: filteredLogs.length,
                    itemsPerPage: _itemsPerPage,
                    itemLabel: 'logs',
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
                        setState(() => _currentPage = page);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesFilters(_AuditLogEntry log) {
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty && !log.searchText.contains(query)) return false;
    if (_category != _all && log.category != _category) return false;
    if (_severity != _all && log.severity != _severity) return false;
    if (_actor != _all && log.actorName != _actor) return false;
    if (!_matchesDateRange(log.createdAt)) return false;
    return true;
  }

  bool _matchesDateRange(DateTime? createdAt) {
    if (_dateRange == _all) return true;
    if (createdAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_dateRange) {
      'Today' => !createdAt.isBefore(today),
      'Last 7 days' => createdAt.isAfter(now.subtract(const Duration(days: 7))),
      'Last 30 days' => createdAt.isAfter(
        now.subtract(const Duration(days: 30)),
      ),
      _ => true,
    };
  }
}

class _AuditFilters extends StatelessWidget {
  const _AuditFilters({
    required this.search,
    required this.category,
    required this.severity,
    required this.actor,
    required this.dateRange,
    required this.actors,
    required this.onChanged,
    required this.onCategoryChanged,
    required this.onSeverityChanged,
    required this.onActorChanged,
    required this.onDateRangeChanged,
  });

  final TextEditingController search;
  final String category;
  final String severity;
  final String actor;
  final String dateRange;
  final List<String> actors;
  final VoidCallback onChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onActorChanged;
  final ValueChanged<String> onDateRangeChanged;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filterWidth = constraints.maxWidth < 420
              ? constraints.maxWidth
              : 190.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText:
                        'Search action, actor, target, scanner, details...',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FilterDropdown(
                    width: filterWidth,
                    label: 'Category',
                    value: category,
                    values: const [
                      _AuditLogsListState._all,
                      'Security',
                      'Authentication',
                      'Attendance',
                      'Gate Pass',
                      'Users',
                      'Data Changes',
                      'Reports',
                      'System',
                      'Archive',
                    ],
                    onChanged: onCategoryChanged,
                  ),
                  _FilterDropdown(
                    width: filterWidth,
                    label: 'Severity',
                    value: severity,
                    values: const [
                      _AuditLogsListState._all,
                      'Security',
                      'Warning',
                      'Info',
                    ],
                    onChanged: onSeverityChanged,
                  ),
                  _FilterDropdown(
                    width: filterWidth,
                    label: 'Date',
                    value: dateRange,
                    values: const [
                      _AuditLogsListState._all,
                      'Today',
                      'Last 7 days',
                      'Last 30 days',
                    ],
                    onChanged: onDateRangeChanged,
                  ),
                  _FilterDropdown(
                    width: filterWidth,
                    label: 'Actor',
                    value: actor,
                    values: [_AuditLogsListState._all, ...actors],
                    onChanged: onActorChanged,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => onChanged(value ?? values.first),
      ),
    );
  }
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({required this.logs});

  final List<_AuditLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final security = logs.where((log) => log.severity == 'Security').length;
    final failedLogins = logs
        .where((log) => log.action.startsWith('failed_login'))
        .length;
    final attendance = logs
        .where(
          (log) => log.category == 'Attendance' || log.category == 'Gate Pass',
        )
        .length;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayCount = logs
        .where((log) => log.createdAt?.isAfter(todayStart) ?? false)
        .length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _AuditMetric(
          label: 'Security Alerts',
          value: '$security',
          icon: Icons.shield_outlined,
        ),
        _AuditMetric(
          label: 'Failed Logins',
          value: '$failedLogins',
          icon: Icons.password_outlined,
        ),
        _AuditMetric(
          label: 'Attendance Events',
          value: '$attendance',
          icon: Icons.fact_check_outlined,
        ),
        _AuditMetric(
          label: 'Today',
          value: '$todayCount',
          icon: Icons.today_outlined,
        ),
      ],
    );
  }
}

class _AuditMetric extends StatelessWidget {
  const _AuditMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: DataSurface(
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final _AuditLogEntry log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final icon = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _severityColor(log.severity).withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _categoryIcon(log.category),
              color: _severityColor(log.severity),
            ),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact
                          ? constraints.maxWidth - 54
                          : constraints.maxWidth - 240,
                    ),
                    child: Text(
                      log.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(label: log.category, type: _badgeType(log)),
                  StatusBadge(label: log.severity, type: _badgeType(log)),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Actor: '),
                    TextSpan(
                      text: log.actorName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (log.target.isNotEmpty) ...[
                      const TextSpan(text: '  Target: '),
                      TextSpan(
                        text: log.target,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
                maxLines: compact ? 4 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (log.metadataSummary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  log.metadataSummary,
                  maxLines: compact ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
              if (compact) ...[
                const SizedBox(height: 8),
                Text(
                  log.createdAt == null
                      ? '-'
                      : DateFormat(
                          'MMM d, yyyy hh:mm a',
                        ).format(log.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ],
          );

          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: content),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: content),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Text(
                  log.createdAt == null
                      ? '-'
                      : DateFormat(
                          'MMM d, yyyy\nhh:mm a',
                        ).format(log.createdAt!),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Security' => Icons.security_outlined,
      'Authentication' => Icons.login_outlined,
      'Attendance' => Icons.fact_check_outlined,
      'Gate Pass' => Icons.door_front_door_outlined,
      'Users' => Icons.manage_accounts_outlined,
      'Reports' => Icons.file_download_outlined,
      'Archive' => Icons.archive_outlined,
      'System' => Icons.settings_outlined,
      _ => Icons.history_outlined,
    };
  }

  Color _severityColor(String severity) {
    return switch (severity) {
      'Security' => Colors.red.shade700,
      'Warning' => Colors.orange.shade800,
      _ => Colors.green.shade700,
    };
  }

  String _badgeType(_AuditLogEntry log) {
    return switch (log.severity) {
      'Security' => 'late',
      'Warning' => 'disabled',
      _ => 'active',
    };
  }
}

class _AuditLogEntry {
  const _AuditLogEntry({
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.target,
    required this.metadata,
    required this.createdAt,
  });

  final String action;
  final String actorId;
  final String actorName;
  final String target;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory _AuditLogEntry.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    return _AuditLogEntry(
      action: data['action'] as String? ?? 'activity',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'Unknown',
      target: data['target'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  String get title => action
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  String get severity {
    if (action.contains('unauthorized') ||
        action.contains('failed_login') ||
        action.contains('blocked_login') ||
        action.contains('disabled_account') ||
        action.contains('rate_limited')) {
      return 'Security';
    }
    if (action.contains('failed') ||
        action.contains('duplicate') ||
        action.contains('restore') ||
        action.contains('delete')) {
      return 'Warning';
    }
    return 'Info';
  }

  String get category {
    if (severity == 'Security') return 'Security';
    if (action.contains('login') || action.contains('logout')) {
      return 'Authentication';
    }
    if (action.contains('attendance')) return 'Attendance';
    if (action.contains('gate_pass')) return 'Gate Pass';
    if (action.contains('user')) return 'Users';
    if (action.contains('export') || action.contains('report')) {
      return 'Reports';
    }
    if (action.contains('backup') || action.contains('restore')) {
      return 'System';
    }
    if (action.contains('settings')) return 'System';
    if (action.contains('archive') || action.contains('archived')) {
      return 'Archive';
    }
    return 'Data Changes';
  }

  String get metadataSummary {
    if (metadata.isEmpty) return '';
    final entries = metadata.entries
        .where((entry) => '${entry.value}'.trim().isNotEmpty)
        .map((entry) => '${_formatKey(entry.key)}: ${entry.value}')
        .take(6)
        .join('  |  ');
    return entries;
  }

  String get searchText => [
    action,
    title,
    actorId,
    actorName,
    target,
    category,
    severity,
    metadataSummary,
  ].join(' ').toLowerCase();

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
