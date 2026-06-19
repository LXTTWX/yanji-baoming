import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/providers/theme_provider.dart';
import 'package:yanji/core/utils/demo_data.dart';
import 'package:yanji/data/models/emergency_card.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/emergency_card_repository.dart';
import 'package:yanji/data/repositories/family_member_repository.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';
import 'package:yanji/widgets/sensitive_data.dart';

/// 首页 3.0
///
/// 布局优先级（自上而下）：
/// 1. 我的健康状态卡片（核心·最大）：体重、BMI、人体体型轮廓、连续打卡、本周完成率
/// 2. 健康异常提醒（条件渲染）：有异常显红，无异常显绿色"全家健康"
/// 3. 全家健康概览：每人一行，异常置顶标红
/// 4. 快捷操作栏（缩小·底部）：三个图标按钮
/// 新手引导：无任何数据时显示欢迎引导 + 突出快捷入口
class HomePage extends StatefulWidget {
  /// 构造函数
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final FitnessRecordRepository _fitnessRepo = FitnessRecordRepository();
  final FamilyMemberRepository _memberRepo = FamilyMemberRepository();
  final HealthRecordRepository _healthRepo = HealthRecordRepository();
  final EmergencyCardRepository _emergencyRepo = EmergencyCardRepository();

  UserProfile? _profile;
  int _consecutiveDays = 0;
  int _weekCompletedDays = 0;
  List<FamilyMember> _members = [];
  Map<String, HealthRecord?> _latestRecords = {};
  List<HealthRecord> _abnormalRecords = [];
  bool _isLoading = true;
  EmergencyCard? _emergencyCard;
  EmergencyContact? _primaryContact;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载首页所需全部数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileRepo.getProfile();
      final consecutive = await _fitnessRepo.getConsecutiveDays();
      final weekDays = await _calcWeekCompletedDays();
      final members = await _memberRepo.getAllMembers();

      final Map<String, HealthRecord?> latest = {};
      final List<HealthRecord> abnormal = [];
      for (final member in members) {
        final records = await _healthRepo.getRecordsByMember(member.id);
        if (records.isNotEmpty) {
          records.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          latest[member.id] = records.first;
          if (records.first.isAbnormal) {
            abnormal.add(records.first);
          }
        } else {
          latest[member.id] = null;
        }
      }

      setState(() {
        _profile = profile;
        _consecutiveDays = consecutive;
        _weekCompletedDays = weekDays;
        _members = members;
        _latestRecords = latest;
        _abnormalRecords = abnormal;
        _isLoading = false;
      });

