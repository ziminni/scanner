part of '../school_year_page.dart';

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
