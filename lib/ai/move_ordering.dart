// 走法排序
// 参考源文件: src/ai/MoveOrdering.lua
// 功能：对走法进行排序，优先搜索有希望的走法

import '../models/move.dart';
import '../game_provider/game_state.dart';
import '../skills/skill_types.dart';
import 'evaluation.dart';

/// 走法排序器
///
/// 对走法进行启发式排序，提高Alpha-Beta剪枝效率
class MoveOrdering {
  /// MVV-LVA（最有价值受害者 - 最低价值攻击者）价值表
  /// （非king技能）
  static const Map<SkillType, int> captureValues = {
    SkillType.rook: 600,
    SkillType.cannon: 300,
    SkillType.knight: 300,
    SkillType.bishop: 200,
    SkillType.advisor: 200,
    SkillType.pawn: 100,
  };

  /// 对走法列表进行排序
  ///
  /// 排序优先级：
  /// 1. PV走法（主要变化走法）
  /// 2. 吃子走法（MVV-LVA排序）
  /// 3. 其他走法
  ///
  /// 参数:
  /// - moves: 待排序的走法列表
  /// - gameState: 当前游戏状态
  /// - pvMove: PV走法（可选）
  ///
  /// 返回: 排序后的走法列表
  static List<Move> orderMoves(
    List<Move> moves,
    GameState gameState, {
    Move? pvMove,
  }) {
    // 为每个走法计算排序分数
    final scoredMoves = <({Move move, int score})>[];

    for (final move in moves) {
      int score = 0;

      // 1. PV走法优先级最高
      if (pvMove != null && _isSameMove(move, pvMove)) {
        score += 1000000;
      }

      // 2. 吃子走法（MVV-LVA）
      if (move.isCapture && move.capturedPieceId != null) {
        score += _evaluateCapture(gameState, move);
      }

      // 3. 移除昂贵的将军检查以提升性能
      // 将军走法会在搜索过程中自然被发现

      scoredMoves.add((move: move, score: score));
    }

    // 按分数降序排序
    scoredMoves.sort((a, b) => b.score.compareTo(a.score));

    return scoredMoves.map((sm) => sm.move).toList();
  }

  /// 评估吃子走法的价值（MVV-LVA）
  ///
  /// 优先吃价值高的棋子，使用价值低的棋子去吃
  /// 使用动态king价值评估
  static int _evaluateCapture(GameState gameState, Move move) {
    // 获取被吃棋子
    final capturedPiece = gameState.board.get(move.to.x, move.to.y);

    if (capturedPiece == null) {
      return 0;
    }

    // 获取攻击棋子
    final attackingPiece = gameState.board.get(move.from.x, move.from.y);

    if (attackingPiece == null) {
      return 0;
    }

    // 计算被吃棋子的价值（受害者价值）
    int victimValue = 0;
    for (final skill in capturedPiece.skillsList) {
      if (skill.typeId == SkillType.king) {
        // 使用动态king价值
        victimValue += Evaluator.getKingValue(gameState, capturedPiece.side);
      } else {
        victimValue += captureValues[skill.typeId] ?? 0;
      }
    }

    // 计算攻击棋子的价值（攻击者价值）
    int attackerValue = 0;
    for (final skill in attackingPiece.skillsList) {
      if (skill.typeId == SkillType.king) {
        // 使用动态king价值
        attackerValue += Evaluator.getKingValue(gameState, attackingPiece.side);
      } else {
        attackerValue += captureValues[skill.typeId] ?? 0;
      }
    }

    // MVV-LVA: 高价值受害者 - 低价值攻击者
    // 公式：受害者价值 * 10 - 攻击者价值
    return victimValue * 10 - attackerValue + 10000;
  }

  /// 判断两个走法是否相同
  static bool _isSameMove(Move m1, Move m2) {
    return m1.from.x == m2.from.x && m1.from.y == m2.from.y && m1.to.x == m2.to.x && m1.to.y == m2.to.y;
  }
}
