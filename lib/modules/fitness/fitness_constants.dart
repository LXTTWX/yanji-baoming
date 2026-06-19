/// 健身模块常量配置
class FitnessConstants {
  /// 3套7天健身计划
  static const List<Map<String, dynamic>> plans = [
    {
      'name': '居家减脂',
      'description': '适合初学者的减脂训练',
      'icon': 'local_fire_department',
      'days': [
        {
          'day': 1,
          'name': '全身燃脂',
          'exercises': [
            {'name': '开合跳', 'sets': '3组', 'reps': '30次', 'tip': '保持节奏，手臂充分展开'},
            {'name': '高抬腿', 'sets': '3组', 'reps': '20次', 'tip': '膝盖尽量抬高，保持核心收紧'},
            {'name': '波比跳', 'sets': '3组', 'reps': '10次', 'tip': '动作连贯，下蹲时手撑地'},
            {'name': '登山跑', 'sets': '3组', 'reps': '20次', 'tip': '保持俯卧撑姿势，交替收腿'},
          ],
        },
        {
          'day': 2,
          'name': '下肢燃脂',
          'exercises': [
            {'name': '深蹲', 'sets': '3组', 'reps': '15次', 'tip': '膝盖不超过脚尖，臀部后坐'},
            {'name': '弓步蹲', 'sets': '3组', 'reps': '12次', 'tip': '前后腿呈90度，躯干直立'},
            {'name': '侧弓步', 'sets': '3组', 'reps': '10次', 'tip': '向侧方迈大步，膝盖弯曲'},
            {'name': '臀桥', 'sets': '3组', 'reps': '15次', 'tip': '臀部发力，顶峰收缩'},
          ],
        },
        {
          'day': 3,
          'name': '上肢燃脂',
          'exercises': [
            {'name': '俯卧撑', 'sets': '3组', 'reps': '10次', 'tip': '身体呈一条直线，可跪姿简化'},
            {'name': '臂屈伸', 'sets': '3组', 'reps': '12次', 'tip': '利用椅子边缘，缓慢下放'},
            {'name': '肩部画圈', 'sets': '3组', 'reps': '20次', 'tip': '手臂伸直，大幅度画圈'},
            {'name': '平板支撑', 'sets': '3组', 'reps': '30秒', 'tip': '保持身体平直，核心收紧'},
          ],
        },
        {
          'day': 4,
          'name': '核心燃脂',
          'exercises': [
            {'name': '卷腹', 'sets': '3组', 'reps': '15次', 'tip': '下背贴地，肩胛骨离地'},
            {'name': '仰卧蹬车', 'sets': '3组', 'reps': '20次', 'tip': '对侧肘碰膝，动作缓慢'},
            {'name': '俄罗斯转体', 'sets': '3组', 'reps': '20次', 'tip': '双脚离地，躯干左右转动'},
            {'name': '仰卧举腿', 'sets': '3组', 'reps': '12次', 'tip': '双腿伸直，缓慢上下'},
          ],
        },
        {
          'day': 5,
          'name': '全身HIIT',
          'exercises': [
            {'name': '开合跳', 'sets': '4组', 'reps': '30次', 'tip': '保持节奏'},
            {'name': '深蹲跳', 'sets': '4组', 'reps': '10次', 'tip': '下蹲后爆发起跳'},
            {'name': '俯卧撑', 'sets': '4组', 'reps': '8次', 'tip': '控制速度'},
            {'name': '高抬腿', 'sets': '4组', 'reps': '20次', 'tip': '快速交替'},
          ],
        },
        {
          'day': 6,
          'name': '下肢强化',
          'exercises': [
            {'name': '蛙跳', 'sets': '3组', 'reps': '10次', 'tip': '蹲下后向前跳跃'},
            {'name': '单腿深蹲', 'sets': '3组', 'reps': '8次', 'tip': '扶墙辅助，缓慢下蹲'},
            {'name': '小腿提踵', 'sets': '3组', 'reps': '20次', 'tip': '站在台阶边缘，上下踮脚'},
            {'name': '靠墙静蹲', 'sets': '3组', 'reps': '30秒', 'tip': '大腿与地面平行'},
          ],
        },
        {
          'day': 7,
          'name': '拉伸放松',
          'exercises': [
            {'name': '全身拉伸', 'sets': '1组', 'reps': '10分钟', 'tip': '每个部位保持15-30秒'},
            {'name': '泡沫轴放松', 'sets': '1组', 'reps': '10分钟', 'tip': '缓慢滚动，找到痛点停留'},
            {'name': '深呼吸冥想', 'sets': '1组', 'reps': '5分钟', 'tip': '闭眼，腹式呼吸'},
          ],
        },
      ],
    },
    {
      'name': '徒手增肌',
      'description': '无需器械的力量训练',
      'icon': 'fitness_center',
      'days': [
        {
          'day': 1,
          'name': '胸部训练',
          'exercises': [
            {'name': '标准俯卧撑', 'sets': '4组', 'reps': '12次', 'tip': '手距略宽于肩，胸部发力'},
            {'name': '窄距俯卧撑', 'sets': '3组', 'reps': '10次', 'tip': '双手靠近，锻炼三头肌'},
            {'name': '宽距俯卧撑', 'sets': '3组', 'reps': '10次', 'tip': '双手宽于肩，锻炼胸外侧'},
            {'name': '俯卧撑击掌', 'sets': '3组', 'reps': '8次', 'tip': '爆发力推起，空中击掌'},
            {'name': '钻石俯卧撑', 'sets': '3组', 'reps': '8次', 'tip': '双手拇指食指相对'},
          ],
        },
        {
          'day': 2,
          'name': '背部训练',
          'exercises': [
            {'name': '超人式', 'sets': '4组', 'reps': '15次', 'tip': '俯卧，同时抬起四肢'},
            {'name': '俯卧Y字举', 'sets': '3组', 'reps': '12次', 'tip': '手臂呈Y字上举'},
            {'name': '俯卧T字举', 'sets': '3组', 'reps': '12次', 'tip': '手臂呈T字侧举'},
            {'name': '俯卧W字举', 'sets': '3组', 'reps': '12次', 'tip': '手臂呈W字后拉'},
            {'name': '反向划船', 'sets': '3组', 'reps': '10次', 'tip': '利用桌子边缘，身体后倾'},
          ],
        },
        {
          'day': 3,
          'name': '腿部训练',
          'exercises': [
            {'name': '深蹲', 'sets': '4组', 'reps': '15次', 'tip': '臀部后坐，膝盖不超过脚尖'},
            {'name': '保加利亚蹲', 'sets': '3组', 'reps': '12次', 'tip': '后脚搭椅子，前腿下蹲'},
            {'name': '罗马尼亚硬拉', 'sets': '3组', 'reps': '12次', 'tip': '微屈膝，臀部后推'},
            {'name': '臀桥', 'sets': '4组', 'reps': '15次', 'tip': '顶峰收缩2秒'},
            {'name': '小腿提踵', 'sets': '4组', 'reps': '20次', 'tip': '站在台阶边缘'},
          ],
        },
        {
          'day': 4,
          'name': '肩部训练',
          'exercises': [
            {'name': '俯卧撑派克', 'sets': '4组', 'reps': '10次', 'tip': '身体呈倒V字，下压头部'},
            {'name': '侧平举', 'sets': '3组', 'reps': '15次', 'tip': '手臂伸直侧举，可用瓶子'},
            {'name': '前平举', 'sets': '3组', 'reps': '15次', 'tip': '手臂伸直前举'},
            {'name': '肩部画圈', 'sets': '3组', 'reps': '20次', 'tip': '大幅度画圈'},
            {'name': '靠墙倒立', 'sets': '3组', 'reps': '30秒', 'tip': '初学者可半倒立'},
          ],
        },
        {
          'day': 5,
          'name': '手臂训练',
          'exercises': [
            {'name': '窄距俯卧撑', 'sets': '4组', 'reps': '12次', 'tip': '重点锻炼三头肌'},
            {'name': '臂屈伸', 'sets': '4组', 'reps': '12次', 'tip': '利用椅子边缘'},
            {'name': '反向臂屈伸', 'sets': '3组', 'reps': '10次', 'tip': '身体面向椅子'},
            {'name': '弯举', 'sets': '3组', 'reps': '15次', 'tip': '可用书本或水瓶'},
            {'name': '锤式弯举', 'sets': '3组', 'reps': '15次', 'tip': '掌心相对'},
          ],
        },
        {
          'day': 6,
          'name': '核心训练',
          'exercises': [
            {'name': '平板支撑', 'sets': '4组', 'reps': '60秒', 'tip': '身体平直，核心收紧'},
            {'name': '侧平板支撑', 'sets': '3组', 'reps': '30秒', 'tip': '每侧都要做'},
            {'name': '卷腹', 'sets': '4组', 'reps': '20次', 'tip': '下背贴地'},
            {'name': '仰卧举腿', 'sets': '3组', 'reps': '15次', 'tip': '双腿伸直'},
            {'name': '俄罗斯转体', 'sets': '3组', 'reps': '20次', 'tip': '双脚离地'},
          ],
        },
        {
          'day': 7,
          'name': '休息拉伸',
          'exercises': [
            {'name': '全身拉伸', 'sets': '1组', 'reps': '15分钟', 'tip': '每个部位保持30秒'},
            {'name': '瑜伽拜日式', 'sets': '1组', 'reps': '5轮', 'tip': '配合呼吸，动作流畅'},
            {'name': '冥想放松', 'sets': '1组', 'reps': '10分钟', 'tip': '专注呼吸，放松身心'},
          ],
        },
      ],
    },
    {
      'name': '肩颈放松',
      'description': '缓解久坐带来的不适',
      'icon': 'self_improvement',
      'days': [
        {
          'day': 1,
          'name': '颈部放松',
          'exercises': [
            {'name': '颈部前后屈伸', 'sets': '3组', 'reps': '10次', 'tip': '缓慢低头抬头，不要用力'},
            {'name': '颈部左右侧屈', 'sets': '3组', 'reps': '10次', 'tip': '耳朵找肩膀，对侧肩膀下沉'},
            {'name': '颈部左右旋转', 'sets': '3组', 'reps': '10次', 'tip': '下巴找肩膀，缓慢转动'},
          ],
        },
        {
          'day': 2,
          'name': '肩部放松',
          'exercises': [
            {'name': '耸肩放松', 'sets': '3组', 'reps': '15次', 'tip': '肩膀尽量靠近耳朵，然后放松'},
            {'name': '肩部前后画圈', 'sets': '3组', 'reps': '15次', 'tip': '大幅度画圈，放松肩关节'},
            {'name': '肩部开合', 'sets': '3组', 'reps': '12次', 'tip': '双手抱头，肘部开合'},
          ],
        },
        {
          'day': 3,
          'name': '上背放松',
          'exercises': [
            {'name': '猫牛式', 'sets': '3组', 'reps': '10次', 'tip': '四点跪姿，交替弓背塌腰'},
            {'name': '婴儿式', 'sets': '3组', 'reps': '30秒', 'tip': '臀部坐脚后跟，手臂前伸'},
            {'name': '仰卧扭转', 'sets': '3组', 'reps': '30秒', 'tip': '双膝并拢倒向一侧'},
          ],
        },
        {
          'day': 4,
          'name': '胸椎灵活',
          'exercises': [
            {'name': '胸椎旋转', 'sets': '3组', 'reps': '10次', 'tip': '四点跪姿，一手扶头旋转'},
            {'name': '胸椎伸展', 'sets': '3组', 'reps': '10次', 'tip': '泡沫轴放在上背后仰'},
            {'name': '开胸运动', 'sets': '3组', 'reps': '12次', 'tip': '双手后伸，挺胸'},
          ],
        },
        {
          'day': 5,
          'name': '手臂放松',
          'exercises': [
            {'name': '手腕旋转', 'sets': '3组', 'reps': '15次', 'tip': '顺时针逆时针各做'},
            {'name': '手指伸展', 'sets': '3组', 'reps': '10次', 'tip': '张开手指，握拳'},
            {'name': '前臂拉伸', 'sets': '3组', 'reps': '30秒', 'tip': '手掌朝上朝下各拉伸'},
          ],
        },
        {
          'day': 6,
          'name': '综合放松',
          'exercises': [
            {'name': '颈部综合', 'sets': '2组', 'reps': '5分钟', 'tip': '前后左右旋转组合'},
            {'name': '肩部综合', 'sets': '2组', 'reps': '5分钟', 'tip': '耸肩画圈开合组合'},
            {'name': '背部综合', 'sets': '2组', 'reps': '5分钟', 'tip': '猫牛式婴儿式组合'},
          ],
        },
        {
          'day': 7,
          'name': '深度放松',
          'exercises': [
            {'name': '渐进式肌肉放松', 'sets': '1组', 'reps': '15分钟', 'tip': '从头到脚依次紧张放松'},
            {'name': '深呼吸冥想', 'sets': '1组', 'reps': '10分钟', 'tip': '腹式呼吸，专注当下'},
            {'name': '全身拉伸', 'sets': '1组', 'reps': '10分钟', 'tip': '每个部位保持30秒'},
          ],
        },
      ],
    },
  ];

