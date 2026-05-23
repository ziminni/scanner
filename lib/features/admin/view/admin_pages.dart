import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/app_controller.dart';
import '../../../models/enums.dart';
import '../../../models/models.dart';
import '../../../shared/widgets/app_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final firestore = app.firestore;
    final systemAdmin = user.role == UserRole.systemAdministrator;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisExtent: 104,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            if (systemAdmin)
              FirestoreCount(
                query: firestore.collection('users'),
                builder: (value) => MetricCard(
                  label: 'Total users',
                  value: value,
                  icon: Icons.people_alt_outlined,
                ),
              ),
            FirestoreCount(
              query: firestore
                  .collection('students')
                  .where('archived', isEqualTo: false),
              builder: (value) => MetricCard(
                label: 'Total students',
                value: value,
                icon: Icons.school_outlined,
              ),
            ),
            FirestoreCount(
              query: firestore
                  .collection('teachers')
                  .where('archived', isEqualTo: false),
              builder: (value) => MetricCard(
                label: 'Total teachers',
                value: value,
                icon: Icons.badge_outlined,
              ),
            ),
            FirestoreCount(
              query: firestore
                  .collection('users')
                  .where('role', isEqualTo: UserRole.staffScanner.key)
                  .where('status', isEqualTo: 'active'),
              builder: (value) => MetricCard(
                label: 'Active scanner users',
                value: value,
                icon: Icons.qr_code_scanner,
              ),
            ),
            if (!systemAdmin)
              FirestoreCount(
                query: firestore
                    .collection('attendance_logs')
                    .where(
                      'attendanceStatus',
                      isEqualTo: AttendanceStatus.late.name,
                    ),
                builder: (value) => MetricCard(
                  label: 'Late count',
                  value: value,
                  icon: Icons.schedule_outlined,
                ),
              ),
            if (!systemAdmin)
              FirestoreCount(
                query: firestore
                    .collection('attendance_logs')
                    .where(
                      'attendanceStatus',
                      isEqualTo: AttendanceStatus.absent.name,
                    ),
                builder: (value) => MetricCard(
                  label: 'Absent count',
                  value: value,
                  icon: Icons.person_off_outlined,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          systemAdmin ? 'Recent system activities' : 'Recent attendance logs',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        systemAdmin
            ? const AuditLogsList(limit: 8)
            : const AttendanceLogsTable(limit: 10),
      ],
    );
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'User Management',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add user'),
          onPressed: () async {
            final created = await showDialog<bool>(
              context: context,
              builder: (_) => const _AddUserDialog(),
            );
            if (created == true && mounted) {
              setState(() => _message = 'User account created.');
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Administrator can create one School Administrator and up to five Staff Scanner accounts.',
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
          const SizedBox(height: 16),
          const _UsersTable(),
        ],
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.staffScanner;
  AccountStatus _status = AccountStatus.active;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AlertDialog(
      title: const Text('Add user'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Full name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Valid email is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                ),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Minimum 6 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  for (final role in [
                    UserRole.schoolAdministrator,
                    UserRole.staffScanner,
                  ])
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Account status'),
                items: [
                  for (final status in AccountStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt),
          label: const Text('Create'),
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  try {
                    await app.admin.createUser(
                      email: _email.text,
                      password: _password.text,
                      fullName: _name.text,
                      role: _role,
                      status: _status,
                      actor: app.currentUser!,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (error) {
                    setState(() {
                      _saving = false;
                      _error = error.toString();
                    });
                  }
                },
        ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final users = (snapshot.data?.docs ?? []).map(AppUser.fromDoc).toList();
        if (users.isEmpty) {
          return const EmptyState(title: 'No users yet');
        }
        return _DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Full name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Last login')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final user in users)
                  DataRow(
                    cells: [
                      DataCell(Text(user.fullName)),
                      DataCell(Text(user.email)),
                      DataCell(Text(user.role.label)),
                      DataCell(Text(user.status.label)),
                      DataCell(
                        Text(
                          user.lastLoginAt == null
                              ? '-'
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(user.lastLoginAt!),
                        ),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: user.status == AccountStatus.active
                                  ? 'Disable account'
                                  : 'Enable account',
                              icon: Icon(
                                user.status == AccountStatus.active
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outline,
                              ),
                              onPressed: () async {
                                final nextStatus =
                                    user.status == AccountStatus.active
                                    ? AccountStatus.disabled
                                    : AccountStatus.active;
                                await app.admin.setUserStatus(
                                  userId: user.id,
                                  status: nextStatus,
                                  actor: app.currentUser!,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete user profile',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await app.admin.deleteUserProfile(
                                  userId: user.id,
                                  actor: app.currentUser!,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Page(title: 'Audit Logs', child: AuditLogsList(limit: 100));
}

class AuditLogsList extends StatelessWidget {
  const AuditLogsList({super.key, required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.firestore
          .collection('audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const EmptyState(title: 'No audit logs yet');
        return _DataSurface(
          child: Column(
            children: [
              for (final doc in docs)
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(doc.data()['action'] as String? ?? 'Activity'),
                  subtitle: Text(
                    '${doc.data()['actorName'] as String? ?? 'Unknown'} ${doc.data()['target'] as String? ?? ''}',
                  ),
                  trailing: TimestampText(doc.data()['createdAt']),
                ),
            ],
          ),
        );
      },
    );
  }
}

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
    return _Page(
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

class DatabaseManagementPage extends StatelessWidget {
  const DatabaseManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _Page(
      title: 'Database Management',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.backup_outlined),
          label: const Text('Backup database'),
          onPressed: () => app.admin.backupDatabase(app.currentUser!),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup records'),
          SizedBox(height: 12),
          _CollectionTable(
            collection: 'backups',
            columns: ['createdByName', 'status', 'counts'],
          ),
        ],
      ),
    );
  }
}

class ArchiveManagementPage extends StatelessWidget {
  const ArchiveManagementPage({super.key});

  @override
  Widget build(BuildContext context) => const _Page(
    title: 'Archives',
    child: _CollectionTable(
      collection: 'archives',
      columns: ['type', 'title', 'schoolYear', 'createdAt'],
    ),
  );
}

class ScannerUsersPage extends StatelessWidget {
  const ScannerUsersPage({super.key});

  @override
  Widget build(BuildContext context) => const _Page(
    title: 'Scanner Users',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollectionTable(
          collection: 'users',
          columns: ['fullName', 'email', 'status', 'lastLoginAt'],
        ),
        SizedBox(height: 20),
        Text('Scanner activity'),
        SizedBox(height: 8),
        AttendanceLogsTable(limit: 50),
      ],
    ),
  );
}

class SchoolYearPage extends StatefulWidget {
  const SchoolYearPage({super.key});

  @override
  State<SchoolYearPage> createState() => _SchoolYearPageState();
}

class _SchoolYearPageState extends State<SchoolYearPage> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _Page(
      title: 'School Year',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<SchoolYear?>(
            future: app.attendance.activeSchoolYear(),
            builder: (context, snapshot) {
              final active = snapshot.data;
              if (active != null) {
                return _DataSurface(
                  child: ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text('Active school year: ${active.name}'),
                    subtitle: Text(
                      'New school year creation is locked until the active year is archived.',
                    ),
                    trailing: FilledButton.icon(
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive'),
                      onPressed: () async {
                        await app.attendance.archiveSchoolYear(
                          active,
                          actorId: app.currentUser!.id,
                          actorName: app.currentUser!.fullName,
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                );
              }

              return _DataSurface(
                child: ListTile(
                  leading: const Icon(Icons.event_busy_outlined),
                  title: const Text('No active school year'),
                  subtitle: const Text(
                    'Create a school year to unlock students, teachers, sections, attendance, and scanner modules.',
                  ),
                  trailing: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create active school year'),
                    onPressed: () async {
                      final created = await showDialog<bool>(
                        context: context,
                        builder: (_) => const _CreateSchoolYearDialog(),
                      );
                      if (created == true && mounted) setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const _CollectionTable(
            collection: 'school_years',
            columns: [
              'name',
              'isActive',
              'archived',
              'term1Start',
              'term1End',
              'term2Start',
              'term2End',
              'term3Start',
              'term3End',
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateSchoolYearDialog extends StatefulWidget {
  const _CreateSchoolYearDialog();

  @override
  State<_CreateSchoolYearDialog> createState() =>
      _CreateSchoolYearDialogState();
}

class _CreateSchoolYearDialogState extends State<_CreateSchoolYearDialog> {
  final _yearStart = TextEditingController();
  final _yearEnd = TextEditingController();
  final _termStarts = List<DateTime?>.filled(3, null);
  final _termEnds = List<DateTime?>.filled(3, null);
  String? _message;
  final bool _saving = false;

  @override
  void dispose() {
    _yearStart.dispose();
    _yearEnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AlertDialog(
      title: const Text('Create active school year'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _yearStart,
                      decoration: const InputDecoration(
                        labelText: 'Start year',
                        hintText: '2026',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Text('-'),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _yearEnd,
                      decoration: const InputDecoration(
                        labelText: 'End year',
                        hintText: '2027',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    _DateButton(
                      label:
                          '${index + 1}${index == 0
                              ? 'st'
                              : index == 1
                              ? 'nd'
                              : 'rd'} Term Start',
                      value: _termStarts[index],
                      onPick: (date) =>
                          setState(() => _termStarts[index] = date),
                    ),
                    _DateButton(
                      label:
                          '${index + 1}${index == 0
                              ? 'st'
                              : index == 1
                              ? 'nd'
                              : 'rd'} Term End',
                      value: _termEnds[index],
                      onPick: (date) => setState(() => _termEnds[index] = date),
                    ),
                  ],
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create'),
          onPressed: _saving ? null : () => _createSchoolYear(app),
        ),
      ],
    );
  }

  Future<void> _createSchoolYear(AppController app) async {
    final start = int.tryParse(_yearStart.text.trim());
    final end = int.tryParse(_yearEnd.text.trim());
    if (start == null || end == null || end != start + 1) {
      setState(
        () => _message = 'Enter a valid school year, for example 2026 - 2027.',
      );
      return;
    }
    if (_termStarts.any((date) => date == null) ||
        _termEnds.any((date) => date == null)) {
      setState(
        () => _message = 'All three term start and end dates are required.',
      );
      return;
    }
    for (var index = 0; index < 3; index++) {
      if (_termEnds[index]!.isBefore(_termStarts[index]!)) {
        setState(
          () => _message =
              'Term ${index + 1} end date cannot be before its start date.',
        );
        return;
      }
      if (index > 0 && !_termStarts[index]!.isAfter(_termEnds[index - 1]!)) {
        setState(
          () =>
              _message = 'Term ${index + 1} must start after Term $index ends.',
        );
        return;
      }
    }

    final active = await app.attendance.activeSchoolYear();
    if (active != null) {
      setState(
        () => _message =
            'Archive the active school year before creating another one.',
      );
      return;
    }

    final name = '$start-$end';
    await app.firestore.collection('school_years').add({
      'name': name,
      'isActive': true,
      'archived': false,
      'term1Start': Timestamp.fromDate(_termStarts[0]!),
      'term1End': Timestamp.fromDate(_termEnds[0]!),
      'term2Start': Timestamp.fromDate(_termStarts[1]!),
      'term2End': Timestamp.fromDate(_termEnds[1]!),
      'term3Start': Timestamp.fromDate(_termStarts[2]!),
      'term3End': Timestamp.fromDate(_termEnds[2]!),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await app.audit.record(
      action: 'school_year_created',
      actorId: app.currentUser!.id,
      actorName: app.currentUser!.fullName,
      target: name,
    );
    if (mounted) Navigator.pop(context, true);
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          value == null ? label : DateFormat('MMM d, yyyy').format(value!),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPick(picked);
        },
      ),
    );
  }
}

class _BirthdateField extends StatelessWidget {
  const _BirthdateField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final today = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate:
              value ?? DateTime(today.year - 12, today.month, today.day),
          firstDate: DateTime(1900),
          lastDate: DateTime(today.year, today.month, today.day),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birthdate',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  tooltip: 'Clear birthdate',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : DateFormat('MMM d, yyyy').format(value!),
        ),
      ),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _controllers = {
    for (final field in _studentFields)
      if (field != 'section' && field != 'status')
        field: TextEditingController(),
  };
  String? _selectedSection;
  DateTime? _birthdate;
  String? _message;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _Page(
      title: 'Students',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.download_outlined),
          label: const Text('Template'),
          onPressed: () {},
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add student'),
          onPressed: _selectedSection == null
              ? null
              : () async {
                  final schoolYear = await app.attendance.activeSchoolYear();
                  if (schoolYear == null) {
                    setState(() {
                      _message =
                          'Create an active school year before adding students.';
                    });
                    return;
                  }
                  final data = {
                    for (final entry in _controllers.entries)
                      entry.key: entry.value.text.trim(),
                    'birthdate': _birthdate == null
                        ? null
                        : Timestamp.fromDate(_birthdate!),
                    'section': _selectedSection,
                    'status': 'Active',
                    'schoolYearId': schoolYear.id,
                    'schoolYear': schoolYear.name,
                    'archived': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  final doc = await app.firestore
                      .collection('students')
                      .add(data);
                  await app.firestore
                      .collection('school_years')
                      .doc(schoolYear.id)
                      .collection('students')
                      .doc(doc.id)
                      .set(data);
                  await app.audit.record(
                    action: 'students_created',
                    actorId: app.currentUser!.id,
                    actorName: app.currentUser!.fullName,
                    target: _controllers['lrn']?.text.trim() ?? '',
                    metadata: {'schoolYear': schoolYear.name},
                  );
                  setState(() => _message = null);
                },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: app.firestore
                .collection('sections')
                .where('archived', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final sectionNames =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => doc.data()['name'] as String? ?? '')
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

              if (_selectedSection != null &&
                  !sectionNames.contains(_selectedSection)) {
                _selectedSection = null;
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _controllers.entries)
                    SizedBox(
                      width: 220,
                      child: entry.key == 'birthdate'
                          ? _BirthdateField(
                              value: _birthdate,
                              onChanged: (date) =>
                                  setState(() => _birthdate = date),
                            )
                          : TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: _label(entry.key),
                              ),
                            ),
                    ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      hint: const Text('Select section'),
                      items: [
                        for (final section in sectionNames)
                          DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                      ],
                      onChanged: sectionNames.isEmpty
                          ? null
                          : (value) => setState(() => _selectedSection = value),
                    ),
                  ),
                  if (sectionNames.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Create a section first before adding students.',
                      ),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const _CollectionTable(
            collection: 'students',
            columns: _studentFields,
          ),
        ],
      ),
    );
  }
}

const _studentFields = [
  'lrn',
  'lastName',
  'firstName',
  'middleName',
  'birthdate',
  'address',
  'guardianName',
  'guardianContact',
  'section',
  'status',
];

class SectionsPage extends StatelessWidget {
  const SectionsPage({super.key});

  @override
  Widget build(BuildContext context) => const _CrudPage(
    title: 'Sections',
    collection: 'sections',
    fields: ['name', 'gradeLevel', 'adviser', 'status'],
  );
}

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) => const _CrudPage(
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

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Attendance Logs',
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search name, ID, section, scanner',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AttendanceLogsTable(limit: 200, search: _search.text),
        ],
      ),
    );
  }
}

