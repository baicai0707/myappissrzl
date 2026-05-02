import 'package:flutter/material.dart';

// ============================================================
// 记账分类
// ============================================================

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.name, this.icon, this.color);
}

const List<CategoryInfo> expenseCategories = [
  CategoryInfo('餐饮', Icons.restaurant, Color(0xFFF97316)),
  CategoryInfo('交通', Icons.directions_car, Color(0xFF3B82F6)),
  CategoryInfo('购物', Icons.shopping_bag, Color(0xFFEC4899)),
  CategoryInfo('娱乐', Icons.sports_esports, Color(0xFF8B5CF6)),
  CategoryInfo('住房', Icons.home, Color(0xFF14B8A6)),
  CategoryInfo('医疗', Icons.local_hospital, Color(0xFFEF4444)),
  CategoryInfo('教育', Icons.school, Color(0xFFF59E0B)),
  CategoryInfo('其他', Icons.more_horiz, Color(0xFF6B7280)),
];

const List<CategoryInfo> incomeCategories = [
  CategoryInfo('工资', Icons.account_balance, Color(0xFF10B981)),
  CategoryInfo('兼职', Icons.work, Color(0xFF3B82F6)),
  CategoryInfo('投资', Icons.trending_up, Color(0xFF8B5CF6)),
  CategoryInfo('红包', Icons.card_giftcard, Color(0xFFEF4444)),
  CategoryInfo('其他', Icons.more_horiz, Color(0xFF6B7280)),
];

// ============================================================
// 版本历史
// ============================================================

final List<Map<String, dynamic>> versionHistory = [
  {
    'version': '2.4.0',
    'date': '2026-05-01',
    'isLatest': true,
    'changes': [
      '全局替换 SnackBar 为自定义 Toast 组件，通知样式更统一美观',
      '新增 CustomToast 组件，支持成功、错误、警告、信息四种提示类型',
      '优化了消息提示的动画效果和视觉体验',
      '修复了一些已知问题',
    ],
  },
  {
    'version': '2.3.1',
    'date': '2026-05-01',
    'isLatest': false,
    'changes': [
      '修复了一些已知问题',
    ],
  },
  {
    'version': '2.3.0',
    'date': '2026-05-01',
    'isLatest': false,
    'changes': [
      '全新课表功能：支持手动添加课程，设置上课时间、教室、教师和起止周数',
      '版本更新弹窗已上线',
      '修复了一些已知问题',
    ],
  },
  {
    'version': '2.2.1',
    'date': '2026-04-30',
    'isLatest': false,
    'changes': [
      '彻底修复记事本无法删除的问题，重写了删除逻辑',
      '记事本提醒功能优化，通知异常不再影响核心操作',
      '提升记事本数据加载的容错能力',
    ],
  },
  {
    'version': '2.2.0',
    'date': '2026-04-30',
    'isLatest': false,
    'changes': [
      '全新界面设计，采用"轻未来感"风格，配色更舒适、布局更精致',
      '首页新增个性化功能排序，长按即可调整功能卡片顺序',
      '关于页面全面改版，展示已上线功能与未来规划蓝图',
      '记事本UI升级，优先级标签增加方向图标',
      '侧边栏视觉优化，等级信息改为胶囊标签样式',
      '修复了一些已知问题',
    ],
  },
  {
    'version': '2.1.1',
    'date': '2026-04-29',
    'isLatest': false,
    'changes': [
      '修复了一个导致部分用户无法正常使用记事本功能的严重bug',
    ],
  },
  {
    'version': '2.1.0',
    'date': '2026-04-29',
    'isLatest': false,
    'changes': [
      '新增记事本：支持文本记录和事件提醒',
      '调整了底层架构，提升了性能和稳定性',
      '调整了首页功能布局，提升了功能点击的便捷性',
      '新增通知中心',
      '新增每日签到功能',
      '新增积分交互玩法',
      '优化了交互体验，提升了整体流畅度',
      '修复了一些已知问题',
    ],
  },
  {
    'version': '2.0.1',
    'date': '2026-04-28',
    'isLatest': false,
    'changes': [
      '优化了app图标和启动画面',
    ],
  },
  {
    'version': '2.0.0',
    'date': '2026-04-28',
    'isLatest': false,
    'changes': [
      '全新UI设计，采用现代化极简风格',
      '新增个人主页，支持头像编辑',
      '新增版本更新日志功能',
      '记账功能大幅升级：支持分类管理、月度统计、分类占比',
      '密码本支持搜索、一键复制密码',
      '支持主题切换记忆，重启后保持上次主题',
      '整体交互体验优化',
      '修复了一些已知问题'
    ],
  },
  {
    'version': '1.0.0',
    'date': '2026-04-27',
    'isLatest': false,
    'changes': [
      '应用首次发布',
      '密码本：安全的本地密码存储',
      '记账工具：基础收支记录',
      '白天/黑夜主题切换',
    ],
  },
];

// ============================================================
// 等级系统
// ============================================================

class LevelInfo {
  final int level;
  final String name;
  final int requiredPoints;
  final IconData icon;
  final Color color;
  const LevelInfo(
      this.level, this.name, this.requiredPoints, this.icon, this.color);
}

const List<LevelInfo> levels = [
  LevelInfo(1, '小小萌新', 0, Icons.star_outline, Color(0xFF9CA3AF)),
  LevelInfo(2, '初识小友', 50, Icons.star_half, Color(0xFF3B82F6)),
  LevelInfo(3, '入门记录员', 150, Icons.auto_stories, Color(0xFF10B981)),
  LevelInfo(4, '常驻陪伴者', 300, Icons.local_fire_department,
      Color(0xFFF97316)),
  LevelInfo(5, '暖心随行官', 500, Icons.favorite, Color(0xFFEC4899)),
  LevelInfo(6, '专属贴心助手', 800, Icons.shield, Color(0xFF8B5CF6)),
  LevelInfo(
      7, '尊享温柔管家', 1200, Icons.workspace_premium, Color(0xFF6366F1)),
  LevelInfo(
      8, '全域日常守护者', 1800, Icons.military_tech, Color(0xFF14B8A6)),
  LevelInfo(
      9, '全能至尊陪伴官', 2500, Icons.emoji_events, Color(0xFFF59E0B)),
  LevelInfo(10, '绝版专属星辰', 3500, Icons.diamond, Color(0xFFEF4444)),
];

// ============================================================
// 签到积分概率（可自行调整后面的数字）
// ============================================================

const Map<int, int> checkInWeights = {
  1: 5,
  2: 10,
  3: 15,
  4: 20,
  5: 20,
  6: 12,
  7: 8,
  8: 5,
  9: 3,
  10: 2,
};
