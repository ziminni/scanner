import 'package:flutter/material.dart';

import '../../core/services/app_controller.dart';
import '../../models/models.dart';
import '../../shared/widgets/admin_widgets.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final _timeIn = TextEditingController(text: '07:00');
  final _timeOut = TextEditingController(text: '17:00');
  final _early = TextEditingController(text: '15');
  final _duplicate = TextEditingController(text: '240');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AdminPage(
      title: 'System Settings',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
          onPressed: () async {
            await app.attendance.updateSettings(
              SystemSettings(
                studentTimeIn: _timeIn.text,
                studentTimeOut: _timeOut.text,
                earlyBeforeMinutes: int.tryParse(_early.text) ?? 15,
                duplicateWindowMinutes: int.tryParse(_duplicate.text) ?? 240,
              ),
              app.currentUser!,
            );
          },
        ),
      ],
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 180,
            child: TextField(
              controller: _timeIn,
              decoration: const InputDecoration(labelText: 'Student time in'),
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _timeOut,
              decoration: const InputDecoration(labelText: 'Student time out'),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _early,
              decoration: const InputDecoration(
                labelText: 'Early threshold minutes',
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: TextField(
              controller: _duplicate,
              decoration: const InputDecoration(
                labelText: 'Duplicate window minutes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
