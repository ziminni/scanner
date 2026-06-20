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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Box(w: 150, h: 22, color: bg),
                  const SizedBox(height: 6),
                  _Box(w: 190, h: 13, color: bg),
                ],
              ),
            ),
            _Box(w: 200, h: 13, color: bg),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
