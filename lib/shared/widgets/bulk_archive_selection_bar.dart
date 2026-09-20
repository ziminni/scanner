import 'package:flutter/material.dart';

class BulkSelectionMenuItem {
  const BulkSelectionMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
}

class BulkArchiveSelectionBar extends StatelessWidget {
  const BulkArchiveSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onArchive,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    this.secondaryMenuItems = const [],
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onArchive;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final List<BulkSelectionMenuItem> secondaryMenuItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(45)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              if (secondaryActionLabel != null)
                _SecondaryActionButton(
                  label: secondaryActionLabel!,
                  icon: secondaryActionIcon ?? Icons.swap_horiz,
                  onPressed: onSecondaryAction,
                  menuItems: secondaryMenuItems,
                ),
              FilledButton.icon(
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive selected'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.menuItems,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<BulkSelectionMenuItem> menuItems;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return MenuAnchor(
      menuChildren: [
        for (final item in menuItems)
          MenuItemButton(
            leadingIcon: item.icon == null ? null : Icon(item.icon),
            onPressed: item.onPressed,
            child: Text(item.label),
          ),
      ],
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: Icon(icon),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
