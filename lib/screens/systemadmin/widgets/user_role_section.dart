part of '../user_management_page.dart';

class _UserRoleSection extends StatelessWidget {
  const _UserRoleSection({
    required this.role,
    required this.users,
    required this.totalUsers,
    required this.isFiltered,
  });

  final UserRole role;
  final List<AppUser> users;
  final int totalUsers;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = '$totalUsers/${role.userLimit}';

    return DataSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _roleIcon(role),
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _roleDescription(role),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(166),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: countLabel, type: 'active'),
            ],
          ),
          const SizedBox(height: 14),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isFiltered
                    ? 'No ${role.label.toLowerCase()} accounts match your search.'
                    : 'No ${role.label.toLowerCase()} accounts yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(166),
                ),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < users.length; index++) ...[
                  _UserCard(user: users[index]),
                  if (index != users.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.systemAdministrator => Icons.admin_panel_settings_outlined,
      UserRole.schoolAdministrator => Icons.school_outlined,
      UserRole.staffScanner => Icons.qr_code_scanner,
    };
  }

  String _roleDescription(UserRole role) {
    return switch (role) {
      UserRole.systemAdministrator =>
        'Full system access and administrative controls',
      UserRole.schoolAdministrator =>
        'School records, attendance, reports, and archives',
      UserRole.staffScanner =>
        'Mobile scanning access and scanner activity logs',
    };
  }
}
