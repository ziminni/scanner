part of '../login_screen.dart';

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MobileHeader(),
            const SizedBox(height: 28),
            _FormPane(state: state, scrollable: false),
          ],
        ),
      ),
    );
  }
}
