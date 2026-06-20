import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
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
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}
