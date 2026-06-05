part of '../login_screen.dart';

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.state});

  final _LoginScreenState state;

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.adminSidebarMuted,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 19,
        color: AppColors.adminSidebarMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.adminBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.adminAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE24B4A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final busy = state._busy;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminSidebar.withAlpha(22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: state._formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel(label: 'Email address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: state._loginCtrl,
                autofillHints: const [AutofillHints.email],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hint: 'name@school.edu.ph',
                  prefixIcon: Icons.mail_outline,
                ),
                validator: (v) => (v == null || !v.trim().contains('@'))
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _FieldLabel(label: 'Password'),
                  GestureDetector(
                    onTap: () {
                      // TODO: navigate to forgot password
                    },
                    child: const Text(
                      'Need help?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.adminAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: state._passwordCtrl,
                autofillHints: const [AutofillHints.password],
                obscureText: state._obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => state._submit(),
                decoration:
                    _inputDecoration(
                      hint: 'password',
                      prefixIcon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: state._obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          state._obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.adminSidebarMuted,
                        ),
                        onPressed: state._togglePasswordVisibility,
                      ),
                    ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters.'
                    : null,
              ),
              const SizedBox(height: 14),
              if (app.authError != null) ...[
                Text(
                  app.authError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              GestureDetector(
                onTap: state._toggleRememberDevice,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: state._rememberDevice
                            ? AppColors.adminAccent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: state._rememberDevice
                              ? AppColors.adminAccent
                              : AppColors.adminBorder,
                        ),
                      ),
                      child: state._rememberDevice
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Keep me signed in on this device',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.adminSidebarMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _LoginSubmitButton(busy: busy, onPressed: state._submit),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.adminBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Authorized users only',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.adminSidebarMuted,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.adminBorder)),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.adminSidebarMuted,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Accounts are created by the System Administrator. ',
                      ),
                      const TextSpan(
                        text: 'Ask your school admin if you need access.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.adminAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginSubmitButton extends StatelessWidget {
  const _LoginSubmitButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: busy
          ? AppColors.adminAccent.withAlpha(150)
          : AppColors.adminAccent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: busy ? null : onPressed,
        child: SizedBox(
          height: 46,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: busy
                  ? const SizedBox(
                      key: ValueKey('busy'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign in',
                      key: ValueKey('label'),
                      style: TextStyle(
                        inherit: false,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        fontFamily: 'Roboto',
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
