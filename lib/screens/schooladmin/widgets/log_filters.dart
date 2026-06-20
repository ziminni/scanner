part of '../attendance_logs_page.dart';

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.search,
    required this.searchLabel,
    required this.filters,
    required this.onSearchChanged,
  });

  final TextEditingController search;
  final String searchLabel;
  final List<Widget> filters;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filterWidth = filters.length * 172;
        final searchWidth = (constraints.maxWidth - filterWidth - 12)
            .clamp(360.0, 720.0)
            .toDouble();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: searchLabel,
                ),
                onChanged: (_) => onSearchChanged(),
              ),
            ),
            ...filters,
          ],
        );
      },
    );
  }
}
