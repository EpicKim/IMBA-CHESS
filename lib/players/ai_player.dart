// AI玩家
// 参考源文件: src/players/AIPlayer.lua
// 功能：表示AI玩家

import 'player.dart';
import '../models/move.dart';
import '../models/game_state.dart';
import '../models/skill.dart';
import '../core/constants.dart';
import '../ai/ai_controller.dart';

/// AI玩家类
///
/// 代表AI玩家，走法由AI控制器自动选择
class AIPlayer extends Player {
  /// AI控制器
  final AIController aiController;

  /// 构造函数
  ///
  /// 参数:
  /// - id: 玩家ID
  /// - name: 玩家名称
  /// - side: 玩家阵营
  /// - difficultyLevel: AI难度等级（1-5）
  /// - thinkingTime: AI思考时间（毫秒）
  AIPlayer({
    required super.id,
    required super.name,
    required super.side,
    int difficultyLevel = 3,
    int thinkingTime = 3000,
  }) : aiController = AIController(
          difficultyLevel: difficultyLevel,
          thinkingTime: thinkingTime,
        );

  @override
  Future<Move?> play(GameState gameState) async {
    // 调用AI控制器选择走法
    return await aiController.chooseMove(gameState, side);
  }

  @override
  Future<Skill?> chooseSkill(
    List<Skill> availableSkills,
    GameState gameState,
  ) async {
    // 调用AI控制器选择技能
    return await aiController.chooseSkill(
      availableSkills,
      gameState,
      side,
    );
  }

  @override
  bool get isMe => false;

  @override
  bool get isAI => true;

  @override
  bool get isOnline => false;
}