  /// 20条激励语（10条鼓励型+10条轻松型）
  static const List<String> encourageWords = [
    '太棒了！你今天又坚持了一天！',
    '每一次锻炼都是对自己的投资！',
    '你比想象中更强大！',
    '坚持就是胜利，加油！',
    '今天的汗水，明天的收获！',
    '你正在变得更好！',
    '自律给你自由！',
    '没有人能阻止你变得更好！',
    '你的努力终将开花结果！',
    '继续前进，不要停下脚步！',
  ];

  static const List<String> relaxWords = [
    '完成！去喝杯水休息一下吧~',
    '今天也辛苦啦，犒劳下自己！',
    '运动结束，感觉整个人都轻松了~',
    '做得不错，继续保持哦~',
    '锻炼完毕，可以安心追剧啦！',
    '今天的任务完成，给自己点个赞！',
    '运动使人快乐，你感受到了吗？',
    '结束！记得拉伸放松哦~',
    '又完成一天，离目标更近了！',
    '好样的！明天继续加油~',
  ];

  /// 成就勋章数据
  static const List<Map<String, dynamic>> achievements = [
    {
      'id': 'streak_7',
      'name': '坚持7天',
      'description': '连续打卡7天',
      'icon': 'emoji_events',
      'condition': '连续打卡7天',
      'type': 'streak',
      'value': 7,
    },
    {
      'id': 'streak_30',
      'name': '坚持30天',
      'description': '连续打卡30天',
      'icon': 'military_tech',
      'condition': '连续打卡30天',
      'type': 'streak',
      'value': 30,
    },
    {
      'id': 'total_100',
      'name': '累计100天',
      'description': '累计训练100天',
      'icon': 'workspace_premium',
      'condition': '累计训练100天',
      'type': 'total',
      'value': 100,
    },
    {
      'id': 'weight_goal',
      'name': '体重达标',
      'description': '体重达到目标范围',
      'icon': 'monitor_weight',
      'condition': 'BMI在18.5-24之间',
      'type': 'bmi',
      'value': 0,
    },
    {
      'id': 'bmi_normal',
      'name': 'BMI正常',
      'description': 'BMI保持正常范围',
      'icon': 'health_and_safety',
      'condition': 'BMI在18.5-24之间',
      'type': 'bmi',
      'value': 0,
    },
  ];
}