      // 加载急救卡摘要数据（不阻塞主流程）
      final card = await _emergencyRepo.getCard();
      final contact = await _emergencyRepo.getPrimaryContact();
      if (mounted) {
        setState(() {
          _emergencyCard = card;
          _primaryContact = contact;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// 计算本周（周一至今）已完成打卡天数
  Future<int> _calcWeekCompletedDays() async {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=周一
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    final all = await _fitnessRepo.getAllRecords();
    final completedDates = <String>{};
    for (final r in all) {
      if (!r.completed) continue;
      try {
        final d = DateTime.parse(r.date);
        if (!d.isBefore(monday) &&
            d.isBefore(DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 1)))) {
          completedDates.add(r.date);
        }
      } catch (_) {
        // 忽略异常日期
      }
    }
    return completedDates.length;
  }

  /// 判断是否为空数据态（触发新手引导）
  bool get _isEmptyState =>
      _profile == null && _members.isEmpty && _consecutiveDays == 0;

  /// 获取成员姓名
  String _getMemberName(String memberId) {
    for (final m in _members) {
      if (m.id == memberId) return m.name;
    }
    return '未知';
  }

  /// BMI 状态评价
  _BmiLevel _evaluateBmi(double? bmi) {
    if (bmi == null) return _BmiLevel.none;
    if (bmi < 18.5) return _BmiLevel.thin;
    if (bmi < 24) return _BmiLevel.normal;
    if (bmi < 28) return _BmiLevel.over;
    return _BmiLevel.obese;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.045;
    final isElder = context.watch<ThemeProvider>().elderMode;
    final fontSize = MediaQuery.of(context).textScaler.scale(14) *
        (isElder ? 1.2 : 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _isEmptyState
                  ? _buildOnboarding(context, theme, padding, fontSize)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          padding, padding * 0.5, padding, padding * 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMyHealthCard(
                              theme, padding, fontSize, isElder),
                          SizedBox(height: padding * 0.7),
                          _buildAbnormalOrHealthyBanner(
                              theme, padding, fontSize),
                          SizedBox(height: padding * 0.7),
                          _buildEmergencyCardSummary(theme, padding, fontSize),
                          SizedBox(height: padding * 0.7),
                          _buildFamilyOverview(theme, padding, fontSize),
                          SizedBox(height: padding * 0.7),
                          _buildQuickActionsBar(theme, padding, fontSize),
                        ],
                      ),
                    ),
            ),
    );
  }

  // ==================== 新手引导 ====================

  /// 空数据态欢迎引导
  Widget _buildOnboarding(
      BuildContext context, ThemeData theme, double padding, double fontSize) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: padding * 1.5),
          Container(
            width: fontSize * 6,
            height: fontSize * 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.waving_hand_outlined,
                size: fontSize * 3, color: theme.colorScheme.primary),
          ),
          SizedBox(height: padding),
          Text('欢迎使用${AppConstants.appName}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: padding * 0.5),
          Text(
            '你的家庭健康管家\n所有数据仅存储在本地，绝不上传',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: fontSize * 0.95,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6),
          ),
          SizedBox(height: padding * 1.5),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loadDemoAndRefresh,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('一键加载演示数据'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: padding * 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          SizedBox(height: padding),
          Text('或快速开始',
              style: TextStyle(
                  fontSize: fontSize * 0.85,
                  color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(height: padding * 0.6),
          Row(
            children: [
              Expanded(
                  child: _buildQuickEntry(
                      theme, padding, fontSize, Icons.fitness_center,
                      '开始健身', () => context.push('/fitness'))),
              SizedBox(width: padding * 0.5),
              Expanded(
                  child: _buildQuickEntry(
                      theme, padding, fontSize, Icons.favorite_outline,
                      '记录健康', () => context.push('/family'))),
              SizedBox(width: padding * 0.5),
              Expanded(
                  child: _buildQuickEntry(
                      theme, padding, fontSize, Icons.notifications_outlined,
                      '设置提醒', () => context.push('/reminder'))),
            ],
          ),
          SizedBox(height: padding),
          Text(
            '完成后即可看到完整健康概览',
            style: TextStyle(
                fontSize: fontSize * 0.8,
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 加载演示数据并刷新
  Future<void> _loadDemoAndRefresh() async {
    try {
      await DemoData().loadAll();
      await _loadData();
    } catch (_) {
      // 静默处理
    }
  }

  /// 引导页快捷入口
  Widget _buildQuickEntry(ThemeData theme, double padding, double fontSize,
      IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: padding * 0.5, horizontal: padding * 0.3),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: fontSize * 1.6),
              SizedBox(height: padding * 0.25),
              Text(label,
                  style: TextStyle(
                      fontSize: fontSize * 0.85,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ① 我的健康状态卡片 ====================

  /// 我的健康状态卡片（核心·最大）
  Widget _buildMyHealthCard(
      ThemeData theme, double padding, double fontSize, bool isElder) {
    final profile = _profile;
    final weight = profile?.weight;
    final height = profile?.height;
    final bmi = profile?.calculateBMI();
    final level = _evaluateBmi(bmi);
    final nickname = profile?.nickname ?? '用户';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * (isElder ? 1.1 : 1.0)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：问候 + 编辑入口
          Row(
            children: [
              CircleAvatar(
                radius: fontSize * 1.3,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person_outline,
                    color: theme.colorScheme.primary, size: fontSize * 1.5),
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('你好，$nickname',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                      _greetingByTime(),
                      style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/fitness/profile'),
                icon: Icon(Icons.tune_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                tooltip: '编辑资料',
              ),
            ],
          ),
          SizedBox(height: padding * 0.8),
          // 中部：体重 + 人体轮廓 + BMI
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左：体重
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前体重',
                        style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: theme.colorScheme.onSurfaceVariant)),
                    SizedBox(height: 4),
                    SensitiveData(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            weight != null ? weight.toStringAsFixed(1) : '--',
                            style: TextStyle(
                                fontSize: fontSize * 2.4,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface),
                          ),
                          SizedBox(width: 4),
                          Text('kg',
                              style: TextStyle(
                                  fontSize: fontSize,
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    if (height != null)
                      Text('身高 ${height.toStringAsFixed(0)} cm',
                          style: TextStyle(
                              fontSize: fontSize * 0.78,
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              // 中：人体体型轮廓
              SizedBox(
                width: fontSize * 4.2,
                height: fontSize * 6.5,
                child: CustomPaint(
                  painter: _BodySilhouettePainter(
                    level: level,
                    bodyColor: level.color,
                    outlineColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.35),
                  ),
                ),
              ),
              SizedBox(width: padding * 0.4),
              // 右：BMI 数值 + 状态徽章
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('BMI',
                        style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: theme.colorScheme.onSurfaceVariant)),
                    SizedBox(height: 4),
                    Text(
                      bmi != null ? bmi.toStringAsFixed(1) : '--',
                      style: TextStyle(
                          fontSize: fontSize * 2.0,
                          fontWeight: FontWeight.bold,
                          color: level.color),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.4,
                          vertical: padding * 0.15),
                      decoration: BoxDecoration(
                        color: level.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: level.color.withValues(alpha: 0.4),
                            width: 1),
                      ),
                      child: Text(
                        level.label,
                        style: TextStyle(
                            fontSize: fontSize * 0.8,
                            fontWeight: FontWeight.bold,
                            color: level.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.8),
          Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.3)),
          SizedBox(height: padding * 0.6),
          // 底部：连续打卡 + 本周完成率
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  padding,
                  fontSize,
                  icon: Icons.local_fire_department_outlined,
                  iconColor: AppColors.warning,
                  value: '$_consecutiveDays 天',
                  label: '连续打卡',
                ),
              ),
              Container(
                  width: 1,
                  height: fontSize * 2.2,
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3)),
              Expanded(
                child: _buildWeekProgress(theme, padding, fontSize),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 按时段返回问候语
  String _greetingByTime() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了，注意休息';
    if (h < 11) return '早安，开启健康一天';
    if (h < 14) return '午安，记得活动一下';
    if (h < 18) return '下午好，保持活力';
    return '晚上好，今天辛苦了';
  }

  /// 统计项（连续打卡）
  Widget _buildStatItem(
    ThemeData theme,
    double padding,
    double fontSize, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(padding * 0.3),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: fontSize * 1.2),
        ),
        SizedBox(width: padding * 0.4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: fontSize * 1.15,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    fontSize: fontSize * 0.75,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  /// 本周完成率（进度环 + 数字）
  Widget _buildWeekProgress(ThemeData theme, double padding, double fontSize) {
    final ratio = (_weekCompletedDays / 7).clamp(0.0, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: fontSize * 2.4,
          height: fontSize * 2.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: fontSize * 0.25,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
              CircularProgressIndicator(
                value: ratio,
                strokeWidth: fontSize * 0.25,
                color: AppColors.success,
              ),
              Text(
                '$_weekCompletedDays/7',
                style: TextStyle(
                    fontSize: fontSize * 0.7,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(width: padding * 0.4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${(ratio * 100).toInt()}%',
                style: TextStyle(
                    fontSize: fontSize * 1.15,
                    fontWeight: FontWeight.bold)),
            Text('本周完成',
                style: TextStyle(
                    fontSize: fontSize * 0.75,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  // ==================== ② 健康异常提醒 ====================

  /// 异常提醒 / 全家健康横幅
  Widget _buildAbnormalOrHealthyBanner(
      ThemeData theme, double padding, double fontSize) {
    if (_abnormalRecords.isEmpty) {
      // 绿色"全家健康"小条
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: padding * 0.8, vertical: padding * 0.5),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: fontSize * 1.4),
            SizedBox(width: padding * 0.4),
            Expanded(
              child: Text(
                '全家健康，暂无异常记录',
                style: TextStyle(
                    fontSize: fontSize * 0.95,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success),
              ),
            ),
          ],
        ),
      );
    }

    // 红色异常提醒卡片
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.error, size: fontSize * 1.4),
              SizedBox(width: padding * 0.4),
              Text(
                '健康异常提醒',
                style: TextStyle(
                    fontSize: fontSize * 1.1,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error),
              ),
              const Spacer(),
              Text('${_abnormalRecords.length} 项',
                  style: TextStyle(
                      fontSize: fontSize * 0.85,
                      color: theme.colorScheme.error
                          .withValues(alpha: 0.8))),
            ],
          ),
          SizedBox(height: padding * 0.5),
          ..._abnormalRecords.map((r) => Padding(
                padding: EdgeInsets.only(bottom: padding * 0.3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_getMemberName(r.memberId)}：${r.type} ${r.value}${r.unit}',
                        style: TextStyle(
                            fontSize: fontSize * 0.95,
                            color: theme.colorScheme.onSurface),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/family/record/${r.memberId}'),
                      child: Text('查看',
                          style: TextStyle(fontSize: fontSize * 0.85)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ==================== ③ 急救卡摘要 ====================

  /// 首页急救卡摘要卡片
  ///
  /// 紧凑展示血型、过敏、第一联系人，点击进入完整急救卡
  Widget _buildEmergencyCardSummary(
      ThemeData theme, double padding, double fontSize) {
    final card = _emergencyCard;
    final contact = _primaryContact;

    // 血型颜色映射
    Color bloodColor(int type) {
      switch (type) {
        case 1:
          return const Color(0xFFE53935);
        case 2:
          return const Color(0xFF1E88E5);
        case 3:
          return const Color(0xFF8E24AA);
        case 4:
          return const Color(0xFF43A047);
        default:
          return const Color(0xFF9E9E9E);
      }
    }

    String bloodText(int type) {
      switch (type) {
        case 1:
          return 'A';
        case 2:
          return 'B';
        case 3:
          return 'AB';
        case 4:
          return 'O';
        default:
          return '?';
      }
    }

    return InkWell(
      onTap: () => context.push('/profile/settings/emergency'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding * 0.7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.error.withValues(alpha: 0.06),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // 左侧：急救标识 + 血型小圆章
            Container(
              width: fontSize * 3.2,
              height: fontSize * 3.2,
              decoration: BoxDecoration(
                color: card != null ? bloodColor(card.bloodType) : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency,
                      color: Colors.white, size: fontSize * 0.9),
                  Text(
                    card != null ? bloodText(card.bloodType) : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize * 1.3,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: padding * 0.5),
            // 中间：急救卡信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined,
                          size: fontSize * 1.1, color: AppColors.error),
                      SizedBox(width: padding * 0.2),
                      Text('医疗急救卡',
                          style: TextStyle(
                              fontSize: fontSize * 1.05,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: padding * 0.2),
                  // 过敏史摘要
                  if (card != null && card.allergies.isNotEmpty)
                    Text(
                      '过敏：${card.allergies.replaceAll('\n', '、')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600),
                    )
                  else
                    Text('无过敏史',
                        style: TextStyle(
                            fontSize: fontSize * 0.85,
                            color: theme.colorScheme.onSurfaceVariant)),
                  SizedBox(height: 2),
                  // 第一联系人
                  if (contact != null)
                    Text(
                      '紧急联系：${contact.name} ${contact.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  else
                    Text('未设置紧急联系人',
                        style: TextStyle(
                            fontSize: fontSize * 0.85,
                            color: AppColors.warning)),
                ],
              ),
            ),
            // 右侧：箭头
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                size: fontSize * 1.3),
          ],
        ),
      ),
    );
  }

  // ==================== ③ 全家健康概览 ====================

  /// 全家健康概览
  Widget _buildFamilyOverview(
      ThemeData theme, double padding, double fontSize) {
    if (_members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.4),
              width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline,
                size: fontSize * 3,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.5)),
            SizedBox(height: padding * 0.5),
            Text('还没有家庭成员',
                style: TextStyle(
                    fontSize: fontSize,
                    color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: padding * 0.3),
            TextButton(
              onPressed: () => context.push('/family'),
              child: const Text('去添加成员'),
            ),
          ],
        ),
      );
    }

    // 异常成员置顶
    final sorted = List<FamilyMember>.from(_members);
    sorted.sort((a, b) {
      final ra = _latestRecords[a.id];
      final rb = _latestRecords[b.id];
      final aAb = ra != null && ra.isAbnormal ? 1 : 0;
      final bAb = rb != null && rb.isAbnormal ? 1 : 0;
      return bAb - aAb;
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('全家健康概览',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => context.push('/family'),
                child: Text('查看详情',
                    style: TextStyle(fontSize: fontSize * 0.85)),
              ),
            ],
          ),
          SizedBox(height: padding * 0.4),
          ...sorted.map((m) => _buildMemberRow(theme, padding, fontSize, m)),
        ],
      ),
    );
  }

  /// 单个成员行
  Widget _buildMemberRow(
      ThemeData theme, double padding, double fontSize, FamilyMember m) {
    final record = _latestRecords[m.id];
    final isAbnormal = record != null && record.isAbnormal;
    final bg = isAbnormal
        ? theme.colorScheme.error.withValues(alpha: 0.06)
        : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.3),
      padding: EdgeInsets.symmetric(
          horizontal: padding * 0.4, vertical: padding * 0.4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: fontSize * 1.1,
            backgroundColor: (isAbnormal
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary)
                .withValues(alpha: 0.15),
            child: Icon(
              m.gender == 1 ? Icons.man_outlined : Icons.woman_outlined,
              color: isAbnormal
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: fontSize * 1.4,
            ),
          ),
          SizedBox(width: padding * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                SizedBox(height: 2),
                if (record != null)
                  Text(
                    '${record.type} ${record.value}${record.unit}',
                    style: TextStyle(
                        fontSize: fontSize * 0.85,
                        color: isAbnormal
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant),
                  )
                else
                  Text('暂无数据',
                      style: TextStyle(
                          fontSize: fontSize * 0.85,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6))),
              ],
            ),
          ),
          Icon(
            isAbnormal ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isAbnormal
                ? theme.colorScheme.error
                : AppColors.success,
            size: fontSize * 1.2,
          ),
        ],
      ),
    );
  }

  // ==================== ④ 快捷操作栏 ====================

  /// 底部快捷操作栏（缩小）
  Widget _buildQuickActionsBar(
      ThemeData theme, double padding, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: padding * 0.4, vertical: padding * 0.4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAction(
                theme, padding, fontSize, Icons.fitness_center,
                '开始健身', () => context.push('/fitness')),
          ),
          Container(
              width: 1,
              height: fontSize * 2.2,
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.3)),
          Expanded(
            child: _buildQuickAction(
                theme, padding, fontSize, Icons.favorite_outline,
                '记录健康', () => context.push('/family')),
          ),
          Container(
              width: 1,
              height: fontSize * 2.2,
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.3)),
          Expanded(
            child: _buildQuickAction(
                theme, padding, fontSize, Icons.notifications_outlined,
                '设置提醒', () => context.push('/reminder')),
          ),
        ],
      ),
    );
  }

  /// 单个快捷操作按钮
  Widget _buildQuickAction(ThemeData theme, double padding, double fontSize,
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding * 0.3),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(padding * 0.3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: theme.colorScheme.primary, size: fontSize * 1.3),
            ),
            SizedBox(height: padding * 0.2),
            Text(label,
                style: TextStyle(
                    fontSize: fontSize * 0.82,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ==================== BMI 等级枚举 ====================

/// BMI 评价等级
enum _BmiLevel {
  /// 未知
  none('—', Color(0xFF9E9E9E)),
  /// 偏瘦
  thin('偏瘦', Color(0xFFF5A623)),
  /// 正常
  normal('正常', Color(0xFF4CAF50)),
  /// 超重
  over('超重', Color(0xFFFF9800)),
  /// 肥胖
  obese('肥胖', Color(0xFFE53935));

  final String label;
  final Color color;
  const _BmiLevel(this.label, this.color);
}

// ==================== 人体体型轮廓 Painter ====================

/// 根据 BMI 等级绘制人体体型轮廓
///
/// 通过调整躯干/四肢宽度比例表现体型：
/// - thin：四肢纤细，躯干窄
/// - normal：匀称
/// - over：躯干略宽
/// - obese：躯干明显宽厚，四肢粗
class _BodySilhouettePainter extends CustomPainter {
  final _BmiLevel level;
  final Color bodyColor;
  final Color outlineColor;

  _BodySilhouettePainter({
    required this.level,
    required this.bodyColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 体型宽度系数（躯干/四肢）
    double torsoFactor;
    double limbFactor;
    switch (level) {
      case _BmiLevel.thin:
        torsoFactor = 0.22;
        limbFactor = 0.08;
        break;
      case _BmiLevel.normal:
        torsoFactor = 0.28;
        limbFactor = 0.10;
        break;
      case _BmiLevel.over:
        torsoFactor = 0.36;
        limbFactor = 0.12;
        break;
      case _BmiLevel.obese:
        torsoFactor = 0.44;
        limbFactor = 0.14;
        break;
      case _BmiLevel.none:
        torsoFactor = 0.28;
        limbFactor = 0.10;
        break;
    }

    final fillPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeJoin = StrokeJoin.round;

    // 头部
    final headRadius = w * 0.13;
    final headCenter = Offset(cx, h * 0.10);
    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // 颈部
    final neckTop = headCenter.dy + headRadius;
    final neckBottom = neckTop + h * 0.04;
    final neckWidth = w * 0.06;
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, (neckTop + neckBottom) / 2),
          width: neckWidth,
          height: neckBottom - neckTop),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, fillPaint);
    canvas.drawRRect(neckRect, outlinePaint);

    // 躯干（肩→腰→臀，用贝塞尔曲线表现轮廓）
    final shoulderY = neckBottom;
    final waistY = shoulderY + h * 0.22;
    final hipY = waistY + h * 0.10;
    final shoulderHalf = w * torsoFactor;
    final waistHalf = w * torsoFactor * 0.82;
    final hipHalf = w * torsoFactor * 0.95;

    final torsoPath = Path()
      ..moveTo(cx - shoulderHalf, shoulderY)
      ..quadraticBezierTo(
          cx - waistHalf - w * 0.02, (shoulderY + waistY) / 2,
          cx - waistHalf, waistY)
      ..quadraticBezierTo(
          cx - hipHalf, (waistY + hipY) / 2,
          cx - hipHalf, hipY)
      ..lineTo(cx + hipHalf, hipY)
      ..quadraticBezierTo(
          cx + hipHalf, (waistY + hipY) / 2,
          cx + waistHalf, waistY)
      ..quadraticBezierTo(
          cx + waistHalf + w * 0.02, (shoulderY + waistY) / 2,
          cx + shoulderHalf, shoulderY)
      ..close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // 手臂（左右）
    final armWidth = w * limbFactor;
    final armTop = shoulderY + h * 0.01;
    final armBottom = hipY - h * 0.02;
    final armOffsetX = shoulderHalf + armWidth * 0.6;

    for (final sign in [-1.0, 1.0]) {
      final armRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + sign * armOffsetX, (armTop + armBottom) / 2),
          width: armWidth,
          height: armBottom - armTop,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(armRect, fillPaint);
      canvas.drawRRect(armRect, outlinePaint);
    }

    // 腿部（左右）
    final legWidth = w * limbFactor * 1.1;
    final legTop = hipY;
    final legBottom = h * 0.97;
    final legOffsetX = hipHalf * 0.45;

    for (final sign in [-1.0, 1.0]) {
      final legRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + sign * legOffsetX, (legTop + legBottom) / 2),
          width: legWidth,
          height: legBottom - legTop,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(legRect, fillPaint);
      canvas.drawRRect(legRect, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}
