part of '../user_management_page.dart';

class _UsersTable extends StatelessWidget {
  const _UsersTable();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.usersStream(),
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
