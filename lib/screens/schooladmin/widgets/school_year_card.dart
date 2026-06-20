part of '../school_year_page.dart';

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
