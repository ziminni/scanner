import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import 'viewmodels/create_school_year_viewmodel.dart';
import 'viewmodels/school_year_viewmodel.dart';

part 'widgets/create_school_year_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status enum derived from Firestore fields
// ─────────────────────────────────────────────────────────────────────────────

enum _SYStatus { active, completed, inactive }

extension _SYStatusX on SchoolYear {
  _SYStatus get displayStatus {
    if (isActive && !archived) return _SYStatus.active;
    if (archived) return _SYStatus.completed;
    return _SYStatus.inactive;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SchoolYearPage extends StatefulWidget {
  const SchoolYearPage({super.key});

  @override
  State<SchoolYearPage> createState() => _SchoolYearPageState();
}

class _SchoolYearPageState extends State<SchoolYearPage> {
  late final SchoolYearViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = SchoolYearViewModel(AppScope.of(context));
    _viewModelReady = true;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AdminPage(
          title: 'School Year',
          actions: [
            FutureBuilder<SchoolYear?>(
              future: _viewModel.activeSchoolYear(),
              builder: (context, snapshot) {
                // Only show the Create button when there is no active year
                if (snapshot.data != null) return const SizedBox.shrink();
                return FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create school year'),
                  onPressed: () async {
                    final created = await showDialog<bool>(
                      context: context,
                      builder: (_) => const CreateSchoolYearDialog(),
                    );
                    if (created == true && mounted) setState(() {});
                  },
                );
              },
            ),
          ],
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.repository
                .rootCollection('school_years')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _CardListSkeleton();
              }

              final schoolYears =
                  (snapshot.data?.docs ?? []).map(SchoolYear.fromDoc).toList()
                    ..sort(_sortDescending);

              if (schoolYears.isEmpty) {
                return const EmptyState(
                  title: 'No school years yet',
                  subtitle:
                      'Create a school year to start tracking attendance.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schoolYears.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sy = schoolYears[index];
                  return _SchoolYearCard(
                    schoolYear: sy,
                    onArchive: sy.isActive
                        ? () async {
                            await _viewModel.archiveActive(sy);
                            if (mounted) setState(() {});
                          }
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  static int _sortDescending(SchoolYear a, SchoolYear b) {
    if (a.isActive && !b.isActive) return -1;
    if (!a.isActive && b.isActive) return 1;
    final aEnd = a.finalTermEnd ?? DateTime(0);
    final bEnd = b.finalTermEnd ?? DateTime(0);
    final cmp = bEnd.compareTo(aEnd);
    if (cmp != 0) return cmp;
    return b.name.compareTo(a.name);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic accordion card — active, completed, or inactive
// ─────────────────────────────────────────────────────────────────────────────

class _SchoolYearCard extends StatefulWidget {
  const _SchoolYearCard({required this.schoolYear, this.onArchive});

  final SchoolYear schoolYear;
  final VoidCallback? onArchive;

  @override
  State<_SchoolYearCard> createState() => _SchoolYearCardState();
}

class _SchoolYearCardState extends State<_SchoolYearCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _chevron;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _chevron = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final sy = widget.schoolYear;
    final theme = Theme.of(context);

    return DataSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Collapsed header ───────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left — name + optional "Active" badge + date range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sy.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (sy.isActive) ...[
                              const SizedBox(width: 10),
                              const _YellowBadge(label: 'Active'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateRange(sy),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right — status pill + counts
                  _SchoolYearMeta(schoolYear: sy),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _chevron,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable details ─────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? _SchoolYearDetails(
                    schoolYear: sy,
                    onArchive: widget.onArchive,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _dateRange(SchoolYear sy) {
    final start = sy.termStarts.whereType<DateTime>().firstOrNull;
    final end = sy.termEnds.whereType<DateTime>().lastOrNull;
    if (start == null && end == null) return 'Date range not set';
    final fmt = DateFormat('yyyy-MM-dd');
    final s = start == null ? '—' : fmt.format(start);
    final e = end == null ? '—' : fmt.format(end);
    return '$s — $e';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right-side: status pill + enrollment / section counts
// ─────────────────────────────────────────────────────────────────────────────

class _SchoolYearMeta extends StatelessWidget {
  const _SchoolYearMeta({required this.schoolYear});

  final SchoolYear schoolYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppScope.of(context);

    return FutureBuilder<_SYCounts>(
      future: _SYCounts.load(app, schoolYear.id),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusPill(status: schoolYear.displayStatus),
            const SizedBox(width: 10),
            if (counts == null)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                '${counts.enrollments} enrollments · ${counts.sections} sections',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded content: term chips + contextual action
// ─────────────────────────────────────────────────────────────────────────────

class _SchoolYearDetails extends StatelessWidget {
  const _SchoolYearDetails({required this.schoolYear, this.onArchive});

  final SchoolYear schoolYear;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terms = [
      (label: '1st Term', start: _fmt(0, true), end: _fmt(0, false)),
      (label: '2nd Term', start: _fmt(1, true), end: _fmt(1, false)),
      (label: '3rd Term', start: _fmt(2, true), end: _fmt(2, false)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERM SCHEDULE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final t in terms)
                    _TermChip(label: t.label, start: t.start, end: t.end),
                ],
              ),
              // Archive action — only for the active school year
              if (onArchive != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'New school year creation is locked until this year is archived.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text('Archive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: () => _confirmArchive(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _fmt(int index, bool start) {
    final list = start ? schoolYear.termStarts : schoolYear.termEnds;
    final date = list.length > index ? list[index] : null;
    if (date == null) return null;
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive school year?'),
        content: Text(
          'This will mark ${schoolYear.name} as archived and allow you to create a new active school year.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) onArchive?.call();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _SYStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      _SYStatus.active => (
        const Color(0xFF03913F).withAlpha(28),
        const Color(0xFF03913F),
        'active',
      ),
      _SYStatus.completed => (
        const Color(0xFF6B7FD4).withAlpha(28),
        const Color(0xFF4A5BA8),
        'completed',
      ),
      _SYStatus.inactive => (
        Colors.grey.withAlpha(28),
        Colors.grey.shade700,
        'inactive',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _YellowBadge extends StatelessWidget {
  const _YellowBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5D3A00),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  const _TermChip({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final String? start;
  final String? end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (start != null && end != null) ? '$start – $end' : 'Dates not set',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _CardListSkeleton extends StatelessWidget {
  const _CardListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          const _CardSkeleton(),
        ],
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Box(w: 150, h: 22, color: bg),
                  const SizedBox(height: 6),
                  _Box(w: 190, h: 13, color: bg),
                ],
              ),
            ),
            _Box(w: 200, h: 13, color: bg),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.w, required this.h, required this.color});
  final double w, h;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore count helper
// ─────────────────────────────────────────────────────────────────────────────

class _SYCounts {
  const _SYCounts({required this.enrollments, required this.sections});

  final int enrollments;
  final int sections;

  static Future<_SYCounts> load(AppController app, String schoolYearId) async {
    final results = await Future.wait([
      app.repository
          .schoolYearCollection(schoolYearId, 'students')
          .where('archived', isEqualTo: false)
          .count()
          .get(),
      app.repository
          .rootCollection('sections')
          .where('archived', isEqualTo: false)
          .count()
          .get(),
    ]);
    return _SYCounts(
      enrollments: results[0].count ?? 0,
      sections: results[1].count ?? 0,
    );
  }
}
