import 'package:flutter/material.dart';

class AdminPaginationControls extends StatelessWidget {
  const AdminPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
          tooltip: 'First page',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          tooltip: 'Previous page',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${currentPage + 1} of $totalPages'),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage + 1 < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          tooltip: 'Next page',
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: currentPage + 1 < totalPages
              ? () => onPageChanged(totalPages - 1)
              : null,
          tooltip: 'Last page',
        ),
      ],
    );
  }
}
