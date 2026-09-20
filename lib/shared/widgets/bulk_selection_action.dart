import 'package:flutter/material.dart';

class BulkSelectionAction {
  const BulkSelectionAction({
    required this.label,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Future<bool> Function(List<String> docIds) onSelected;
}
