import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';

class GenderDropdownField extends StatelessWidget {
  const GenderDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.includeAll = false,
    this.label = 'Gender',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool includeAll;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = PersonGender.fromValue(value)?.label;
    final selected = includeAll ? (normalized ?? '') : normalized;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.people_outline),
      ),
      hint: includeAll ? null : const Text('Select gender'),
      items: [
        if (includeAll)
          const DropdownMenuItem(value: '', child: Text('All genders')),
        for (final gender in PersonGender.values)
          DropdownMenuItem(value: gender.label, child: Text(gender.label)),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
