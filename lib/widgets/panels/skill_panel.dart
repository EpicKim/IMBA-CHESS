// 技能面板
// 参考源文件: src/areas/SkillArea.lua
// 功能：显示可用技能卡，支持技能选择

import 'package:flutter/material.dart';
import '../../models/skill.dart';
import '../../core/skills/skill_types.dart';

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

  /// 构造函数
  const SkillPanel({
    super.key,
    this.availableSkills = const [],
    this.selectedSkill,
    this.onSkillSelected,
    this.isSelecting = false,
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '技能系统',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 提示信息
            if (message.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelecting ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelecting ? Colors.blue : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelecting ? Icons.info : Icons.check_circle,
                      color: isSelecting ? Colors.blue : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelecting ? Colors.blue : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 技能列表
            if (availableSkills.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '暂无可用技能',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: availableSkills.length,
                  itemBuilder: (context, index) {
                    final skill = availableSkills[index];
                    final isSelected = selectedSkill == skill;

                    return _SkillCard(
                      skill: skill,
                      isSelected: isSelected,
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

  /// 构造函数
  const _SkillCard({
    required this.skill,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 技能图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSkillColor(skill.typeId).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getSkillColor(skill.typeId),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getSkillIcon(skill.typeId),
                    style: TextStyle(
                      fontSize: 24,
                      color: _getSkillColor(skill.typeId),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 技能信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSkillDescription(skill.typeId),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 选中指示器
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
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
    switch (type) {
      case SkillType.king:
        return '将';
      case SkillType.rook:
        return '車';
      case SkillType.cannon:
        return '炮';
      case SkillType.knight:
        return '馬';
      case SkillType.bishop:
        return '象';
      case SkillType.advisor:
        return '士';
      case SkillType.pawn:
        return '兵';
    }
  }

  /// 获取技能描述
  String _getSkillDescription(SkillType type) {
    switch (type) {
      case SkillType.king:
        return '在九宫内直线移动一格';
      case SkillType.rook:
        return '直线移动任意格';
      case SkillType.cannon:
        return '直线移动，隔子吃子';
      case SkillType.knight:
        return '日字走法';
      case SkillType.bishop:
        return '田字走法，不可过河';
      case SkillType.advisor:
        return '九宫内斜线移动一格';
      case SkillType.pawn:
        return '前进一格，过河后可横移';
    }
  }
}
