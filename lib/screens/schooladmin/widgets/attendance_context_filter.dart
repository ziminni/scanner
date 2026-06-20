part of '../attendance_logs_page.dart';

class _AttendanceContextFilter extends StatelessWidget {
  const _AttendanceContextFilter({
    required this.tabIndex,
    required this.sectionValue,
    required this.scheduleValue,
    required this.onSectionChanged,
    required this.onScheduleChanged,
  });

  final int tabIndex;
  final String sectionValue;
  final String scheduleValue;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onScheduleChanged;

  @override
  Widget build(BuildContext context) {
    final app = SchoolAdminViewModelScope.of(context);
    if (tabIndex == 0) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: app.repository.activeSectionsStream(),
        builder: (context, snapshot) {
          final sections =
              snapshot.data?.docs
                  .map((doc) => (doc.data()['name'] as String? ?? '').trim())
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList()
                ?..sort();
          final options = sections ?? const <String>[];
          return _LogFilterSelect(
            label: 'Section',
            value: options.contains(sectionValue) ? sectionValue : '',
            options: options,
            onChanged: onSectionChanged,
          );
        },
      );
    }

    return FutureBuilder<SchoolYear?>(
      future: app.attendance.activeSchoolYear(),
      builder: (context, schoolYearSnapshot) {
        final schoolYear = schoolYearSnapshot.data;
        if (schoolYear == null) {
          return _LogFilterSelect(
            label: 'Schedule',
            value: '',
            options: const [],
            onChanged: onScheduleChanged,
          );
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: app.repository.activeTeachersStream(schoolYear.id),
          builder: (context, snapshot) {
            final schedules =
                snapshot.data?.docs
                    .map((doc) {
                      final data = doc.data();
                      final timeIn =
                          data['assignedTimeIn'] as String? ?? '07:00';
                      final timeOut =
                          data['assignedTimeOut'] as String? ?? '17:00';
                      return '$timeIn - $timeOut';
                    })
                    .where((schedule) => schedule.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ?..sort();
            final options = schedules ?? const <String>[];
            return _LogFilterSelect(
              label: 'Schedule',
              value: options.contains(scheduleValue) ? scheduleValue : '',
              options: options,
              onChanged: onScheduleChanged,
            );
          },
        );
      },
    );
  }
}
