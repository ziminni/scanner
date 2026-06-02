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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 520,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search users...',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (final user in users)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text(user.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(179))),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Role: ${user.role.label}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(179))),
                                      const SizedBox(width: 12),
                                      Text(
                                        user.lastLoginAt == null
                                            ? '-'
                                            : DateFormat('yyyy-MM-dd hh:mm').format(user.lastLoginAt!),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(179)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(
                                  label: user.status.label,
                                  type: user.status == AccountStatus.active ? 'active' : 'disabled',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: user.status == AccountStatus.active ? 'Disable account' : 'Enable account',
                                      icon: Icon(
                                        user.status == AccountStatus.active ? Icons.block_outlined : Icons.check_circle_outline,
                                      ),
                                      onPressed: () async {
                                        final nextStatus = user.status == AccountStatus.active ? AccountStatus.disabled : AccountStatus.active;
                                        await app.admin.setUserStatus(userId: user.id, status: nextStatus, actor: app.currentUser!);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete user profile',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await app.admin.deleteUserProfile(userId: user.id, actor: app.currentUser!);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
