part of '../school_year_page.dart';

class _CardListSkeleton extends StatelessWidget {
  const _CardListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          const _CardSkeleton(),
        ],
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return DataSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Box(w: 44, h: 44, color: bg),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(w: 150, h: 22, color: bg),
                    const SizedBox(height: 6),
                    _Box(w: 190, h: 13, color: bg),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (var i = 0; i < 3; i++) _Box(w: 180, h: 54, color: bg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
