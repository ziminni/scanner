part of '../reports_export_page.dart';

class _TemplateDownloadCard extends StatelessWidget {
  const _TemplateDownloadCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.fileName,
    required this.assetPath,
  });

  final String title;
  final String description;
  final IconData icon;
  final String fileName;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 420,
      child: DataSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _downloadTemplate(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Template'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      downloadAsset(assetPath: assetPath, fileName: fileName);
      messenger.showSnackBar(SnackBar(content: Text('$title downloaded.')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download template: $error')),
      );
    }
  }
}
