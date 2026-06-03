part of '../user_management_page.dart';

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final lastLogin = user.lastLoginAt == null
        ? 'Last login: -'
        : 'Last login: ${DateFormat('MMM d, yyyy hh:mm a').format(user.lastLoginAt!)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lastLogin,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(
                label: user.status.label,
                type: user.status == AccountStatus.active
                    ? 'active'
                    : 'disabled',
              ),
              const Spacer(),
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
                  final nextStatus = user.status == AccountStatus.active
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
        ],
      ),
    );
  }
}
