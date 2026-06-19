import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/theme/design_system.dart';
import 'package:yanji/data/models/app_config.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';

/// 我的页面（家檐安记风格）
///
/// 个人中心与安全，极简大留白设计。
/// 包含：个人信息卡片、勋章墙卡片、隐私与安全卡片。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final AppConfigRepository _configRepo = AppConfigRepository();
  UserProfile? _profile;
  AppConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载用户数据
  Future<void> _loadData() async {
    try {
      final profile = await _profileRepo.getProfile();
      final config = await _configRepo.getConfig();
      setState(() {
        _profile = profile;
        _config = config;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final padding = DesignSystem.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : RefreshIndicator(
                color: AppColors.terracotta,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(padding, padding * 0.6, padding, padding * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: padding * 0.8),
                      _buildProfileCard(sw),
                      SizedBox(height: padding * 0.6),
                      _buildBadgeWall(sw),
                      SizedBox(height: padding * 0.6),
                      _buildPrivacySecurityCard(sw),
                      SizedBox(height: padding * 0.6),
                      _buildSettingsEntry(sw),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 顶部 Header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('个人中心', style: DesignSystem.pageSubtitle()),
        SizedBox(height: 4),
        Text('我的', style: DesignSystem.pageTitle()),
      ],
    );
  }

  /// 个人信息卡片
  Widget _buildProfileCard(double sw) {
    final name = _profile?.nickname ?? '健康用户';
    final consecutiveDays = 28; // 模拟连续打卡天数

    return HomeCard(
      child: Row(
        children: [
          // 渐变色头像
          Container(
            width: sw * 0.18,
            height: sw * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.terracotta, AppColors.amber],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracotta.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1) : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: DesignSystem.serif,
                ),
              ),
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignSystem.cardTitle()),
                SizedBox(height: 4),
                Text(
                  '健身达人 · 连续 $consecutiveDays 天',
                  style: DesignSystem.cardSubtitle(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.taupe),
            onPressed: () => context.push('/fitness/profile'),
          ),
        ],
      ),
    );
  }

  /// 勋章墙卡片
  Widget _buildBadgeWall(double sw) {
    final badges = [
      {'icon': '🔥', 'label': '7天连击', 'color': AppColors.amber, 'unlocked': true},
      {'icon': '💪', 'label': '力量初成', 'color': AppColors.terracotta, 'unlocked': true},
      {'icon': '🎯', 'label': '目标过半', 'color': AppColors.sage, 'unlocked': true},
      {'icon': '🔒', 'label': '30天', 'color': AppColors.taupe, 'unlocked': false},
    ];

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('勋章墙', style: DesignSystem.cardTitle()),
              TextButton(
                onPressed: () => context.push('/fitness/achievement'),
                child: Text('全部', style: TextStyle(
                  color: AppColors.terracotta,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ],
          ),
          SizedBox(height: sw * 0.04),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: sw * 0.03,
            crossAxisSpacing: sw * 0.03,
            childAspectRatio: 1,
            children: badges.map((b) => _buildBadge(sw, b)).toList(),
          ),
        ],
      ),
    );
  }

  /// 单个勋章
  Widget _buildBadge(double sw, Map<String, dynamic> badge) {
    final isUnlocked = badge['unlocked'] as bool;
    final color = badge['color'] as Color;
    final icon = badge['icon'] as String;
    final label = badge['label'] as String;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? color.withValues(alpha: 0.12) : AppColors.borderLight,
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? null
              : Border.all(
                  color: AppColors.taupe.withValues(alpha: 0.3),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: sw * 0.06)),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? color : AppColors.taupe,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 隐私与安全卡片
  Widget _buildPrivacySecurityCard(double sw) {
    final lockEnabled = _config?.appLockEnabled ?? false;
    final blurEnabled = _config?.sensitiveDataBlurEnabled ?? false;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('隐私与安全', style: DesignSystem.cardTitle()),
          SizedBox(height: sw * 0.04),
          // 应用启动锁
          _buildSwitchTile(
            sw,
            icon: Icons.lock_outline,
            title: '应用启动锁',
            value: lockEnabled,
            onChanged: (v) => _toggleAppLock(v),
          ),
          Divider(height: sw * 0.04, color: AppColors.borderLight),
          // 敏感数据模糊
          _buildSwitchTile(
            sw,
            icon: Icons.visibility_off_outlined,
            title: '敏感数据模糊',
            value: blurEnabled,
            onChanged: (v) => _toggleSensitiveBlur(v),
          ),
          Divider(height: sw * 0.04, color: AppColors.borderLight),
          // AES 加密导出
          _buildInfoTile(
            sw,
            icon: Icons.enhanced_encryption_outlined,
            title: 'AES 加密导出',
            trailing: '已启用',
            trailingColor: AppColors.amber,
          ),
        ],
      ),
    );
  }

  /// 开关列表项
  Widget _buildSwitchTile(
    double sw, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.taupe, size: sw * 0.05),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Text(title, style: DesignSystem.body()),
        ),
        // iOS 风格开关
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: value ? AppColors.sage : AppColors.borderLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 信息列表项
  Widget _buildInfoTile(
    double sw, {
    required IconData icon,
    required String title,
    required String trailing,
    required Color trailingColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.taupe, size: sw * 0.05),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Text(title, style: DesignSystem.body()),
        ),
        Text(
          trailing,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: trailingColor,
          ),
        ),
      ],
    );
  }

  /// 设置入口
  Widget _buildSettingsEntry(double sw) {
    return GestureDetector(
      onTap: () => context.push('/profile/settings'),
      child: HomeCard(
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: AppColors.taupe, size: sw * 0.05),
            SizedBox(width: sw * 0.03),
            Expanded(
              child: Text('全部设置', style: DesignSystem.body()),
            ),
            Icon(Icons.chevron_right, color: AppColors.taupe, size: sw * 0.05),
          ],
        ),
      ),
    );
  }

  /// 切换应用锁
  Future<void> _toggleAppLock(bool value) async {
    final config = _config;
    if (config == null) return;
    config.appLockEnabled = value;
    await _configRepo.saveConfig(config);
    setState(() {});
  }

  /// 切换敏感数据模糊
  Future<void> _toggleSensitiveBlur(bool value) async {
    final config = _config;
    if (config == null) return;
    config.sensitiveDataBlurEnabled = value;
    await _configRepo.saveConfig(config);
    setState(() {});
  }
}
