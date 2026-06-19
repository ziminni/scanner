import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/colors.dart';
import '../../core/services/app_controller.dart';

part 'widgets/feature_card.dart';
part 'widgets/field_label.dart';
part 'widgets/form_content.dart';
part 'widgets/form_pane.dart';
part 'widgets/login_card.dart';
part 'widgets/mobile_header.dart';
part 'widgets/narrow_layout.dart';
part 'widgets/sidebar.dart';
part 'widgets/sidebar_header.dart';
part 'widgets/wide_layout.dart';

// ---------------------------------------------------------------------------
// LoginScreen
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _busy = false;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleRememberDevice() {
    setState(() => _rememberDevice = !_rememberDevice);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(
        context,
      ).login(_loginCtrl.text.trim(), _passwordCtrl.text);
    } catch (_) {
      // AppController stores the friendly auth error for the UI.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: isWide ? _WideLayout(state: this) : _NarrowLayout(state: this),
    );
  }
}
