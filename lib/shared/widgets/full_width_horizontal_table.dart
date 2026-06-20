import 'package:flutter/material.dart';

class FullWidthHorizontalTable extends StatefulWidget {
  const FullWidthHorizontalTable({super.key, required this.child});

  final Widget child;

  @override
  State<FullWidthHorizontalTable> createState() =>
      _FullWidthHorizontalTableState();
}

class _FullWidthHorizontalTableState extends State<FullWidthHorizontalTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