class AttendanceLogsTable extends StatelessWidget {
  const AttendanceLogsTable({super.key, required this.limit, this.search = ''});

  final int limit;
  final String search;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.attendance.logsStream(limit: limit),
      builder: (context, snapshot) {
        final query = search.toLowerCase();
        final logs = (snapshot.data?.docs ?? [])
            .map(AttendanceLog.fromDoc)
            .where(
              (log) =>
                  query.isEmpty ||
                  '${log.personId} ${log.fullName} ${log.section} ${log.scannedBy}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        if (logs.isEmpty) {
          return const EmptyState(title: 'No attendance logs found');
        }
        return _DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Scanner')),
                DataColumn(label: Text('Sync')),
              ],
              rows: [
                for (final log in logs)
                  DataRow(
                    cells: [
                      DataCell(Text(log.personId)),
                      DataCell(Text(log.fullName)),
                      DataCell(Text(log.personRole.label)),
                      DataCell(Text(log.section)),
                      DataCell(Text('${log.dateKey} ${log.timeText}')),
                      DataCell(Text(log.attendanceType.label)),
                      DataCell(Text(log.attendanceStatus.label)),
                      DataCell(Text(log.scannedBy)),
                      DataCell(Text(log.syncStatus.label)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AttendanceStatusPage extends StatelessWidget {
  const AttendanceStatusPage({super.key});

  @override
  Widget build(BuildContext context) => const _Page(
    title: 'Attendance Status',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Late, absent, and incomplete attendance records'),
        SizedBox(height: 12),
        AttendanceLogsTable(limit: 200),
      ],
    ),
  );
}

class EarlyStudentsPage extends StatelessWidget {
  const EarlyStudentsPage({super.key});

  @override
  Widget build(BuildContext context) => const _Page(
    title: 'Early Students',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily, weekly, monthly, and per-term early rankings are derived from Early attendance logs and archived when a term ends.',
        ),
        SizedBox(height: 12),
        AttendanceLogsTable(limit: 200),
      ],
    ),
  );
}

