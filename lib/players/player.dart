// 玩家抽象类
// 参考源文件: src/players/Player.lua
// 功能：定义玩家接口

import '../models/move.dart';
import '../game_provider/game_state.dart';
import '../skills/skill.dart';
import '../core/constants.dart';

/// 玩家抽象类
///
/// 定义所有玩家类型的通用接口
abstract class Player {
  /// 玩家ID
  final String id;

  /// 玩家名称
  final String name;

  /// 玩家阵营
  final Side side;

  /// 构造函数
  Player({
    required this.id,
    required this.name,
    required this.side,
  });

  /// 选择走法
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  ///
  /// 返回: 选择的走法（异步）
  Future<Move?> play(GameState gameState);

  /// 选择技能
  ///
  /// 参数:
  /// - availableSkills: 可用技能列表
  /// - gameState: 当前游戏状态
  ///
  /// 返回: 选择的技能（异步）
  Future<Skill?> chooseSkill(
    List<Skill> availableSkills,
    GameState gameState,
  );

  /// 是否是本地玩家
  bool get isMe;

  /// 是否是AI玩家
  bool get isAI;

  /// 是否是网络玩家
  bool get isOnline;

  /// 通知玩家其选择的走法已被执行（可选实现）
  ///
  /// 用于本地玩家完成其 Future，AI/在线玩家可以忽略
  void notifyMoveExecuted(Move move) {
    // 默认实现：什么都不做（AI/在线玩家不需要）
  }

  /// 通知玩家其选择的技能已被应用（可选实现）
  ///
  /// 用于本地玩家完成其 Future，AI/在线玩家可以忽略
  void notifySkillApplied(Skill skill) {
    // 默认实现：什么都不做（AI/在线玩家不需要）
  }
}
