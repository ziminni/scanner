import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/services/app_controller.dart';
import 'viewmodels/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final LoginViewModel _viewModel;
  bool _viewModelReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModelReady) return;
    _viewModel = LoginViewModel(AppScope.of(context));
    _viewModelReady = true;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.adminBackground,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _LoginFormPanel(
                      formKey: _formKey,
                      email: _email,
                      password: _password,
                      viewModel: _viewModel,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.email,
    required this.password,
    required this.viewModel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final compactWidth = size.width < 420;
    final compactHeight = size.height < 680;
    final outerPadding = EdgeInsets.symmetric(
      horizontal: compactWidth ? 14 : 24,
      vertical: compactHeight ? 18 : 32,
    );
    final panelPadding = EdgeInsets.all(compactWidth ? 18 : 28);
    final logoSize = compactHeight || compactWidth ? 58.0 : 74.0;
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      fontSize: compactWidth ? 21 : null,
      height: 1.12,
    );

    return Padding(
      padding: outerPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: panelPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compactWidth ? 16 : 20),
              border: Border.all(color: AppColors.adminBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adminSidebar.withAlpha(18),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: _LogoMark(size: logoSize),
                    ),
                    SizedBox(height: compactHeight ? 14 : 20),
                    Text(
                      'School Attendance Monitoring',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your assigned account to continue.',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.adminText.withAlpha(170),
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: compactHeight ? 20 : 26),
                    TextFormField(
                      controller: email,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || !value.trim().contains('@')
                          ? 'Enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      autofillHints: const [AutofillHints.password],
                      obscureText: viewModel.obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: viewModel.obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            viewModel.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: viewModel.togglePasswordVisibility,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters.'
                          : null,
                    ),
                    if (viewModel.authError != null) ...[
                      const SizedBox(height: 14),
                      _LoginError(message: viewModel.authError!),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        icon: viewModel.busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(viewModel.busy ? 'Signing in' : 'Login'),
                        ),
                        onPressed: viewModel.busy ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    try {
      await viewModel.login(email.text.trim(), password.text);
    } catch (_) {}
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/img/logo.jpg', fit: BoxFit.cover),
      ),
    );
  }
}
