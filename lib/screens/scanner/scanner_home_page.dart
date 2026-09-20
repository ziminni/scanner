import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_controller.dart';
import '../../routes/app_routes.dart';
import 'scanner_theme.dart';
import 'viewmodels/scanner_home_viewmodel.dart';
import 'widgets/home_leaderboard.dart';
import 'widgets/home_sync_status.dart';

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
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: ScannerTheme.heroDecoration(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final iconSize = compact ? 40.0 : 54.0;
                final iconRadius = compact ? 13.0 : 17.0;

                final title = Text(
                  'Welcome, ${user.fullName}',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                );

                final subtitle = Text(
                  'Scan IDs, review recent logs, and keep attendance moving smoothly.',
                  maxLines: compact ? 2 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style:
                      (compact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)
                          ?.copyWith(color: Colors.white.withAlpha(226)),
                );

                final icon = Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(34),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: compact ? 24 : 30,
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: title),
                        ],
                      ),
                      const SizedBox(height: 10),
                      subtitle,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 8), subtitle],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
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
              return Column(
                children: [
                  HomeSyncStatus(
                    studentStatus: viewModel.studentSync,
                    teacherStatus: viewModel.teacherSync,
                    onSyncStudents: viewModel.syncStudents,
                    onSyncTeachers: viewModel.syncTeachers,
                  ),
                  const SizedBox(height: 16),
                  LoggedScanSyncStatus(
                    status: viewModel.loggedScanSync,
                    onSyncLoggedPeople: viewModel.syncLoggedPeople,
                  ),
                  const SizedBox(height: 16),
                  HomeLeaderboard(viewModel: viewModel),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 174,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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
      padding: const EdgeInsets.all(18),
      decoration: ScannerTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ScannerTheme.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ScannerTheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ScannerTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ScannerTheme.mutedText,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
