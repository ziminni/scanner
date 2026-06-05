part of '../login_screen.dart';

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _Sidebar()),
        Expanded(flex: 3, child: _FormPane(state: state)),
      ],
    );
  }
}
