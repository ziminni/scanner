part of '../attendance_logs_page.dart';

class _LogFilterSelect extends StatelessWidget {
  const _LogFilterSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('All', overflow: TextOverflow.ellipsis),
          ),
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}
