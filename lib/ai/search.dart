// Alpha-Beta搜索算法
// 参考源文件: src/ai/Search.lua
// 功能：使用Alpha-Beta剪枝搜索最佳走法

import 'dart:math' as math;
import '../models/move.dart';
import '../models/game_state.dart';
import '../core/constants.dart';
import '../core/move_generator.dart';
import 'evaluation.dart';
import 'move_ordering.dart';

/// 置换表项
///
/// 存储已搜索过的局面信息
class TTEntry {
  /// 局面评分
  final int score;

  /// 搜索深度
  final int depth;

  /// 节点类型（精确值/上界/下界）
  final TTNodeType nodeType;

  /// 最佳走法
  final Move? bestMove;

  /// 构造函数
  const TTEntry({
    required this.score,
    required this.depth,
    required this.nodeType,
    this.bestMove,
  });
}

/// 置换表节点类型
enum TTNodeType {
  exact, // 精确值
  lowerBound, // 下界（Beta截断）
  upperBound, // 上界（Alpha截断）
}

/// Alpha-Beta搜索器
///
/// 实现Alpha-Beta剪枝算法，支持：
/// - 置换表
/// - 走法排序
/// - 静态搜索
class Search {
  /// 置换表（缓存已搜索的局面）
  final Map<String, TTEntry> transpositionTable = {};

  /// 搜索的节点数（统计）
  int nodesSearched = 0;

  /// 是否超时
  bool isTimeout = false;

  /// 超时时间戳
  int? timeoutTimestamp;

  /// 清除搜索状态
  void reset() {
    transpositionTable.clear();
    nodesSearched = 0;
    isTimeout = false;
    timeoutTimestamp = null;
  }

  /// 设置超时时间
  ///
  /// 参数:
  /// - milliseconds: 超时时间（毫秒）
  void setTimeout(int milliseconds) {
    timeoutTimestamp = DateTime.now().millisecondsSinceEpoch + milliseconds;
  }

