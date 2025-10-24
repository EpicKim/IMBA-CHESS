// 走法生成系统
// 参考源文件: src/game/MoveGen.lua
// 功能：生成伪合法走法和合法走法

import '../models/move.dart';
import '../models/board.dart';
import 'constants.dart';
import 'skills/skill_types.dart';

/// 走法生成器类
///
/// 负责生成所有走法，包括：
/// 1. 伪合法走法（不检查是否将军）
/// 2. 合法走法（过滤掉会导致被将军的走法）
class MoveGenerator {
  /// 获取指定位置棋子的伪合法走法
  ///
  /// 参数:
  /// - state: 游戏状态对象
  /// - x, y: 棋子位置
  ///
  /// 返回: 走法列表（未检查是否会导致将军）
  static List<Move> getPseudoLegalMoves(dynamic state, int x, int y) {
    final board = state.board as Board;
    final piece = board.get(x, y);

    // 如果位置没有棋子，返回空列表
    if (piece == null) {
      return [];
    }

    // 收集所有技能的走法
    final allMoves = <Move>[];

    // 遍历棋子的所有技能
    for (final skill in piece.skillsList) {
      // 调用技能的走法生成函数
      final moves = skill.getMoves(state, x, y, piece.side, piece);
      allMoves.addAll(moves);
    }

    return allMoves;
  }

  /// 获取指定位置棋子的合法走法
  ///
  /// 参数:
  /// - state: 游戏状态对象
  /// - x, y: 棋子位置
  ///
  /// 返回: 走法列表（已过滤掉会导致将军的走法）
  static List<Move> getLegalMoves(dynamic state, int x, int y) {
    // 先获取所有伪合法走法
    final pseudoLegalMoves = getPseudoLegalMoves(state, x, y);

    // 过滤掉会导致自己被将军的走法
    final legalMoves = <Move>[];

    for (final move in pseudoLegalMoves) {
      // 尝试执行该走法
      final newState = _makeMove(state, move);

      // 检查执行后是否会导致自己被将军
      final board = state.board as Board;
      final piece = board.get(x, y);

      if (piece != null && !isInCheck(newState, piece.side)) {
        // 不会导致将军，是合法走法
        legalMoves.add(move);
      }
    }

    return legalMoves;
  }

  /// 获取指定阵营的所有合法走法
  ///
  /// 参数:
  /// - state: 游戏状态对象
  /// - side: 阵营
  ///
  /// 返回: 走法列表
  static List<Move> getAllLegalMoves(dynamic state, Side side) {
    final board = state.board as Board;
    final allMoves = <Move>[];

    // 遍历棋盘上的所有位置
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        // 如果该位置有己方棋子
        if (piece != null && piece.side == side) {
          // 获取该棋子的所有合法走法
          final moves = getLegalMoves(state, x, y);
          allMoves.addAll(moves);
        }
      }
    }

    return allMoves;
  }

  /// 检查指定阵营是否处于被将军状态
  ///
  /// 参数:
  /// - state: 游戏状态对象
  /// - side: 要检查的阵营
  ///
  /// 返回: true=被将军，false=未被将军
  static bool isInCheck(dynamic state, Side side) {
    final board = state.board as Board;

    // 找到己方将/帅的位置
    final kingPos = board.findKing(side);

    if (kingPos == null) {
      // 如果找不到将/帅（异常情况），认为不在被将军状态
      return false;
    }

    // 检查是否有敌方棋子可以攻击到将/帅
    return isSquareAttacked(state, kingPos.x, kingPos.y, side);
  }

  /// 检查指定位置是否受到指定阵营的攻击
  ///
  /// 参数:
  /// - state: 游戏状态对象
  /// - x, y: 要检查的位置
  /// - defendingSide: 防守方阵营（即被攻击的一方）
  ///
  /// 返回: true=受到攻击，false=未受到攻击
  static bool isSquareAttacked(dynamic state, int x, int y, Side defendingSide) {
    final board = state.board as Board;
    final attackingSide = defendingSide == Side.red ? Side.black : Side.red;

    // 遍历棋盘，检查是否有敌方棋子可以攻击到该位置
    for (var py = 0; py < BoardConstants.boardHeight; py++) {
      for (var px = 0; px < BoardConstants.boardWidth; px++) {
        final piece = board.get(px, py);

        // 如果是敌方棋子
        if (piece != null && piece.side == attackingSide) {
          // 获取该棋子的所有伪合法走法
          final moves = getPseudoLegalMoves(state, px, py);

          // 检查是否有走法可以到达目标位置
          for (final move in moves) {
            if (move.to.x == x && move.to.y == y) {
              return true; // 该位置受到攻击
            }
          }
        }
      }
    }

    // 特殊规则：检查"将帅对脸"规则
    // 如果目标位置是将/帅，需要检查对方将/帅是否与之在同一列且中间无子
    final targetPiece = board.get(x, y);
    if (targetPiece != null && targetPiece.hasSkill(SkillType.king)) {
      // 找到对方将/帅
      final opponentKingPos = board.findKing(attackingSide);

      if (opponentKingPos != null && opponentKingPos.x == x) {
        // 同一列，检查中间是否有子
        final minY = opponentKingPos.y < y ? opponentKingPos.y : y;
        final maxY = opponentKingPos.y > y ? opponentKingPos.y : y;

        var hasBlocker = false;
        for (var cy = minY + 1; cy < maxY; cy++) {
          if (board.get(x, cy) != null) {
            hasBlocker = true;
            break;
          }
        }

        // 如果中间无子，则构成对脸，视为受到攻击
        if (!hasBlocker) {
          return true;
        }
      }
    }

    return false;
  }

  /// 内部辅助函数：执行走法并返回新状态
  ///
  /// 注意：这是一个简化版本，仅用于走法合法性检查
  /// 实际游戏中应使用完整的状态管理系统
  ///
  /// 参数:
  /// - state: 当前游戏状态
  /// - move: 要执行的走法
  ///
  /// 返回: 执行走法后的新状态
  static dynamic _makeMove(dynamic state, Move move) {
    // 创建状态的深拷贝
    final board = state.board as Board;
    final newBoard = board.copyWith();

    // 获取起始位置的棋子
    final piece = newBoard.get(move.from.x, move.from.y);

    if (piece != null) {
      // 清空起始位置
      newBoard.set(move.from.x, move.from.y, null);

      // 将棋子移动到目标位置
      newBoard.set(move.to.x, move.to.y, piece);
    }

    // 返回新状态（简化版，只包含棋盘）
    return _SimpleState(newBoard);
  }
}

/// 内部简化的状态类（仅用于走法合法性检查）
class _SimpleState {
  final Board board;

  _SimpleState(this.board);
}
