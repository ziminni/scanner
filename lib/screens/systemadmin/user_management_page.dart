import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/app_controller.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/admin_widgets.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
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
        return DataSurface(
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
