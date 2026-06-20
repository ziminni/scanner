part of '../teachers_page.dart';

class _TeachersFilterBar extends StatelessWidget {
  const _TeachersFilterBar({
    required this.search,
    required this.scheduleFilter,
    required this.genderFilter,
    required this.onSearchChanged,
    required this.onScheduleChanged,
    required this.onGenderChanged,
  });

  final TextEditingController search;
  final String scheduleFilter;
  final String genderFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onScheduleChanged;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final searchWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 352).clamp(320.0, 720.0).toDouble();
        return SizedBox(
          width: constraints.maxWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search teacher name, ID, or contact',
                  ),
                  onChanged: (_) => onSearchChanged(),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: scheduleFilter,
                  decoration: const InputDecoration(labelText: 'Schedule'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(
                      value: '07:00 - 16:00',
                      child: Text('07:00 - 16:00'),
                    ),
                    DropdownMenuItem(
                      value: '07:30 - 16:30',
                      child: Text('07:30 - 16:30'),
                    ),
                  ],
                  onChanged: (value) => onScheduleChanged(value ?? ''),
                ),
              ),
              SizedBox(
                width: 180,
                child: GenderDropdownField(
                  value: genderFilter,
                  includeAll: true,
                  onChanged: (value) => onGenderChanged(value ?? ''),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
