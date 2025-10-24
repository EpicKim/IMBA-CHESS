// 游戏状态类
// 参考源文件: src/game/Game.lua
// 功能：管理整个游戏状态，包括棋盘、当前回合、历史记录等

import 'package:equatable/equatable.dart';
import 'board.dart';
import 'move.dart';
import '../core/constants.dart';
import '../core/move_generator.dart';
import '../skills/skill_types.dart';

/// 游戏状态类
///
/// 包含完整的游戏状态信息：
/// - 棋盘
/// - 当前轮次
/// - 移动历史
/// - 玩家信息
/// - 游戏结果
class GameState extends Equatable {
  /// 棋盘对象
  final Board board;

  /// 当前该哪方行动
  final Side sideToMove;

  /// 完整回合数（每个回合包含红方和黑方各一步）
  final int fullmoveCount;

  /// 移动历史记录
  final List<Move> history;

  /// 半回合计数器（用于判断和棋：50回合无吃子规则）
  final int halfmoveClock;

  /// 构造函数
  const GameState({
    required this.board,
    required this.sideToMove,
    this.fullmoveCount = 1,
    this.history = const [],
    this.halfmoveClock = 0,
  });

  /// 创建初始游戏状态
  factory GameState.initial() {
    return GameState(
      board: Board.initial(),
      sideToMove: Side.red, // 红方先行
      fullmoveCount: 1,
      history: [],
      halfmoveClock: 0,
    );
  }

  /// 应用一步走法，返回新的游戏状态
  ///
  /// 参数:
  /// - move: 要执行的走法
  ///
  /// 返回: 新的游戏状态
  GameState applyMove(Move move) {
    // 创建新棋盘
    final newBoard = board.copyWith();

    // 获取起始位置的棋子
    final piece = newBoard.get(move.from.x, move.from.y);

    if (piece == null) {
      // 异常情况：起始位置没有棋子
      return this;
    }

    // 清空起始位置
    newBoard.set(move.from.x, move.from.y, null);

    // 将棋子移动到目标位置
    newBoard.set(move.to.x, move.to.y, piece);

    // 更新半回合计数器
    final newHalfmoveClock = move.isCapture ? 0 : halfmoveClock + 1;

    // 更新完整回合数（黑方走完后回合数+1）
    final newFullmoveCount = sideToMove == Side.black ? fullmoveCount + 1 : fullmoveCount;

    // 切换行动方
    final newSideToMove = sideToMove == Side.red ? Side.black : Side.red;

    // 添加到历史记录
    final newHistory = List<Move>.from(history)..add(move);

    return GameState(
      board: newBoard,
      sideToMove: newSideToMove,
      fullmoveCount: newFullmoveCount,
      history: newHistory,
      halfmoveClock: newHalfmoveClock,
    );
  }

  /// 撤销上一步走法，返回新的游戏状态
  ///
  /// 返回: 新的游戏状态，如果没有历史记录则返回当前状态
  GameState undoMove() {
    if (history.isEmpty) {
      return this;
    }

    // 获取上一步走法
    final lastMove = history.last;

    // 创建新棋盘
    final newBoard = board.copyWith();

    // 获取目标位置的棋子（即刚移动过的棋子）
    final piece = newBoard.get(lastMove.to.x, lastMove.to.y);

    if (piece != null) {
      // 将棋子移回起始位置
      newBoard.set(lastMove.from.x, lastMove.from.y, piece);

      // 如果有吃子，需要恢复被吃的棋子
      if (lastMove.capturedPieceId != null) {
        // 从历史中查找被吃的棋子
        // （简化实现：这里需要额外的数据结构来存储被吃的棋子）
        // TODO: 实现被吃棋子的恢复
        newBoard.set(lastMove.to.x, lastMove.to.y, null);
      } else {
        // 清空目标位置
        newBoard.set(lastMove.to.x, lastMove.to.y, null);
      }
    }

    // 切换回上一个行动方
    final newSideToMove = sideToMove == Side.red ? Side.black : Side.red;

    // 更新完整回合数
    final newFullmoveCount = newSideToMove == Side.black ? fullmoveCount - 1 : fullmoveCount;

    // 移除最后一条历史记录
    final newHistory = List<Move>.from(history)..removeLast();

    // 更新半回合计数器（简化处理：重置为0）
    // TODO: 实现正确的半回合计数器恢复
    const newHalfmoveClock = 0;

    return GameState(
      board: newBoard,
      sideToMove: newSideToMove,
      fullmoveCount: newFullmoveCount,
      history: newHistory,
      halfmoveClock: newHalfmoveClock,
    );
  }

