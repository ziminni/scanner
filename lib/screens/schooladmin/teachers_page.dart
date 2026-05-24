import 'package:flutter/material.dart';

import '../../shared/widgets/crud_page.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) => const CrudPage(
    title: 'Teachers',
    collection: 'teachers',
    fields: [
      'teacherId',
      'lastName',
      'firstName',
      'middleName',
      'birthdate',
      'address',
      'contactNumber',
      'assignedTimeIn',
      'assignedTimeOut',
      'status',
    ],
  );
}
