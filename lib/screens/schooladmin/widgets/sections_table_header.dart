part of '../sections_page.dart';

class _SectionsTableHeader extends StatelessWidget {
  const _SectionsTableHeader({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: value, tristate: true, onChanged: onChanged),
                const Text('Select all in this grade'),
              ],
            ),
          );
        }
        final style = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: value,
                  tristate: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: Text('SECTION', style: style)),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: Text('ADVISER', style: style)),
              const SizedBox(width: 18),
              SizedBox(width: 120, child: Text('STUDENTS', style: style)),
              const SizedBox(width: 88),
            ],
          ),
        );
      },
    );
  }
}