  /// 检查是否超时
  bool _checkTimeout() {
    if (timeoutTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= timeoutTimestamp!) {
        isTimeout = true;
        return true;
      }
    }
    return false;
  }

  /// 搜索最佳走法
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  /// - depth: 搜索深度
  /// - side: 搜索方
  ///
  /// 返回: 最佳走法和评分
  ({Move? move, int score}) findBestMove(
    GameState gameState,
    int depth,
    Side side,
  ) {
    nodesSearched = 0;
    isTimeout = false;

    Move? bestMove;
    int bestScore = -999999;

    // 获取所有合法走法
    final legalMoves = MoveGenerator.getAllLegalMoves(gameState, side);

    if (legalMoves.isEmpty) {
      // 没有合法走法
      return (move: null, score: bestScore);
    }

    // 走法排序
    final orderedMoves = MoveOrdering.orderMoves(legalMoves, gameState);

    // 遍历所有走法
    for (final move in orderedMoves) {
      // 检查超时
      if (_checkTimeout()) {
        break;
      }

      // 执行走法
      final newState = gameState.applyMove(move);

      // 搜索对方的最佳应对
      final score = -_alphaBeta(
        newState,
        depth - 1,
        -999999,
        999999,
        side == Side.red ? Side.black : Side.red,
      );

      // 更新最佳走法
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return (move: bestMove, score: bestScore);
  }

  /// Alpha-Beta搜索算法
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  /// - depth: 剩余搜索深度
  /// - alpha: Alpha值
  /// - beta: Beta值
  /// - side: 当前搜索方
  ///
  /// 返回: 局面评分
  int _alphaBeta(
    GameState gameState,
    int depth,
    int alpha,
    int beta,
    Side side,
  ) {
    // 增加节点计数
    nodesSearched++;

    // 检查超时
    if (_checkTimeout()) {
      return 0;
    }

    // 计算局面键（用于置换表）
    final key = gameState.computeKey();

    // 查询置换表
    final ttEntry = transpositionTable[key];
    if (ttEntry != null && ttEntry.depth >= depth) {
      // 根据节点类型返回分数
      switch (ttEntry.nodeType) {
        case TTNodeType.exact:
          return ttEntry.score;
        case TTNodeType.lowerBound:
          if (ttEntry.score >= beta) {
            return ttEntry.score;
          }
          break;
        case TTNodeType.upperBound:
          if (ttEntry.score <= alpha) {
            return ttEntry.score;
          }
          break;
      }
    }

    // 达到搜索深度，进行静态评估
    if (depth <= 0) {
      return _quiescence(gameState, alpha, beta, side, 3);
    }

    // 检查游戏结束
    if (gameState.isGameOver()) {
      if (gameState.isCheckmate()) {
        // 被将死，返回极低分数（考虑深度，越快将死越不利）
        return -900000 + (10 - depth) * 1000;
      } else {
        // 和棋
        return 0;
      }
    }

    // 获取所有合法走法
    final legalMoves = MoveGenerator.getAllLegalMoves(gameState, side);

    if (legalMoves.isEmpty) {
      // 没有合法走法（被将死或困毙）
      if (MoveGenerator.isInCheck(gameState, side)) {
        return -900000 + (10 - depth) * 1000; // 被将死
      } else {
        return 0; // 困毙（和棋）
      }
    }

    // 走法排序
    final orderedMoves = MoveOrdering.orderMoves(
      legalMoves,
      gameState,
      pvMove: ttEntry?.bestMove,
    );

    var currentAlpha = alpha;
    Move? bestMove;
    TTNodeType nodeType = TTNodeType.upperBound;

    // 遍历所有走法
    for (final move in orderedMoves) {
      // 执行走法
      final newState = gameState.applyMove(move);

      // 递归搜索
      final score = -_alphaBeta(
        newState,
        depth - 1,
        -beta,
        -currentAlpha,
        side == Side.red ? Side.black : Side.red,
      );

      // Beta截断
      if (score >= beta) {
        // 存入置换表
        transpositionTable[key] = TTEntry(
          score: score,
          depth: depth,
          nodeType: TTNodeType.lowerBound,
          bestMove: move,
        );
        return score;
      }

      // 更新Alpha
      if (score > currentAlpha) {
        currentAlpha = score;
        bestMove = move;
        nodeType = TTNodeType.exact;
      }
    }

    // 存入置换表
    transpositionTable[key] = TTEntry(
      score: currentAlpha,
      depth: depth,
      nodeType: nodeType,
      bestMove: bestMove,
    );

    return currentAlpha;
  }

  /// 静态搜索（只搜索吃子走法）
  ///
  /// 避免水平线效应，搜索到稳定局面
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  /// - alpha: Alpha值
  /// - beta: Beta值
  /// - side: 当前搜索方
  /// - depth: 剩余搜索深度
  ///
  /// 返回: 局面评分
  int _quiescence(
    GameState gameState,
    int alpha,
    int beta,
    Side side,
    int depth,
  ) {
    nodesSearched++;

    // 静态评估
    final standPat = Evaluator.evaluate(gameState, side);

    // Beta截断
    if (standPat >= beta) {
      return standPat;
    }

    // 更新Alpha
    var currentAlpha = math.max(alpha, standPat);

    // 达到静态搜索深度限制
    if (depth <= 0) {
      return standPat;
    }

    // 只搜索吃子走法
    final allMoves = MoveGenerator.getAllLegalMoves(gameState, side);
    final captureMoves = allMoves.where((m) => m.isCapture).toList();

    if (captureMoves.isEmpty) {
      return standPat;
    }

    // 走法排序
    final orderedMoves = MoveOrdering.orderMoves(captureMoves, gameState);

    // 遍历吃子走法
    for (final move in orderedMoves) {
      final newState = gameState.applyMove(move);

      final score = -_quiescence(
        newState,
        -beta,
        -currentAlpha,
        side == Side.red ? Side.black : Side.red,
        depth - 1,
      );

      // Beta截断
      if (score >= beta) {
        return score;
      }

      // 更新Alpha
      if (score > currentAlpha) {
        currentAlpha = score;
      }
    }

    return currentAlpha;
  }
}
