// 局面评估函数
// 参考源文件: src/ai/Evaluation.lua
// 功能：评估棋盘局面，返回分数

import '../models/game_state.dart';
import '../models/piece.dart';
import '../core/constants.dart';
import '../core/skills/skill_types.dart';
import '../core/move_generator.dart';

/// 局面评估器
///
/// 根据多种因素评估当前局面的优劣：
/// - 物质价值（棋子数量和类型）
/// - 位置价值
/// - 机动性（可走步数）
/// - 将军威胁
class Evaluator {
  /// 棋子基础价值表
  static const Map<SkillType, int> pieceValues = {
    SkillType.king: 10000, // 将/帅
    SkillType.rook: 600, // 车
    SkillType.cannon: 300, // 炮
    SkillType.knight: 300, // 马
    SkillType.bishop: 200, // 相/象
    SkillType.advisor: 200, // 士
    SkillType.pawn: 100, // 兵/卒
  };

  /// 位置价值表（红方视角）
  /// 每个技能类型都有对应的位置加分表
  static const Map<SkillType, List<List<int>>> positionTables = {
    // 兵/卒位置表（过河更有价值）
    SkillType.pawn: [
      [0, 0, 0, 0, 0, 0, 0, 0, 0], // 黑方底线
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [10, 0, 10, 0, 20, 0, 10, 0, 10], // 黑方兵线
      [20, 0, 20, 0, 30, 0, 20, 0, 20], // 河界
      [30, 0, 30, 0, 40, 0, 30, 0, 30], // 河界
      [40, 0, 40, 0, 50, 0, 40, 0, 40], // 红方过河兵
      [50, 0, 50, 0, 60, 0, 50, 0, 50],
      [60, 0, 60, 0, 70, 0, 60, 0, 60],
      [70, 0, 70, 0, 80, 0, 70, 0, 70], // 红方底线附近
    ],
  };

  /// 评估局面
  ///
  /// 参数:
  /// - gameState: 游戏状态
  /// - side: 评估方（从该方视角评估）
  ///
  /// 返回: 分数（正数表示该方优势，负数表示劣势）
  static int evaluate(GameState gameState, Side side) {
    int score = 0;

    // 1. 物质价值评估
    score += _evaluateMaterial(gameState, side);

    // 2. 位置价值评估
    score += _evaluatePosition(gameState, side);

    // 3. 机动性评估（可走步数）
    score += _evaluateMobility(gameState, side);

    // 4. 将军威胁评估
    score += _evaluateKingSafety(gameState, side);

    return score;
  }

  /// 评估物质价值
  ///
  /// 计算双方棋子的价值差
  static int _evaluateMaterial(GameState gameState, Side side) {
    int score = 0;
    final board = gameState.board;

    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null) {
          // 计算棋子价值（所有技能的价值总和）
          int pieceValue = 0;

          for (final skill in piece.skillsList) {
            pieceValue += pieceValues[skill.typeId] ?? 0;
          }

          // 己方棋子加分，对方棋子减分
          if (piece.side == side) {
            score += pieceValue;
          } else {
            score -= pieceValue;
          }
        }
      }
    }

    return score;
  }

  /// 评估位置价值
  ///
  /// 根据棋子在棋盘上的位置给予加分
  static int _evaluatePosition(GameState gameState, Side side) {
    int score = 0;
    final board = gameState.board;

    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null) {
          // 简化：只评估兵的位置价值
          for (final skill in piece.skillsList) {
            if (skill.typeId == SkillType.pawn) {
              // 根据阵营调整y坐标（黑方需要翻转）
              final adjustedY = piece.side == Side.red ? y : (BoardConstants.boardHeight - 1 - y);

              final posValue = positionTables[SkillType.pawn]?[adjustedY][x] ?? 0;

              // 己方棋子加分，对方棋子减分
              if (piece.side == side) {
                score += posValue;
              } else {
                score -= posValue;
              }
            }
          }
        }
      }
    }

    return score;
  }

  /// 评估机动性
  ///
  /// 计算可走步数（更多选择 = 更有利）
  static int _evaluateMobility(GameState gameState, Side side) {
    // 计算己方合法走法数量
    final ourMoves = MoveGenerator.getAllLegalMoves(gameState, side);

    // 计算对方合法走法数量
    final opponentSide = side == Side.red ? Side.black : Side.red;
    final opponentMoves = MoveGenerator.getAllLegalMoves(gameState, opponentSide);

    // 机动性差值（权重较小）
    return (ourMoves.length - opponentMoves.length) * 10;
  }

  /// 评估将军安全
  ///
  /// 检查将军是否处于危险状态
  static int _evaluateKingSafety(GameState gameState, Side side) {
    int score = 0;

    // 如果己方被将军，大幅减分
    if (MoveGenerator.isInCheck(gameState, side)) {
      score -= 500;
    }

    // 如果对方被将军，大幅加分
    final opponentSide = side == Side.red ? Side.black : Side.red;
    if (MoveGenerator.isInCheck(gameState, opponentSide)) {
      score += 500;
    }

    return score;
  }

  /// 快速评估（简化版，用于走法排序）
  ///
  /// 只计算物质价值，不计算其他因素
  static int quickEvaluate(GameState gameState, Side side) {
    return _evaluateMaterial(gameState, side);
  }
}
