part of '../login_screen.dart';

class _FormPane extends StatelessWidget {
  const _FormPane({required this.state, this.scrollable = true});

  final _LoginScreenState state;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final inner = _FormContent(state: state);
    if (!scrollable) return inner;
    return Container(
      color: AppColors.adminBackground,
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: inner,
          ),
        ),
      ),
    );
  }
}
