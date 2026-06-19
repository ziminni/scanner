part of '../user_management_page.dart';

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage =
        user.role == UserRole.schoolAdministrator ||
        user.role == UserRole.staffScanner;
    final lastLogin = user.lastLoginAt == null
        ? 'Last login: -'
        : 'Last login: ${DateFormat('MMM d, yyyy hh:mm a').format(user.lastLoginAt!)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showUserDetails(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.onSurface.withAlpha(15),
            ),
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
                  if (canManage) ...[
                    const Spacer(),
                    IconButton(
                      tooltip: user.status == AccountStatus.active
                          ? 'Disable user'
                          : 'Enable user',
                      icon: Icon(
                        user.status == AccountStatus.active
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 20,
                      ),
                      color: user.status == AccountStatus.active
                          ? theme.colorScheme.onSurface.withAlpha(166)
                          : theme.colorScheme.primary,
                      onPressed: () => _confirmStatusChange(context),
                    ),
                    IconButton(
                      tooltip: 'Delete user',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUserDetails(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _UserDetailsDialog(user: user),
    );
  }

  Future<void> _confirmStatusChange(BuildContext context) async {
    final app = AppScope.of(context);
    final actor = app.currentUser;
    if (actor == null) return;

    final nextStatus = user.status == AccountStatus.active
        ? AccountStatus.disabled
        : AccountStatus.active;
    final action = nextStatus == AccountStatus.disabled ? 'disable' : 'enable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} user?'),
        content: Text('Are you sure you want to $action ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              nextStatus == AccountStatus.disabled ? 'Disable' : 'Enable',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await app.admin.setUserStatus(
        userId: user.id,
        status: nextStatus,
        actor: actor,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} ${nextStatus.label.toLowerCase()}.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final app = AppScope.of(context);
    final actor = app.currentUser;
    if (actor == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This will remove ${user.fullName} from User Management. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await app.admin.deleteUserProfile(userId: user.id, actor: actor);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${user.fullName} deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return message.replaceFirst('Exception: ', '');
  }
}

class _UserDetailsDialog extends StatefulWidget {
  const _UserDetailsDialog({required this.user});

  final AppUser user;

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
  bool _sendingReset = false;

  bool get _canChangePassword =>
      widget.user.role == UserRole.schoolAdministrator ||
      widget.user.role == UserRole.staffScanner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 620 ? screenWidth - 48 : 520.0;
    return AlertDialog(
      title: const Text('User details'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReadOnlyUserField(
              label: 'Name',
              value: widget.user.fullName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _ReadOnlyUserField(
              label: 'Email',
              value: widget.user.email,
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 12),
            _ReadOnlyUserField(
              label: 'Role',
              value: widget.user.role.label,
              icon: Icons.admin_panel_settings_outlined,
            ),
            if (_canChangePassword) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _sendingReset
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.password_outlined),
                  label: const Text('Send password reset email'),
                  onPressed: _sendingReset ? null : _sendPasswordReset,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Firebase will email password reset instructions to ${widget.user.email}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(166),
                ),
              ),
            ] else ...[
              const SizedBox(height: 18),
              Text(
                'Password changes are only available for School Administrator and Staff Scanner accounts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(166),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _sendPasswordReset() async {
    final app = AppScope.of(context);
    final actor = app.currentUser;
    if (actor == null) return;

    setState(() => _sendingReset = true);
    try {
      await app.admin.sendPasswordResetForUser(user: widget.user, actor: actor);
      if (!mounted) return;
      _showMessage('Password reset email sent to ${widget.user.email}.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyUserManagementError(error));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadOnlyUserField extends StatelessWidget {
  const _ReadOnlyUserField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyUserManagementError(Object error) {
  final message = error.toString().replaceFirst('Bad state: ', '');
  return message.replaceFirst('Exception: ', '');
}
