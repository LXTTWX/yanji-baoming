import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/modules/fitness/fitness_constants.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// 健身计划打卡页
class FitnessPlanPage extends StatefulWidget {
  /// 构造函数
  const FitnessPlanPage({super.key});

  @override
  State<FitnessPlanPage> createState() => _FitnessPlanPageState();
}

class _FitnessPlanPageState extends State<FitnessPlanPage> with TickerProviderStateMixin {
  final FitnessRecordRepository _recordRepository = FitnessRecordRepository();
  late TabController _planTabController;
  late TabController _dayTabController;
  
  List<FitnessRecord> _todayRecords = [];
  bool _isLoading = true;
  int _currentPlanIndex = 0;
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _planTabController = TabController(length: 3, vsync: this);
    _dayTabController = TabController(length: 7, vsync: this);
    _loadData();
    
    _planTabController.addListener(() {
      if (_planTabController.indexIsChanging) {
        setState(() {
          _currentPlanIndex = _planTabController.index;
          _currentDayIndex = 0;
          _dayTabController.animateTo(0);
        });
      }
    });
    
    _dayTabController.addListener(() {
      if (_dayTabController.indexIsChanging) {
        setState(() => _currentDayIndex = _dayTabController.index);
      }
    });
  }

  @override
  void dispose() {
    _planTabController.dispose();
    _dayTabController.dispose();
    super.dispose();
  }

  /// 加载今日打卡记录
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final records = await _recordRepository.getRecordsByDate(todayStr);
      
      setState(() {
        _todayRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('加载数据失败');
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// 检查今天是否已打卡指定计划
  bool _isTodayChecked(String planName) {
    return _todayRecords.any((r) => r.planType == planName && r.completed);
  }

  /// 执行打卡
  Future<void> _checkIn() async {
    final planName = FitnessConstants.plans[_currentPlanIndex]['name'] as String;
    
    if (_isTodayChecked(planName)) {
      _showErrorSnackBar('今日已打卡该计划');
      return;
    }

    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      
      final record = FitnessRecord(
        id: const Uuid().v4(),
        planType: planName,
        duration: 30,
        calories: 250,
        date: todayStr,
        completed: true,
        createdAt: now.toIso8601String(),
      );

      await _recordRepository.addRecord(record);
      _todayRecords.add(record);
      
      // 显示激励语
      _showEncouragementDialog(planName);
      
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('打卡失败');
    }
  }

  /// 显示激励语弹窗
  void _showEncouragementDialog(String planName) {
    final encourageWords = FitnessConstants.encourageWords;
    final relaxWords = FitnessConstants.relaxWords;
    final allWords = [...encourageWords, ...relaxWords];
    final randomWord = allWords[DateTime.now().millisecondsSinceEpoch % allWords.length];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              '打卡成功！',
              style: TextStyle(
                fontSize: MediaQuery.of(context).textScaler.scale(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已完成今日【$planName】训练',
              style: TextStyle(
                fontSize: MediaQuery.of(context).textScaler.scale(14),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                randomWord,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).textScaler.scale(16),
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '好的',
              style: TextStyle(
                fontSize: MediaQuery.of(context).textScaler.scale(16),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('健身计划'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('健身计划'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        bottom: TabBar(
          controller: _planTabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '居家减脂'),
            Tab(text: '徒手增肌'),
            Tab(text: '肩颈放松'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDayTabs(context, padding, fontSize),
          Expanded(
            child: _buildPlanContent(context, padding, fontSize),
          ),
          _buildCheckInButton(context, padding, fontSize),
        ],
      ),
    );
  }

  /// 构建日期标签页
  Widget _buildDayTabs(BuildContext context, double padding, double fontSize) {
    final days = FitnessConstants.plans[_currentPlanIndex]['days'] as List;
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: padding * 0.5),
      child: TabBar(
        controller: _dayTabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: fontSize),
        tabs: days.map((day) {
          final dayNum = day['day'] as int;
          return Tab(text: '第$dayNum天');
        }).toList(),
      ),
    );
  }

  /// 构建计划内容
  Widget _buildPlanContent(BuildContext context, double padding, double fontSize) {
    final plan = FitnessConstants.plans[_currentPlanIndex];
    final days = plan['days'] as List;
    final currentDay = days[_currentDayIndex];
    final exercises = currentDay['exercises'] as List;
    final dayName = currentDay['name'] as String;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(context, dayName, padding, fontSize),
          SizedBox(height: padding),
          ...exercises.map((exercise) => _buildExerciseCard(
            context,
            exercise['name'] as String,
            exercise['sets'] as String,
            exercise['reps'] as String,
            exercise['tip'] as String,
            padding,
            fontSize,
          )),
        ],
      ),
    );
  }

  /// 构建日期标题
  Widget _buildDayHeader(BuildContext context, String dayName, double padding, double fontSize) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primaryLight.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: AppColors.primary, size: fontSize * 1.5),
          SizedBox(width: padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: fontSize * 1.3,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: padding * 0.3),
                Text(
                  '今日训练内容',
                  style: TextStyle(
                    fontSize: fontSize * 0.9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建动作卡片
  Widget _buildExerciseCard(
    BuildContext context,
    String name,
    String sets,
    String reps,
    String tip,
    double padding,
    double fontSize,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: padding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 0.8,
                    vertical: padding * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$sets × $reps',
                    style: TextStyle(
                      fontSize: fontSize * 0.9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: padding * 0.8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: fontSize * 1.2,
                  color: AppColors.accent,
                ),
                SizedBox(width: padding * 0.5),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建打卡按钮
  Widget _buildCheckInButton(BuildContext context, double padding, double fontSize) {
    final planName = FitnessConstants.plans[_currentPlanIndex]['name'] as String;
    final isChecked = _isTodayChecked(planName);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isChecked ? null : _checkIn,
          icon: Icon(
            isChecked ? Icons.check_circle : Icons.fitness_center,
            size: 24,
          ),
          label: Text(
            isChecked ? '今日已打卡' : '一键打卡',
            style: TextStyle(fontSize: fontSize * 1.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isChecked ? AppColors.success : AppColors.primary,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isChecked ? 0 : 4,
          ),
        ),
      ),
    );
  }
}
