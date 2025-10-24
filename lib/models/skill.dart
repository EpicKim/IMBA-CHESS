// 技能数据模型
// 参考源文件: src/skills/BaseSkill.lua

import 'package:equatable/equatable.dart';
import '../skills/skill_types.dart';
import '../core/constants.dart';
import 'move.dart';

/// 走法生成器函数类型
/// 输入：游戏状态、棋子位置(x, y)、棋子所属阵营、棋子对象
/// 输出：该技能产生的所有走法列表
typedef MoveGeneratorFunction = List<Move> Function(
  dynamic state,
  int x,
  int y,
  dynamic side,
  dynamic piece,
);

/// 技能类
/// 表示一个具体的技能实例（如"车技能"、"马技能"等）
class Skill extends Equatable {
  final SkillType typeId; // 技能类型
  final String name; // 技能名称（显示用）
  final MoveGeneratorFunction? moveGen; // 走法生成器函数
  final Map<String, dynamic> attrs; // 技能属性（如兵/卒的 sideways）

  const Skill({
    required this.typeId,
    required this.name,
    this.moveGen,
    this.attrs = const {},
  });

  @override
  List<Object?> get props => [typeId, name, attrs];

  @override
  String toString() => 'Skill{$name}';

  /// 根据阵营获取技能显示名称
  ///
  /// 某些棋子在红方和黑方有不同的名称：
  /// - 帅(红) / 将(黑)
  /// - 相(红) / 象(黑)
  /// - 兵(红) / 卒(黑)
  String getDisplayName(Side side) {
    return typeId.getDisplayName(side);
  }

  /// 获取该技能在指定位置的所有走法
  ///
  /// 参数：
  /// - state: 当前游戏状态
  /// - x, y: 棋子位置
  /// - side: 棋子所属阵营
  /// - piece: 棋子对象
  ///
  /// 返回：走法列表
  List<Move> getMoves(dynamic state, int x, int y, dynamic side, dynamic piece) {
    if (moveGen == null) {
      return []; // 无走法生成器，返回空列表
    }

    // 调用走法生成器
    return moveGen!(state, x, y, side, piece);
  }

  /// 复制并修改部分字段
  Skill copyWith({
    SkillType? typeId,
    String? name,
    MoveGeneratorFunction? moveGen,
    Map<String, dynamic>? attrs,
  }) {
    return Skill(
      typeId: typeId ?? this.typeId,
      name: name ?? this.name,
      moveGen: moveGen ?? this.moveGen,
      attrs: attrs ?? this.attrs,
    );
  }

  /// 创建带属性的技能副本
  Skill withAttrs(Map<String, dynamic> newAttrs) {
    final mergedAttrs = Map<String, dynamic>.from(attrs);
    mergedAttrs.addAll(newAttrs);
    return copyWith(attrs: mergedAttrs);
  }
}