class ReportsExportPage extends StatelessWidget {
  const ReportsExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _Page(
      title: 'Reports & Export',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Prepare Excel'),
          onPressed: () async {
            final docs = await app.firestore
                .collection('attendance_logs')
                .limit(500)
                .get();
            await app.admin.exportLogsExcel(
              docs.docs.map(AttendanceLog.fromDoc).toList(),
            );
            await app.audit.record(
              action: 'attendance_export_excel',
              actorId: app.currentUser!.id,
              actorName: app.currentUser!.fullName,
            );
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Prepare PDF'),
          onPressed: () async {
            final docs = await app.firestore
                .collection('attendance_logs')
                .limit(500)
                .get();
            await app.admin.exportLogsPdf(
              docs.docs.map(AttendanceLog.fromDoc).toList(),
            );
            await app.audit.record(
              action: 'attendance_export_pdf',
              actorId: app.currentUser!.id,
              actorName: app.currentUser!.fullName,
            );
          },
        ),
      ],
      child: const AttendanceLogsTable(limit: 200),
    );
  }
}

class _CrudPage extends StatefulWidget {
  const _CrudPage({
    required this.title,
    required this.collection,
    required this.fields,
  });

  final String title;
  final String collection;
  final List<String> fields;

  @override
  State<_CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<_CrudPage> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      if (field != 'status' && !_usesDropdown(field) && !_usesTimePicker(field))
        field: TextEditingController(),
  };
  DateTime? _birthdate;
  TimeOfDay? _assignedTimeIn;
  TimeOfDay? _assignedTimeOut;
  _TeacherOption? _selectedAdviser;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return _Page(
      title: widget.title,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.download_outlined),
          label: const Text('Template'),
          onPressed: () {},
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: () async {
            final data = {
              for (final entry in _controllers.entries)
                entry.key: entry.value.text.trim(),
              if (widget.fields.contains('birthdate'))
                'birthdate': _birthdate == null
                    ? null
                    : Timestamp.fromDate(_birthdate!),
              if (widget.fields.contains('adviser')) ...{
                'adviser': _selectedAdviser?.name ?? '',
                'adviserTeacherId': _selectedAdviser?.teacherId ?? '',
                'adviserDocId': _selectedAdviser?.docId ?? '',
              },
              if (widget.fields.contains('assignedTimeIn'))
                'assignedTimeIn': _timeToStorage(
                  _assignedTimeIn ?? const TimeOfDay(hour: 7, minute: 0),
                ),
              if (widget.fields.contains('assignedTimeOut'))
                'assignedTimeOut': _timeToStorage(
                  _assignedTimeOut ?? const TimeOfDay(hour: 17, minute: 0),
                ),
              if (widget.fields.contains('status')) 'status': 'Active',
              'archived': false,
              'createdAt': FieldValue.serverTimestamp(),
            };
            if (widget.collection == 'teachers') {
              final schoolYear = await app.attendance.activeSchoolYear();
              if (schoolYear == null) return;
              data['schoolYearId'] = schoolYear.id;
              data['schoolYear'] = schoolYear.name;
              final doc = await app.firestore
                  .collection(widget.collection)
                  .add(data);
              await app.firestore
                  .collection('school_years')
                  .doc(schoolYear.id)
                  .collection(widget.collection)
                  .doc(doc.id)
                  .set(data);
            } else {
              await app.firestore.collection(widget.collection).add(data);
            }
            await app.audit.record(
              action: '${widget.collection}_created',
              actorId: app.currentUser!.id,
              actorName: app.currentUser!.fullName,
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in _controllers.entries)
                SizedBox(width: 220, child: _fieldInput(entry)),
              if (widget.fields.contains('adviser'))
                SizedBox(
                  width: 220,
                  child: _AdviserDropdown(
                    selected: _selectedAdviser,
                    onChanged: (teacher) =>
                        setState(() => _selectedAdviser = teacher),
                  ),
                ),
              if (widget.fields.contains('assignedTimeIn'))
                SizedBox(
                  width: 220,
                  child: _TimePickerField(
                    label: 'Assigned Time In',
                    value: _assignedTimeIn,
                    fallback: const TimeOfDay(hour: 7, minute: 0),
                    onChanged: (time) => setState(() => _assignedTimeIn = time),
                  ),
                ),
              if (widget.fields.contains('assignedTimeOut'))
                SizedBox(
                  width: 220,
                  child: _TimePickerField(
                    label: 'Assigned Time Out',
                    value: _assignedTimeOut,
                    fallback: const TimeOfDay(hour: 17, minute: 0),
                    onChanged: (time) =>
                        setState(() => _assignedTimeOut = time),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _CollectionTable(
            collection: widget.collection,
            columns: widget.fields,
          ),
        ],
      ),
    );
  }

  bool _usesDropdown(String field) =>
      widget.collection == 'sections' && field == 'adviser';

  bool _usesTimePicker(String field) =>
      widget.collection == 'teachers' &&
      (field == 'assignedTimeIn' || field == 'assignedTimeOut');

  Widget _fieldInput(MapEntry<String, TextEditingController> entry) {
    if (entry.key == 'birthdate') {
      return _BirthdateField(
        value: _birthdate,
        onChanged: (date) => setState(() => _birthdate = date),
      );
    }
    return TextField(
      controller: entry.value,
      decoration: InputDecoration(labelText: _label(entry.key)),
    );
  }

  String _timeToStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.fallback,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay? value;
  final TimeOfDay fallback;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? fallback;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: displayValue,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '',
          suffixIcon: Icon(Icons.schedule_outlined),
        ).copyWith(labelText: label),
        child: Text(displayValue.format(context)),
      ),
    );
  }
}

