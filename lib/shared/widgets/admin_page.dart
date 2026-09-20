import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.titleTrailing,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final hasToolbar = titleTrailing != null || actions.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasToolbar) ...[
          Semantics(
            label: '$title page actions',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (titleTrailing case final trailing?)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: trailing,
                    ),
                  )
                else
                  const Spacer(),
                if (actions.isNotEmpty)
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
          ),
          const SizedBox(height: 18),
        ],
        child,
      ],
    );
  }
}
