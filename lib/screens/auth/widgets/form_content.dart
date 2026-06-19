part of '../login_screen.dart';

class _FormContent extends StatelessWidget {
  const _FormContent({required this.state});

  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'WELCOME BACK',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: AppColors.adminAccent,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to the attendance system',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.adminText,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use the email and password assigned to your administrator or scanner account.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.adminSidebarMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _LoginCard(state: state),
        const SizedBox(height: 14),
        const Text(
          'Having trouble? Contact the system administrator or school IT office.',
          style: TextStyle(fontSize: 11, color: AppColors.adminSidebarMuted),
        ),
      ],
    );
  }
}
