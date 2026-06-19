import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/theme/design_system.dart';
import 'package:yanji/data/models/family_member.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/repositories/family_member_repository.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';

/// 守护页面（家檐安记风格）
///
/// 长辈健康关怀，去医疗器械化设计。
/// 包含：异常状态卡片（隐私模糊）、正常状态卡片（心跳动画）、服药打卡卡片。
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage>
    with TickerProviderStateMixin {
  final FamilyMemberRepository _memberRepo = FamilyMemberRepository();
  final HealthRecordRepository _healthRepo = HealthRecordRepository();

  List<FamilyMember> _members = [];
  Map<String, HealthRecord?> _latestRecords = {};
  Map<String, List<HealthRecord>> _medicationRecords = {};
  bool _isLoading = true;

  // 隐私模糊状态：每个成员的每个数据项是否显示明文
  final Set<String> _revealedKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    try {
      final members = await _memberRepo.getAllMembers();
      final latestMap = <String, HealthRecord?>{};
      final medMap = <String, List<HealthRecord>>{};

      for (final m in members) {
        final records = await _healthRepo.getRecordsByMember(m.id);
        if (records.isNotEmpty) {
          // 最新血压记录
          final bpRecords = records.where((r) => r.type == '血压').toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          latestMap[m.id] = bpRecords.isNotEmpty ? bpRecords.first : null;

          // 服药记录
          final meds = records.where((r) => r.type == '服药').toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          medMap[m.id] = meds;
        }
      }

      setState(() {
        _members = members;
        _latestRecords = latestMap;
        _medicationRecords = medMap;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// 解析血压数据
  Map<String, int>? _parseBloodPressure(String value) {
    try {
      final map = json.decode(value) as Map<String, dynamic>;
      return {
        'systolic': (map['systolic'] as num).toInt(),
        'diastolic': (map['diastolic'] as num).toInt(),
      };
    } catch (_) {
      return null;
    }
  }

  /// 判断血压是否异常
  bool _isBpAbnormal(int systolic, int diastolic) {
    return systolic >= 140 || diastolic >= 90;
  }

  /// 切换隐私模糊状态
  void _toggleReveal(String key) {
    setState(() {
      if (_revealedKeys.contains(key)) {
        _revealedKeys.remove(key);
      } else {
        _revealedKeys.add(key);
      }
    });
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
                      ..._members.map((m) => _buildMemberCard(sw, m)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 顶部 Header
  Widget _buildHeader() {
    final now = DateTime.now();
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final dateStr = '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateStr, style: DesignSystem.pageSubtitle()),
        SizedBox(height: 4),
        Text('守护模式', style: DesignSystem.pageTitle()),
        SizedBox(height: 4),
        Text('家人健康概览', style: DesignSystem.pageSubtitle()),
      ],
    );
  }

  /// 构建成员卡片
  Widget _buildMemberCard(double sw, FamilyMember member) {
    final record = _latestRecords[member.id];
    final bp = record != null ? _parseBloodPressure(record.value) : null;
    final isAbnormal = bp != null && _isBpAbnormal(bp['systolic'] ?? 0, bp['diastolic'] ?? 0);

    return Column(
      children: [
        if (isAbnormal)
          _buildAbnormalCard(sw, member, bp)
        else
          _buildNormalCard(sw, member, bp),
        SizedBox(height: sw * 0.04),
        _buildMedicationCard(sw, member),
        SizedBox(height: sw * 0.06),
      ],
    );
  }

  /// 异常状态卡片（核心警示设计）
  Widget _buildAbnormalCard(double sw, FamilyMember member, Map<String, int> bp) {
    final cardPad = DesignSystem.cardPadding(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: sw * 0.02),
      decoration: DesignSystem.cardDecoration(),
      child: Stack(
        children: [
          // 左侧红色竖条
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(cardPad + 4, cardPad, cardPad, cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部
                Row(
                  children: [
                    _buildAvatar(member, AppColors.rose),
                    SizedBox(width: sw * 0.03),
                    Expanded(
                      child: Text(member.name,
                          style: DesignSystem.cardTitle()),
                    ),
                    const StatusTag(text: '需关注', color: AppColors.rose),
                  ],
                ),
                SizedBox(height: sw * 0.04),
                // 数据网格（3列）
                Row(
                  children: [
                    _buildPrivacyData(
                      sw,
                      label: '收缩压',
                      value: '${bp['systolic']}',
                      unit: 'mmHg',
                      color: AppColors.rose,
                      revealKey: '${member.id}_systolic',
                    ),
                    _buildPrivacyData(
                      sw,
                      label: '舒张压',
                      value: '${bp['diastolic']}',
                      unit: 'mmHg',
                      color: AppColors.rose,
                      revealKey: '${member.id}_diastolic',
                    ),
                    _buildPrivacyData(
                      sw,
                      label: '心率',
                      value: '78',
                      unit: 'bpm',
                      color: AppColors.amber,
                      revealKey: '${member.id}_heart',
                    ),
                  ],
                ),
                SizedBox(height: sw * 0.03),
                // 隐私提示
                Text('👉 点击数字查看明文（防偷看）',
                    style: DesignSystem.cardSubtitle(size: 11)),
                SizedBox(height: sw * 0.03),
                // 异常解释框
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sw * 0.03),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⚠ 血压偏高，建议减少盐分摄入',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.rose,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 正常状态卡片
  Widget _buildNormalCard(double sw, FamilyMember member, Map<String, int>? bp) {
    final cardPad = DesignSystem.cardPadding(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: sw * 0.02),
      decoration: DesignSystem.cardDecoration(),
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              children: [
                _buildAvatar(member, AppColors.sage),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Text(member.name, style: DesignSystem.cardTitle()),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.sage,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('稳定',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sage,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sw * 0.04),
            // 数据网格
            Row(
              children: [
                _buildDataItem(
                  sw,
                  label: '收缩压',
                  value: bp != null ? '${bp['systolic']}' : '--',
                  unit: 'mmHg',
                  color: AppColors.sage,
                ),
                _buildDataItem(
                  sw,
                  label: '舒张压',
                  value: bp != null ? '${bp['diastolic']}' : '--',
                  unit: 'mmHg',
                  color: AppColors.sage,
                ),
                _buildHeartRateItem(sw, '72', AppColors.sage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 头像
  Widget _buildAvatar(FamilyMember member, Color color) {
    final initial = member.name.isNotEmpty ? member.name.substring(0, 1) : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 隐私数据项（可点击切换模糊/清晰）
  Widget _buildPrivacyData(
    double sw, {
    required String label,
    required String value,
    required String unit,
    required Color color,
    required String revealKey,
  }) {
    final isRevealed = _revealedKeys.contains(revealKey);
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleReveal(revealKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: DesignSystem.cardSubtitle(size: 11)),
            SizedBox(height: sw * 0.01),
            AnimatedOpacity(
              opacity: isRevealed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                value,
                style: DesignSystem.dataNumber(color: color, size: 22),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: !isRevealed
                  ? Container(
                      height: 22,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text('••••',
                            style: TextStyle(
                              color: AppColors.taupe,
                              fontSize: 14,
                              letterSpacing: 2,
                            )),
                      ),
                    )
                  : SizedBox(height: 22, child: Text(unit, style: DesignSystem.cardSubtitle(size: 10))),
            ),
          ],
        ),
      ),
    );
  }

  /// 普通数据项
  Widget _buildDataItem(
    double sw, {
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: DesignSystem.cardSubtitle(size: 11)),
          SizedBox(height: sw * 0.01),
          Text(value, style: DesignSystem.dataNumber(color: color, size: 22)),
          Text(unit, style: DesignSystem.cardSubtitle(size: 10)),
        ],
      ),
    );
  }

  /// 心率数据项（带心跳动画）
  Widget _buildHeartRateItem(double sw, String value, Color color) {
    return Expanded(
      child: _HeartbeatWidget(
        child: Column(
          children: [
            Text('心率', style: DesignSystem.cardSubtitle(size: 11)),
            SizedBox(height: sw * 0.01),
            Text(value, style: DesignSystem.dataNumber(color: color, size: 22)),
            Text('bpm', style: DesignSystem.cardSubtitle(size: 10)),
          ],
        ),
      ),
    );
  }

  /// 服药打卡卡片
  Widget _buildMedicationCard(double sw, FamilyMember member) {
    final meds = _medicationRecords[member.id] ?? [];
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayMeds = meds.where((m) => m.measuredAt.startsWith(todayStr)).toList();

    // 模拟早中晚服药状态
    final morningDone = todayMeds.any((m) {
      try {
        final d = DateTime.parse(m.measuredAt);
        return d.hour < 12;
      } catch (_) {
        return false;
      }
    });
    final noonDone = todayMeds.any((m) {
      try {
        final d = DateTime.parse(m.measuredAt);
        return d.hour >= 12 && d.hour < 18;
      } catch (_) {
        return false;
      }
    });
    final eveningDone = todayMeds.any((m) {
      try {
        final d = DateTime.parse(m.measuredAt);
        return d.hour >= 18;
      } catch (_) {
        return false;
      }
    });

    final doneCount = [morningDone, noonDone, eveningDone].where((b) => b).length;
    final cardPad = DesignSystem.cardPadding(context);

    return Container(
      width: double.infinity,
      decoration: DesignSystem.cardDecoration(),
      child: Padding(
        padding: EdgeInsets.all(cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('服药打卡', style: DesignSystem.cardTitle()),
                Text('$doneCount / 3',
                    style: DesignSystem.dataNumber(
                        color: AppColors.terracotta, size: 16)),
              ],
            ),
            SizedBox(height: sw * 0.04),
            Row(
              children: [
                _buildMedicationBlock(sw, '早', '07:00', morningDone, AppColors.sage),
                SizedBox(width: sw * 0.025),
                _buildMedicationBlock(sw, '中', '12:00', noonDone, AppColors.sage),
                SizedBox(width: sw * 0.025),
                _buildMedicationBlock(sw, '晚', '19:00', eveningDone, AppColors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 服药时间块
  Widget _buildMedicationBlock(
      double sw, String period, String time, bool done, Color doneColor) {
    final color = done ? doneColor : AppColors.amber;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sw * 0.03),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(period,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
            SizedBox(height: 2),
            Text(time,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                )),
            SizedBox(height: sw * 0.02),
            Text(
              done ? '✓ 已服' : '⏰ 待服',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 心跳动画组件
///
/// 模拟人类心跳节奏的轻微缩放动画，传达"鲜活"的生命感。
class _HeartbeatWidget extends StatefulWidget {
  final Widget child;

  const _HeartbeatWidget({required this.child});

  @override
  State<_HeartbeatWidget> createState() => _HeartbeatWidgetState();
}

class _HeartbeatWidgetState extends State<_HeartbeatWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 模拟心跳：两次快速跳动后停顿
        final t = _controller.value;
        double scale = 1.0;
        if (t < 0.1) {
          scale = 1.0 + t * 0.8; // 快速放大
        } else if (t < 0.2) {
          scale = 1.08 - (t - 0.1) * 0.8; // 快速回缩
        } else if (t < 0.3) {
          scale = 1.0 + (t - 0.2) * 0.5; // 第二次跳动
        } else if (t < 0.4) {
          scale = 1.05 - (t - 0.3) * 0.5; // 回缩
        } else {
          scale = 1.0; // 停顿
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
