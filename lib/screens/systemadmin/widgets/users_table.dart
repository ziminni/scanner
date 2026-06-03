part of '../user_management_page.dart';

class _UsersTable extends StatefulWidget {
  const _UsersTable();

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  final _search = TextEditingController();
  static const _roleOrder = [
    UserRole.systemAdministrator,
    UserRole.schoolAdministrator,
    UserRole.staffScanner,
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: app.repository.usersStream(),
      builder: (context, snapshot) {
        final query = _search.text.trim().toLowerCase();
        final allUsers = (snapshot.data?.docs ?? [])
            .map(AppUser.fromDoc)
            .toList();
        final filteredUsers = allUsers.where((user) {
          if (query.isEmpty) return true;
          return [
            user.fullName,
            user.email,
            user.role.label,
            user.status.label,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

        if (allUsers.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserSearchField(
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              EmptyState(
                title: query.isEmpty ? 'No users yet' : 'No users found',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserSearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (filteredUsers.isEmpty)
              const EmptyState(title: 'No users found')
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final sections = [
                    for (final role in _roleOrder)
                      _UserRoleSection(
                        role: role,
                        users: filteredUsers
                            .where((user) => user.role == role)
                            .toList(),
                        totalUsers: allUsers
                            .where((user) => user.role == role)
                            .length,
                        isFiltered: query.isNotEmpty,
                      ),
                  ];

                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < sections.length;
                          index++
                        ) ...[
                          sections[index],
                          if (index != sections.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < sections.length; index++) ...[
                        Expanded(child: sections[index]),
                        if (index != sections.length - 1)
                          const SizedBox(width: 14),
                      ],
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
