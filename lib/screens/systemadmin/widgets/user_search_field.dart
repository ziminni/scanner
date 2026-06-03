part of '../user_management_page.dart';

class _UserSearchField extends StatelessWidget {
  const _UserSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DataSurface(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search users by name, email, role, or status',
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
