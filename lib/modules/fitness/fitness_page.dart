import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/theme/design_system.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/widgets/check_in_toast.dart';

/// 健身页面（家檐安记风格）
///
/// 年轻人自律陪伴，极简大留白大圆角设计。
/// 包含：本周进度卡片、今日计划卡片、体重变化图表。
class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key});

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  final FitnessRecordRepository _fitnessRepo = FitnessRecordRepository();

  int _weekCompletedDays = 0;
  int _consecutiveDays = 0;
  List<FitnessRecord> _todayRecords = [];
  List<double> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    try {
      final allRecords = await _fitnessRepo.getAllRecords();

      // 本周打卡天数
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekRecords = allRecords.where((r) {
        try {
          final d = DateTime.parse(r.date);
          return d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              d.isBefore(now.add(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
      final weekDays = weekRecords.map((r) => r.date.substring(0, 10)).toSet();

      // 连续打卡天数
      int consecutive = 0;
      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateStr =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (weekDays.contains(dateStr) || allRecords.any((r) => r.date.startsWith(dateStr))) {
          consecutive++;
        } else if (i > 0) {
          break;
        }
      }

      // 今日记录
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final today = allRecords.where((r) => r.date.startsWith(todayStr)).toList();

      // 体重历史（近30天）
      final weightRecords = allRecords
          .where((r) => r.planType == '体重' || r.planType == 'weight')
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final allWeights = weightRecords.map((r) {
        try {
          return double.parse(r.note ?? '0');
        } catch (_) {
          return 0.0;
        }
      }).where((w) => w > 0).toList();
      final weights = allWeights.length > 30
          ? allWeights.sublist(allWeights.length - 30)
          : allWeights;

      setState(() {
        _weekCompletedDays = weekDays.length;
        _consecutiveDays = consecutive;
        _todayRecords = today;
        _weightHistory = weights;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// 获取今日计划项（模拟肩颈放松计划）
  List<Map<String, dynamic>> get _todayPlanItems {
    return [
      {'name': '颈部前后拉伸', 'done': _todayRecords.any((r) => (r.note ?? '').contains('颈部前后'))},
      {'name': '肩部环绕运动', 'done': _todayRecords.any((r) => (r.note ?? '').contains('肩部环绕'))},
      {'name': '上背部伸展', 'done': _todayRecords.any((r) => (r.note ?? '').contains('上背部'))},
      {'name': '深呼吸放松', 'done': _todayRecords.any((r) => (r.note ?? '').contains('深呼吸'))},
    ];
  }

  /// 打卡
  Future<void> _checkIn(String itemName) async {
    final now = DateTime.now();
    final record = FitnessRecord(
      id: 'fitness_${now.millisecondsSinceEpoch}',
      planType: '肩颈放松',
      date: now.toIso8601String(),
      duration: 5,
      calories: 0,
      completed: true,
      note: itemName,
      createdAt: now.toIso8601String(),
    );
    await _fitnessRepo.addRecord(record);
    if (mounted) CheckInToast.show(context, '打卡成功！坚持就是胜利 🎉');
    await _loadData();
  }

  /// 整体打卡
  Future<void> _checkInAll() async {
    final now = DateTime.now();
    final record = FitnessRecord(
      id: 'fitness_all_${now.millisecondsSinceEpoch}',
      planType: '肩颈放松',
      date: now.toIso8601String(),
      duration: 20,
      calories: 30,
      completed: true,
      note: '完成全部肩颈放松计划',
      createdAt: now.toIso8601String(),
    );
    await _fitnessRepo.addRecord(record);
    if (mounted) CheckInToast.show(context, '打卡成功！坚持就是胜利 🎉');
    await _loadData();
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
                      _buildWeekProgressCard(sw),
                      SizedBox(height: padding * 0.6),
                      _buildTodayPlanCard(sw),
                      SizedBox(height: padding * 0.6),
                      _buildWeightChartCard(sw),
                      SizedBox(height: padding * 0.6),
                      _buildQuickNavRow(sw),
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
        Text('健身打卡', style: DesignSystem.pageTitle()),
      ],
    );
  }

  /// 本周进度卡片
  Widget _buildWeekProgressCard(double sw) {
    final completed = _weekCompletedDays.clamp(0, 7);
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('本周进度', style: DesignSystem.cardSubtitle()),
              Text('$completed / 7 天',
                  style: DesignSystem.dataNumber(
                      color: AppColors.terracotta, size: 16)),
            ],
          ),
          SizedBox(height: sw * 0.04),
          // 7 个进度条
          Row(
            children: List.generate(7, (i) {
              final isDone = i < completed;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 6 ? sw * 0.015 : 0),
                  height: sw * 0.03,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.terracotta : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(sw * 0.015),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 今日计划卡片（核心）
  Widget _buildTodayPlanCard(double sw) {
    final items = _todayPlanItems;
    final allDone = items.every((i) => i['done'] == true);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('肩颈放松', style: DesignSystem.cardTitle()),
              const StatusTag(text: '入门', color: AppColors.sage),
            ],
          ),
          SizedBox(height: sw * 0.04),
          // 计划列表
          ...items.map((item) => _buildPlanItem(sw, item)),
          SizedBox(height: sw * 0.03),
          // 底部交互区
          Container(
            padding: EdgeInsets.only(top: sw * 0.04),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('连续打卡',
                        style: DesignSystem.cardSubtitle(size: 12)),
                    Text('第 $_consecutiveDays 天',
                        style: TextStyle(
                          fontFamily: DesignSystem.serif,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        )),
                  ],
                ),
                GestureDetector(
                  onTap: allDone ? null : _checkInAll,
                  child: Container(
                    width: sw * 0.14,
                    height: sw * 0.14,
                    decoration: BoxDecoration(
                      color: allDone ? AppColors.sage : AppColors.terracotta,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (allDone ? AppColors.sage : AppColors.terracotta)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      allDone ? Icons.check : Icons.check,
                      color: Colors.white,
                      size: sw * 0.07,
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

  /// 单个计划项
  Widget _buildPlanItem(double sw, Map<String, dynamic> item) {
    final isDone = item['done'] as bool;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.02),
      child: Row(
        children: [
          // 勾选图标
          Container(
            width: sw * 0.06,
            height: sw * 0.06,
            decoration: BoxDecoration(
              color: isDone ? AppColors.sage : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.sage : AppColors.borderLight,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          SizedBox(width: sw * 0.03),
          // 动作名称
          Expanded(
            child: Text(
              item['name'] as String,
              style: DesignSystem.body(
                color: isDone ? AppColors.taupe : AppColors.charcoal,
              ),
            ),
          ),
          // 状态/按钮
          if (isDone)
            Text('已完成',
                style: DesignSystem.cardSubtitle(size: 13))
          else
            GestureDetector(
              onTap: () => _checkIn(item['name'] as String),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.04, vertical: sw * 0.02),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('打卡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  /// 体重变化卡片
  Widget _buildWeightChartCard(double sw) {
    final hasData = _weightHistory.length >= 2;
    double? weightChange;
    if (hasData) {
      weightChange = _weightHistory.last - _weightHistory.first;
    }

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('体重变化 (30天)', style: DesignSystem.cardSubtitle()),
              if (weightChange != null)
                StatusTag(
                  text: '${weightChange < 0 ? '↓' : '↑'} ${weightChange.abs().toStringAsFixed(1)} kg',
                  color: weightChange < 0 ? AppColors.sage : AppColors.rose,
                ),
            ],
          ),
          SizedBox(height: sw * 0.04),
          SizedBox(
            height: sw * 0.35,
            child: hasData
                ? CustomPaint(
                    painter: _WeightChartPainter(
                      data: _weightHistory,
                      lineColor: AppColors.terracotta,
                    ),
                    size: Size.infinite,
                  )
                : Center(
                    child: Text('暂无体重数据',
                        style: DesignSystem.cardSubtitle()),
                  ),
          ),
        ],
      ),
    );
  }

  /// 快捷导航行
  Widget _buildQuickNavRow(double sw) {
    return Row(
      children: [
        Expanded(
          child: _buildNavChip(
            sw,
            icon: Icons.person_outline,
            label: '身体档案',
            onTap: () => context.push('/fitness/profile'),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _buildNavChip(
            sw,
            icon: Icons.bar_chart_outlined,
            label: '健身统计',
            onTap: () => context.push('/fitness/stats'),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _buildNavChip(
            sw,
            icon: Icons.emoji_events_outlined,
            label: '成就勋章',
            onTap: () => context.push('/fitness/achievement'),
          ),
        ),
      ],
    );
  }

  /// 导航小卡片
  Widget _buildNavChip(double sw,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sw * 0.04),
        decoration: DesignSystem.cardDecoration(),
        child: Column(
          children: [
            Icon(icon, color: AppColors.terracotta, size: sw * 0.06),
            SizedBox(height: sw * 0.02),
            Text(label, style: DesignSystem.cardSubtitle(size: 12)),
          ],
        ),
      ),
    );
  }
}

/// 体重折线图绘制器
class _WeightChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _WeightChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(0.1, double.infinity);

    final w = size.width;
    final h = size.height;
    final padding = h * 0.15;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (w / (data.length - 1)) * i;
      final y = padding + (h - padding * 2) * (1 - (data[i] - minVal) / range);
      points.add(Offset(x, y));
    }

    // 绘制平滑曲线
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, paint);

    // 末端圆点
    final last = points.last;
    canvas.drawCircle(last, 5, dotPaint);
    canvas.drawCircle(last, 8, Paint()..color = lineColor.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      data != oldDelegate.data;
}
