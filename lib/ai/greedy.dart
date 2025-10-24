// 贪心算法（简单AI）
// 参考源文件: src/ai/Greedy.lua
// 功能：1步前瞻的贪心搜索，作为AI后备方案

import '../models/move.dart';
import '../models/game_state.dart';
import '../core/constants.dart';
import '../core/move_generator.dart';
import 'evaluation.dart';

/// 贪心算法AI
///
/// 简单的1步前瞻AI，用作：
/// 1. Alpha-Beta搜索超时后的后备方案
/// 2. 快速测试和调试
class GreedyAI {
  /// 选择最佳走法（贪心策略）
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  /// - side: AI阵营
  ///
  /// 返回: 最佳走法（如果没有合法走法则返回null）
  static Move? chooseMove(GameState gameState, Side side) {
    // 获取所有合法走法
    final legalMoves = MoveGenerator.getAllLegalMoves(gameState, side);

    if (legalMoves.isEmpty) {
      return null;
    }

    Move? bestMove;
    int bestScore = -999999;

    // 遍历所有走法，选择评分最高的
    for (final move in legalMoves) {
      // 执行走法
      final newState = gameState.applyMove(move);

      // 评估新局面
      final score = Evaluator.evaluate(newState, side);

      // 更新最佳走法
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// 快速评估走法（不实际执行）
  ///
  /// 用于快速排序和选择
  ///
  /// 参数:
  /// - move: 走法
  /// - gameState: 当前游戏状态
  ///
  /// 返回: 走法的估计价值
  static int evaluateMove(Move move, GameState gameState) {
    int score = 0;

    // 1. 吃子加分
    if (move.isCapture && move.capturedPieceId != null) {
      final capturedPiece = gameState.board.get(move.to.x, move.to.y);

      if (capturedPiece != null) {
        // 根据被吃棋子的技能数量加分
        score += capturedPiece.skillsList.length * 100;
      }
    }

    // 2. 将军加分
    final newState = gameState.applyMove(move);
    if (newState.isInCheck()) {
      score += 500;
    }

    // 3. 中心位置加分（简单启发）
    final centerX = 4; // 棋盘中心x坐标
    final distanceToCenter = (move.to.x - centerX).abs();
    score += (8 - distanceToCenter) * 10;

    return score;
  }
}
