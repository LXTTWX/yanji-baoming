import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/constants/medical_constants.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';
import 'package:yanji/modules/fitness/fitness_constants.dart';

/// 成就勋章页面
class FitnessAchievementPage extends StatefulWidget {
  /// 构造函数
  const FitnessAchievementPage({super.key});

  @override
  State<FitnessAchievementPage> createState() => _FitnessAchievementPageState();
}

class _FitnessAchievementPageState extends State<FitnessAchievementPage> {
  final FitnessRecordRepository _fitnessRepo = FitnessRecordRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();
  
  List<FitnessRecord> _allRecords = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  
  // 勋章数据
  List<Map<String, dynamic>> _achievements = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    try {
      final records = await _fitnessRepo.getAllRecords();
      final profile = await _profileRepo.getProfile();
      
      setState(() {
        _allRecords = records;
        _userProfile = profile;
        _calculateAchievements();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 计算勋章解锁状态
  void _calculateAchievements() {
    _achievements = FitnessConstants.achievements.map((achievement) {
      final unlocked = _checkAchievementUnlocked(achievement);
      final unlockedDate = unlocked ? _getUnlockedDate(achievement) : null;
      
      return {
        ...achievement,
        'unlocked': unlocked,
        'unlockedDate': unlockedDate,
      };
    }).toList();
  }
  
  /// 检查勋章是否解锁
  bool _checkAchievementUnlocked(Map<String, dynamic> achievement) {
    final type = achievement['type'] as String;
    final value = achievement['value'] as int;
    
    switch (type) {
      case 'streak':
        return _checkStreakAchievement(value);
      case 'total':
        return _checkTotalAchievement(value);
      case 'bmi':
        return _checkBmiAchievement();
      default:
        return false;
    }
  }
  
  /// 检查连续打卡成就
  bool _checkStreakAchievement(int requiredDays) {
    final completedRecords = _allRecords.where((r) => r.completed).toList();
    if (completedRecords.isEmpty) return false;
    
    completedRecords.sort((a, b) => b.date.compareTo(a.date));
    int consecutive = 0;
    String? lastDate;
    
    for (final record in completedRecords) {
      if (lastDate == null) {
        lastDate = record.date;
        consecutive = 1;
      } else {
        final last = DateTime.parse(lastDate);
        final current = DateTime.parse(record.date);
        final diff = last.difference(current).inDays;
        if (diff == 1) {
          consecutive++;
          lastDate = record.date;
        } else {
          break;
        }
      }
    }
    
    return consecutive >= requiredDays;
  }
  
  /// 检查累计训练成就
  bool _checkTotalAchievement(int requiredDays) {
    final totalDays = _allRecords.where((r) => r.completed).length;
    return totalDays >= requiredDays;
  }
  
  /// 检查BMI成就
  bool _checkBmiAchievement() {
    if (_userProfile == null) return false;
    
    final bmi = _userProfile?.calculateBMI();
    if (bmi == null) return false;
    
    return bmi >= MedicalConstants.bmiUnderweight && 
           bmi < MedicalConstants.bmiNormalMax;
  }
  
  /// 获取解锁日期
  String? _getUnlockedDate(Map<String, dynamic> achievement) {
    final type = achievement['type'] as String;
    
    if (type == 'streak' || type == 'total') {
      // 获取最近一次完成记录的日期
      final completedRecords = _allRecords.where((r) => r.completed).toList();
      if (completedRecords.isNotEmpty) {
        completedRecords.sort((a, b) => b.date.compareTo(a.date));
        return completedRecords.first.date;
      }
    } else if (type == 'bmi') {
      // BMI成就使用当前日期
      return DateTime.now().toIso8601String().substring(0, 10);
    }
    
    return null;
  }
  
  /// 获取勋章图标
  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'health_and_safety':
        return Icons.health_and_safety;
      default:
        return Icons.star;
    }
  }
  
  /// 生成分享卡片
  void _generateShareCard(Map<String, dynamic> achievement) {
    // 预留截图接口
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享功能开发中，敬请期待'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final isElderMode = MediaQuery.of(context).textScaler.scale(1) > 1.1;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就勋章'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 成就统计
                  _buildAchievementStats(context, padding, isElderMode),
                  SizedBox(height: padding),
                  
                  // 已解锁勋章
                  _buildUnlockedSection(context, padding, isElderMode),
                  SizedBox(height: padding),
                  
                  // 未解锁勋章
                  _buildLockedSection(context, padding, isElderMode),
                ],
              ),
            ),
    );
  }
  
  /// 构建成就统计
  Widget _buildAchievementStats(BuildContext context, double padding, bool isElderMode) {
    final unlockedCount = _achievements.where((a) => a['unlocked'] == true).length;
    final totalCount = _achievements.length;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(padding * 1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.1),
              AppColors.accentLight.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '$unlockedCount',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontSize: isElderMode ? 36 : 32,
                  ),
                ),
                Text(
                  '已解锁',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isElderMode ? 16 : 14,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: MediaQuery.of(context).size.height * 0.06,
              color: AppColors.divider,
            ),
            Column(
              children: [
                Text(
                  '$totalCount',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: isElderMode ? 36 : 32,
                  ),
                ),
                Text(
                  '总勋章',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isElderMode ? 16 : 14,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: MediaQuery.of(context).size.height * 0.06,
              color: AppColors.divider,
            ),
            Column(
              children: [
                Text(
                  '${((unlockedCount / totalCount) * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: isElderMode ? 36 : 32,
                  ),
                ),
                Text(
                  '完成度',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isElderMode ? 16 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建已解锁勋章区域
  Widget _buildUnlockedSection(BuildContext context, double padding, bool isElderMode) {
    final unlockedAchievements = _achievements.where((a) => a['unlocked'] == true).toList();
    
    if (unlockedAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已解锁勋章',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isElderMode ? 20 : 16,
          ),
        ),
        SizedBox(height: padding * 0.5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            childAspectRatio: 0.8,
          ),
          itemCount: unlockedAchievements.length,
          itemBuilder: (context, index) {
            return _buildAchievementCard(
              context,
              unlockedAchievements[index],
              true,
              padding,
              isElderMode,
            );
          },
        ),
      ],
    );
  }
  
  /// 构建未解锁勋章区域
  Widget _buildLockedSection(BuildContext context, double padding, bool isElderMode) {
    final lockedAchievements = _achievements.where((a) => a['unlocked'] != true).toList();
    
    if (lockedAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未解锁勋章',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isElderMode ? 20 : 16,
          ),
        ),
        SizedBox(height: padding * 0.5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            childAspectRatio: 0.8,
          ),
          itemCount: lockedAchievements.length,
          itemBuilder: (context, index) {
            return _buildAchievementCard(
              context,
              lockedAchievements[index],
              false,
              padding,
              isElderMode,
            );
          },
        ),
      ],
    );
  }
  
  /// 构建成就卡片
  Widget _buildAchievementCard(
    BuildContext context,
    Map<String, dynamic> achievement,
    bool isUnlocked,
    double padding,
    bool isElderMode,
  ) {
    final iconName = achievement['icon'] as String;
    final name = achievement['name'] as String;
    final condition = achievement['condition'] as String;
    final unlockedDate = achievement['unlockedDate'] as String?;
    
    final iconColor = isUnlocked ? AppColors.accent : AppColors.textHint;
    final backgroundColor = isUnlocked 
        ? AppColors.accent.withValues(alpha: 0.1)
        : AppColors.textHint.withValues(alpha: 0.05);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isUnlocked ? () => _generateShareCard(achievement) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: backgroundColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 勋章图标
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked 
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.textHint.withValues(alpha: 0.1),
                ),
                child: Icon(
                  _getAchievementIcon(iconName),
                  size: isElderMode ? 40 : 36,
                  color: iconColor,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.03),
              
              // 勋章名称
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: isElderMode ? 18 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.01),
              
              // 解锁条件或解锁日期
              Text(
                isUnlocked 
                    ? '解锁于 ${unlockedDate ?? '未知'}'
                    : condition,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnlocked ? AppColors.success : AppColors.textHint,
                  fontSize: isElderMode ? 14 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              
              // 已解锁标识
              if (isUnlocked) ...[
                SizedBox(height: MediaQuery.of(context).size.width * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.02,
                    vertical: MediaQuery.of(context).size.width * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '已解锁',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: isElderMode ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}