part of '../login_screen.dart';

class _Sidebar extends StatelessWidget {
  static const _campusImagePath = 'assets/images/leon-garcia-campus.jpg';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _campusImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (!kIsWeb) return const SizedBox.expand();
            return Image.network(
              Uri.base.resolve('assets/$_campusImagePath').toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.expand(),
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.adminSidebar.withAlpha(242),
                AppColors.adminPrimary.withAlpha(226),
                AppColors.adminAccent.withAlpha(190),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(72),
                Colors.transparent,
                AppColors.adminSidebar.withAlpha(150),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 34, 36, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarHeader(),
                      const SizedBox(height: 42),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(24),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withAlpha(34)),
                        ),
                        child: const Text(
                          'ATTENDANCE · GATE PASS · REPORTS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: AppColors.adminSidebarMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'School Attendance Monitoring System',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Securely monitor student and teacher Time In, '
                        'Time Out, gate pass activity, reports, and '
                        'school year records in one place.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.adminBorder,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 34),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.05,
                        children: const [
                          _FeatureCard(
                            icon: Icons.fact_check_outlined,
                            iconColor: AppColors.warn,
                            title: 'Premises attendance',
                            description:
                                'Track valid Time In and Time Out scans.',
                          ),
                          _FeatureCard(
                            icon: Icons.emoji_events,
                            iconColor: AppColors.adminPrimary,
                            title: 'Early attendance',
                            description:
                                'Rank the earliest valid Time In records.',
                          ),
                          _FeatureCard(
                            icon: Icons.badge,
                            iconColor: AppColors.adminAccent,
                            title: 'Gate pass',
                            description:
                                'Record school-hour exits and returns.',
                          ),
                          _FeatureCard(
                            icon: Icons.insert_chart_outlined,
                            iconColor: AppColors.adminAccent,
                            title: 'Reports',
                            description:
                                'Review and download attendance records.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(24),
                  border: Border(
                    top: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                ),
                child: Text(
                  'Copyright ${DateTime.now().year} LEON GARCIA',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.adminSidebarMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
