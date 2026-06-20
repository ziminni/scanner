part of '../school_year_page.dart';

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