  /// 检查当前行动方是否处于被将军状态
  ///
  /// 返回: true=被将军，false=未被将军
  bool isInCheck() {
    return MoveGenerator.isInCheck(this, sideToMove);
  }

  /// 检查当前行动方是否被将死
  ///
  /// 返回: true=被将死，false=未被将死
  bool isCheckmate() {
    // 如果没有被将军，肯定不是将死
    if (!isInCheck()) {
      return false;
    }

    // 如果被将军，检查是否有合法走法可以解除将军
    final legalMoves = MoveGenerator.getAllLegalMoves(this, sideToMove);

    // 没有合法走法 = 被将死
    return legalMoves.isEmpty;
  }

  /// 检查是否和棋（困毙）
  ///
  /// 返回: true=困毙（无子可动），false=有子可动
  bool isStalemate() {
    // 如果被将军，不是困毙（是将死）
    if (isInCheck()) {
      return false;
    }

    // 没有被将军，检查是否有合法走法
    final legalMoves = MoveGenerator.getAllLegalMoves(this, sideToMove);

    // 没有合法走法 = 困毙
    return legalMoves.isEmpty;
  }

  /// 检查是否和棋（任意原因）
  ///
  /// 返回: true=和棋，false=游戏继续
  bool isDraw() {
    // 原因1：困毙
    if (isStalemate()) {
      return true;
    }

    // 原因2：50回合无吃子规则（100半回合）
    if (halfmoveClock >= 100) {
      return true;
    }

    // 原因3：三次重复局面
    // TODO: 实现三次重复局面检测

    return false;
  }

  /// 检查指定方是否输了（所有棋子都没有king技能）
  ///
  /// 参数:
  /// - side: 要检查的阵营
  ///
  /// 返回: true=该方输了，false=该方还有king技能的棋子
  bool hasPlayerLost(Side side) {
    // 遍历棋盘，检查该方是否还有拥有king技能的棋子
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);
        if (piece != null && piece.side == side && piece.hasSkill(SkillType.king)) {
          // 找到一个拥有king技能的棋子，该方未输
          return false;
        }
      }
    }
    // 没有找到任何拥有king技能的棋子，该方输了
    return true;
  }

  /// 检查游戏是否结束
  ///
  /// 返回: true=游戏结束，false=游戏继续
  bool isGameOver() {
    // 检查是否有一方输了（没有king技能的棋子）
    if (hasPlayerLost(Side.red) || hasPlayerLost(Side.black)) {
      return true;
    }

    return isCheckmate() || isDraw();
  }

  /// 获取游戏结果
  ///
  /// 返回:
  /// - 'red_win': 红方胜
  /// - 'black_win': 黑方胜
  /// - 'draw': 和棋
  /// - null: 游戏未结束
  String? getResult() {
    // 优先检查是否有一方输了（没有king技能的棋子）
    if (hasPlayerLost(Side.red)) {
      return 'black_win';
    }
    if (hasPlayerLost(Side.black)) {
      return 'red_win';
    }

    if (isCheckmate()) {
      // 当前行动方被将死，对方获胜
      return sideToMove == Side.red ? 'black_win' : 'red_win';
    }

    if (isDraw()) {
      return 'draw';
    }

    return null;
  }

  /// 计算当前局面的唯一键（用于三次重复局面检测）
  ///
  /// 返回: 局面的字符串表示
  String computeKey() {
    final buffer = StringBuffer();

    // 遍历棋盘
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null) {
          // 记录棋子信息：阵营+技能类型
          buffer.write(piece.side == Side.red ? 'r' : 'b');

          // 简化：只记录第一个技能
          if (piece.skillsList.isNotEmpty) {
            buffer.write(piece.skillsList.first.typeId.index);
          }

          buffer.write('@$x,$y;');
        }
      }
    }

    // 添加当前行动方
    buffer.write('|${sideToMove == Side.red ? 'r' : 'b'}');

    return buffer.toString();
  }

  /// 创建副本（用于不可变状态管理）
  GameState copyWith({
    Board? board,
    Side? sideToMove,
    int? fullmoveCount,
    List<Move>? history,
    int? halfmoveClock,
  }) {
    return GameState(
      board: board ?? this.board,
      sideToMove: sideToMove ?? this.sideToMove,
      fullmoveCount: fullmoveCount ?? this.fullmoveCount,
      history: history ?? this.history,
      halfmoveClock: halfmoveClock ?? this.halfmoveClock,
    );
  }

  @override
  List<Object?> get props => [
        board,
        sideToMove,
        fullmoveCount,
        history,
        halfmoveClock,
      ];

  @override
  String toString() {
    return 'GameState(fullmove: $fullmoveCount, toMove: $sideToMove, '
        'moves: ${history.length}, halfmove: $halfmoveClock)';
  }
}
