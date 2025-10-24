// 棋子数据模型
// 参考源文件: src/game/Piece.lua

import 'package:equatable/equatable.dart';
import '../core/constants.dart';
import '../skills/skill_types.dart';
import 'skill.dart';

/// 棋子类
/// 核心概念：棋子是"白板"，通过技能系统获得走法能力
/// 每个棋子可以拥有多个技能，第一个技能决定显示名称（主技能）
class Piece extends Equatable {
  final int id; // 棋子唯一ID
  final Side side; // 所属阵营（红方/黑方）
  final String? label; // 棋面文字（首个技能赋值）
  final List<Skill> skillsList; // 技能实例数组（唯一来源）

  const Piece({
    required this.id,
    required this.side,
    this.label,
    this.skillsList = const [],
  });

  /// 使用技能类型列表创建棋子
  ///
  /// 参数:
  /// - id: 棋子ID
  /// - side: 所属阵营
  /// - label: 显示文字
  /// - skillTypes: 技能类型列表
  factory Piece.withSkills(int id, Side side, String label, List<SkillType> skillTypes) {
    // 将技能类型转换为技能实例
    final skills = skillTypes.map((type) => skillDefinitions[type]!).toList();

    return Piece(
      id: id,
      side: side,
      label: label,
      skillsList: skills,
    );
  }

  @override
  List<Object?> get props => [id, side, label, skillsList];

  @override
  String toString() {
    final sideText = side == Side.red ? '红' : '黑';
    final skillNames = skillsList.map((s) => s.name).join('+');
    return 'Piece{$sideText-$label[$skillNames]}';
  }

  /// 检查棋子是否拥有某个技能类型
  bool hasSkill(SkillType skillType) {
    return skillsList.any((skill) => skill.typeId == skillType);
  }

  /// 获取指定类型的技能实例
  /// 返回第一个匹配的技能，如果不存在则返回 null
  Skill? getSkill(SkillType skillType) {
    try {
      return skillsList.firstWhere((skill) => skill.typeId == skillType);
    } catch (e) {
      return null; // 未找到
    }
  }

  /// 添加技能到技能列表
  /// 返回新的棋子实例（不可变模式）
  Piece addSkill(Skill skill) {
    // 检查是否已有该技能
    if (hasSkill(skill.typeId)) {
      return this; // 已有则不重复添加
    }

    // 创建新的技能列表
    final newSkillsList = List<Skill>.from(skillsList);

    // 王技能插入首位
    if (skill.typeId == SkillType.king) {
      newSkillsList.insert(0, skill);
    } else {
      newSkillsList.add(skill);
    }

    // 更新标签（如果当前无标签，使用新技能名称）
    final newLabel = label ?? skill.name;

    return copyWith(
      skillsList: newSkillsList,
      label: newLabel,
    );
  }

  /// 复制并修改部分字段
  Piece copyWith({
    int? id,
    Side? side,
    String? label,
    List<Skill>? skillsList,
  }) {
    return Piece(
      id: id ?? this.id,
      side: side ?? this.side,
      label: label ?? this.label,
      skillsList: skillsList ?? this.skillsList,
    );
  }

  /// 创建空白棋子（无技能）
  factory Piece.blank({
    required int id,
    required Side side,
  }) {
    return Piece(
      id: id,
      side: side,
      label: null,
      skillsList: const [],
    );
  }
}

/// 棋子ID生成器
/// 用于为新棋子分配唯一ID
class PieceIdGenerator {
  static int _nextId = 1;

  /// 获取下一个唯一ID
  static int nextId() {
    return _nextId++;
  }

  /// 重置ID计数器（用于新局开始）
  static void reset() {
    _nextId = 1;
  }
}
