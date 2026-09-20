part of '../sections_page.dart';

class _SectionToolbar extends StatelessWidget {
  const _SectionToolbar({
    required this.selectedCount,
    required this.busy,
    required this.onAdd,
    required this.onEdit,
    required this.onDownload,
    required this.onDelete,
  });

  final int selectedCount;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedCount > 0;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (hasSelection)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '$selectedCount section${selectedCount == 1 ? '' : 's'} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onEdit != null)
            OutlinedButton.icon(
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Section'),
            ),
          Opacity(
            opacity: hasSelection && !busy ? 1 : .42,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withAlpha(100)),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Section'),
            ),
          ),
          Opacity(
            opacity: hasSelection && !busy ? 1 : .42,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onDownload,
              icon: const Icon(Icons.qr_code_2_outlined, size: 18),
              label: const Text('Download QR'),
            ),
          ),
          FilledButton.icon(
            onPressed: busy ? null : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Section'),
          ),
        ],
      ),
    );
  }
}
