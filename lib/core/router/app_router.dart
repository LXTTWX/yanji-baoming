import 'package:go_router/go_router.dart';
import 'package:yanji/modules/home/home_page.dart';
import 'package:yanji/modules/fitness/fitness_page.dart';
import 'package:yanji/modules/fitness/fitness_profile.dart';
import 'package:yanji/modules/fitness/fitness_plan.dart';
import 'package:yanji/modules/fitness/fitness_stats.dart';
import 'package:yanji/modules/fitness/fitness_achievement.dart';
import 'package:yanji/modules/family/family_page.dart';
import 'package:yanji/modules/family/health_record_page.dart';
import 'package:yanji/modules/family/health_chart_page.dart';
import 'package:yanji/modules/reminder/reminder_page.dart';
import 'package:yanji/modules/settings/settings_page.dart';
import 'package:yanji/modules/profile/profile_page.dart';
import 'package:yanji/modules/emergency/emergency_card_page.dart';
import 'package:yanji/widgets/app_scaffold.dart';

/// 应用路由配置
///
/// 底部导航 3 个 Tab：健身、守护、我的。
/// 首页、提醒等作为独立路由保留。
class AppRouter {
  /// 路由实例
  static final GoRouter router = GoRouter(
    initialLocation: '/fitness',
    routes: [
      // 急救卡锁屏查看（独立路由，不在主Shell内）
      GoRoute(
        path: '/emergency/lock',
        builder: (context, state) => const EmergencyCardPage(
            mode: EmergencyCardMode.lock),
      ),
      // 首页（独立路由，非 Tab）
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // 提醒页（独立路由，非 Tab）
      GoRoute(
        path: '/reminder',
        builder: (context, state) => const ReminderPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: 健身
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fitness',
                builder: (context, state) => const FitnessPage(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const FitnessProfilePage(),
                  ),
                  GoRoute(
                    path: 'plan',
                    builder: (context, state) => const FitnessPlanPage(),
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => const FitnessStatsPage(),
                  ),
                  GoRoute(
                    path: 'achievement',
                    builder: (context, state) => const FitnessAchievementPage(),
                  ),
                ],
              ),
            ],
          ),
          // Tab 1: 守护
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/family',
                builder: (context, state) => const FamilyPage(),
                routes: [
                  GoRoute(
                    path: 'record/:memberId',
                    builder: (context, state) {
                      final memberId = state.pathParameters['memberId'] ?? '';
                      return HealthRecordPage(memberId: memberId);
                    },
                  ),
                  GoRoute(
                    path: 'chart/:memberId',
                    builder: (context, state) {
                      final memberId = state.pathParameters['memberId'] ?? '';
                      final extra = state.extra;
                      final memberName = (extra is Map && extra.containsKey('memberName'))
                          ? extra['memberName'] as String
                          : '成员';
                      return HealthChartPage(memberId: memberId, memberName: memberName);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: 我的
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  // 完整设置页
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                    routes: [
                      // 急救卡（从设置页进入）
                      GoRoute(
                        path: 'emergency',
                        builder: (context, state) => const EmergencyCardPage(
                            mode: EmergencyCardMode.view),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