class _TeacherOption {
  const _TeacherOption({
    required this.docId,
    required this.teacherId,
    required this.name,
  });

  final String docId;
  final String teacherId;
  final String name;
}

class _AdviserDropdown extends StatelessWidget {
  const _AdviserDropdown({required this.selected, required this.onChanged});

  final _TeacherOption? selected;
  final ValueChanged<_TeacherOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.firestore
          .collection('teachers')
          .where('archived', isEqualTo: false)
          .snapshots(),
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
          return _TeacherOption(
            docId: doc.id,
            teacherId: data['teacherId'] as String? ?? doc.id,
            name: name.isEmpty ? data['teacherId'] as String? ?? doc.id : name,
          );
        }).toList()..sort((a, b) => a.name.compareTo(b.name));

        final selectedTeacher = teachers.where((teacher) {
          return teacher.docId == selected?.docId;
        }).firstOrNull;

        return DropdownButtonFormField<_TeacherOption>(
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

class _CollectionTable extends StatelessWidget {
  const _CollectionTable({required this.collection, required this.columns});

  final String collection;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.firestore.collection(collection).limit(200).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return EmptyState(title: 'No $collection records yet');
        }
        return _DataSurface(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                for (final column in columns)
                  DataColumn(label: Text(_label(column))),
                const DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final doc in docs)
                  DataRow(
                    cells: [
                      for (final column in columns)
                        DataCell(Text(_formatValue(doc.data()[column]))),
                      DataCell(
                        IconButton(
                          tooltip: 'Archive',
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => app.admin.archiveRecord(
                            collection,
                            doc.id,
                            app.currentUser!,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _DataSurface extends StatelessWidget {
  const _DataSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

String _label(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String _formatValue(Object? value) {
  if (value == null) {
    return '-';
  }
  if (value is Timestamp) {
    return DateFormat('MMM d, yyyy').format(value.toDate());
  }
  return value.toString();
}
