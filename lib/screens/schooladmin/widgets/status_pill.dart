part of '../school_year_page.dart';

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
