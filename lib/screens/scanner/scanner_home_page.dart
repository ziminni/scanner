import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_controller.dart';
import '../../routes/app_routes.dart';
import 'scanner_theme.dart';
import 'viewmodels/scanner_home_viewmodel.dart';
import 'widgets/home_leaderboard.dart';

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  ScannerHomeViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) return;
    _viewModel = ScannerHomeViewModel(AppScope.of(context))..load();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser!;
    final theme = Theme.of(context);

    return ColoredBox(
      color: ScannerTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ScannerTheme.panelDecoration(
              color: ScannerTheme.surfaceSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.fullName}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: ScannerTheme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this scanner module to record student and teacher Time In and Time Out attendance.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ScannerTheme.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _viewModel!,
            builder: (context, _) {
              final viewModel = _viewModel!;
              if (viewModel.busy) {
                return Container(
                  height: 220,
                  decoration: ScannerTheme.panelDecoration(),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (viewModel.error != null) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: ScannerTheme.panelDecoration(),
                  child: Text(
                    viewModel.error!,
                    style: const TextStyle(color: ScannerTheme.text),
                  ),
                );
              }
              return HomeLeaderboard(viewModel: viewModel);
            },
          ),
          const SizedBox(height: 20),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 150,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            children: [
              _ScannerHomeActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Start Scanning',
                description: 'Open the ID scanner and record attendance.',
                buttonLabel: 'Open Scanner',
                onPressed: () => context.go(AppRoutes.scannerPath),
              ),
              _ScannerHomeActionCard(
                icon: Icons.list_alt_outlined,
                title: 'Attendance Logs',
                description: 'Review recent scanned attendance records.',
                buttonLabel: 'View Logs',
                onPressed: () => context.go(AppRoutes.logsPath),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerHomeActionCard extends StatelessWidget {
  const _ScannerHomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ScannerTheme.primary),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ScannerTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: Text(description)),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}
