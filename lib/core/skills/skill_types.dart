// 技能类型枚举定义
// 参考源文件: src/skills/init.lua

import '../../models/skill.dart';
import '../constants.dart';
import 'generators/king_skill.dart';
import 'generators/rook_skill.dart';
import 'generators/cannon_skill.dart';
import 'generators/knight_skill.dart';
import 'generators/bishop_skill.dart';
import 'generators/advisor_skill.dart';
import 'generators/pawn_skill.dart';

/// 技能类型枚举
/// 定义所有可用的象棋技能类型
enum SkillType {
  king, // 将/帅技能（1）
  rook, // 车技能（2）
  knight, // 马技能（3）
  cannon, // 炮技能（4）
  bishop, // 象技能（5）
  advisor, // 士技能（6）
  pawn, // 兵/卒技能（7）
}

/// 技能类型扩展方法
extension SkillTypeExtension on SkillType {
  /// 获取技能类型ID（用于兼容原Lua代码的数字ID）
  int get typeId {
    switch (this) {
      case SkillType.king:
        return 1;
      case SkillType.rook:
        return 2;
      case SkillType.knight:
        return 3;
      case SkillType.cannon:
        return 4;
      case SkillType.bishop:
        return 5;
      case SkillType.advisor:
        return 6;
      case SkillType.pawn:
        return 7;
    }
  }

  /// 从类型ID获取技能类型
  static SkillType fromTypeId(int id) {
    switch (id) {
      case 1:
        return SkillType.king;
      case 2:
        return SkillType.rook;
      case 3:
        return SkillType.knight;
      case 4:
        return SkillType.cannon;
      case 5:
        return SkillType.bishop;
      case 6:
        return SkillType.advisor;
      case 7:
        return SkillType.pawn;
      default:
        throw ArgumentError('Invalid skill type ID: $id');
    }
  }
}

/// 技能定义映射表
///
/// 将技能类型映射到具体的技能实例
final Map<SkillType, Skill> skillDefinitions = {
  SkillType.king: Skill(
    typeId: SkillType.king,
    name: '将/帅',
    moveGen: (state, x, y, side, piece) => generateKingMoves(state, x, y, side as Side, piece),
  ),
  SkillType.rook: Skill(
    typeId: SkillType.rook,
    name: '车',
    moveGen: (state, x, y, side, piece) => generateRookMoves(state, x, y, side as Side, piece),
  ),
  SkillType.cannon: Skill(
    typeId: SkillType.cannon,
    name: '炮',
    moveGen: (state, x, y, side, piece) => generateCannonMoves(state, x, y, side as Side, piece),
  ),
  SkillType.knight: Skill(
    typeId: SkillType.knight,
    name: '马',
    moveGen: (state, x, y, side, piece) => generateKnightMoves(state, x, y, side as Side, piece),
  ),
  SkillType.bishop: Skill(
    typeId: SkillType.bishop,
    name: '相/象',
    moveGen: (state, x, y, side, piece) => generateBishopMoves(state, x, y, side as Side, piece),
  ),
  SkillType.advisor: Skill(
    typeId: SkillType.advisor,
    name: '士',
    moveGen: (state, x, y, side, piece) => generateAdvisorMoves(state, x, y, side as Side, piece),
  ),
  SkillType.pawn: Skill(
    typeId: SkillType.pawn,
    name: '兵/卒',
    moveGen: (state, x, y, side, piece) => generatePawnMoves(state, x, y, side as Side, piece),
  ),
};
