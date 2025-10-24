// 技能面板
// 参考源文件: src/areas/SkillArea.lua
// 功能：显示可用技能卡，支持技能选择

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../skills/skill.dart';
import '../../skills/skill_types.dart';
import '../../core/constants.dart';

/// 技能面板组件
///
/// 显示可选技能列表，支持技能选择
class SkillPanel extends StatelessWidget {
  /// 可用技能列表
  final List<Skill> availableSkills;

  /// 选中的技能
  final Skill? selectedSkill;

  /// 技能选择回调
  final void Function(Skill skill)? onSkillSelected;

  /// 是否处于技能选择模式
  final bool isSelecting;

  /// 提示信息
  final String message;

  /// 当前选择技能的玩家阵营
  final Side currentSide;

  /// 构造函数
  const SkillPanel({
    super.key,
    this.availableSkills = const [],
    this.selectedSkill,
    this.onSkillSelected,
    this.isSelecting = false,
    this.message = '',
    required this.currentSide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 32.sp),
                SizedBox(width: 8.w),
                Text(
                  '技能系统',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            SizedBox(height: 8.h),

            // 提示信息
            if (message.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isSelecting ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelecting ? Colors.blue : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelecting ? Icons.info : Icons.check_circle,
                      color: isSelecting ? Colors.blue : Colors.green,
                      size: 28.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: isSelecting ? Colors.blue : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // 技能列表
            if (availableSkills.isEmpty) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Text(
                    '暂无可用技能',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 480.h,
                child: ListView.builder(
                  itemCount: availableSkills.length,
                  itemBuilder: (context, index) {
                    final skill = availableSkills[index];
                    final isSelected = selectedSkill == skill;

                    return _SkillCard(
                      skill: skill,
                      isSelected: isSelected,
                      currentSide: currentSide,
                      onTap: isSelecting && onSkillSelected != null ? () => onSkillSelected!(skill) : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 技能卡片组件
class _SkillCard extends StatelessWidget {
  /// 技能对象
  final Skill skill;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback? onTap;

  /// 当前玩家阵营
  final Side currentSide;

  /// 构造函数
  const _SkillCard({
    required this.skill,
    this.isSelected = false,
    this.onTap,
    required this.currentSide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // 技能图标
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: _getSkillColor(skill.typeId).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _getSkillColor(skill.typeId),
                    width: 3.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getSkillIcon(skill.typeId),
                    style: TextStyle(
                      fontSize: 32.sp,
                      color: _getSkillColor(skill.typeId),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // 技能信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.getDisplayName(currentSide),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getSkillDescription(skill.typeId),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 选中指示器
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取技能颜色
  Color _getSkillColor(SkillType type) {
    switch (type) {
      case SkillType.king:
        return Colors.purple;
      case SkillType.rook:
        return Colors.red;
      case SkillType.cannon:
        return Colors.orange;
      case SkillType.knight:
        return Colors.green;
      case SkillType.bishop:
        return Colors.blue;
      case SkillType.advisor:
        return Colors.teal;
      case SkillType.pawn:
        return Colors.brown;
    }
  }

  /// 获取技能图标（文字）
  String _getSkillIcon(SkillType type) {
    // 使用当前玩家阵营显示图标
    return type.getDisplayName(currentSide);
  }

  /// 获取技能描述
  String _getSkillDescription(SkillType type) {
    switch (type) {
      case SkillType.king:
        return 'Imba象棋：全棋盘直线移动一格';
      case SkillType.rook:
        return '直线移动任意格';
      case SkillType.cannon:
        return '直线移动，隔子吃子';
      case SkillType.knight:
        return '日字走法';
      case SkillType.bishop:
        return 'Imba象棋：全棋盘田字走法';
      case SkillType.advisor:
        return 'Imba象棋：全棋盘斜线移动一格';
      case SkillType.pawn:
        return '前进一格，过河后可横移';
    }
  }
}
