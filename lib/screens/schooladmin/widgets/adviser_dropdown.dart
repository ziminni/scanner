part of '../sections_page.dart';

class _AdviserDropdown extends StatelessWidget {
  const _AdviserDropdown({required this.selected, required this.onChanged});

  final TeacherOption? selected;
  final ValueChanged<TeacherOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: (() async* {
        final schoolYear = await app.attendance.activeSchoolYear();
        if (schoolYear == null) return;
        yield* app.repository.activeTeachersStream(schoolYear.id);
      })(),
      builder: (context, snapshot) {
        final teachers = (snapshot.data?.docs ?? []).map((doc) {
          final data = doc.data();
          final firstName = data['firstName'] as String? ?? '';
          final middleName = data['middleName'] as String? ?? '';
          final lastName = data['lastName'] as String? ?? '';
          final name = [
            lastName,
            firstName,
            middleName,
          ].where((part) => part.trim().isNotEmpty).join(', ');
          return TeacherOption(
            docId: doc.id,
            teacherId: data['teacherId'] as String? ?? doc.id,
            name: name.isEmpty ? data['teacherId'] as String? ?? doc.id : name,
          );
        }).toList()..sort((a, b) => a.name.compareTo(b.name));

        final selectedTeacher = teachers.where((teacher) {
          return teacher.docId == selected?.docId;
        }).firstOrNull;

        return DropdownButtonFormField<TeacherOption>(
          initialValue: selectedTeacher,
          decoration: const InputDecoration(labelText: 'Adviser'),
          hint: const Text('Select teacher'),
          items: [
            for (final teacher in teachers)
              DropdownMenuItem(value: teacher, child: Text(teacher.name)),
          ],
          onChanged: teachers.isEmpty ? null : onChanged,
        );
      },
    );
  }
}
