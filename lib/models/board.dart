// 棋盘数据模型
// 参考源文件: src/game/Board.lua

import '../core/constants.dart';
import '../skills/skill_types.dart';
import 'piece.dart';
import 'move.dart';

/// 棋盘类
/// 负责管理 9x10 棋盘上所有棋子的位置和状态
class Board {
  // 棋盘网格：grid[y][x] 存储位置 (x, y) 上的棋子
  // null 表示该位置为空
  final List<List<Piece?>> grid;

  Board._(this.grid);

  /// 默认构造函数：创建空棋盘
  Board()
      : this._(List.generate(
          BoardConstants.rows,
          (y) => List<Piece?>.filled(BoardConstants.cols, null),
        ));

  /// 创建空棋盘（工厂方法）
  factory Board.empty() {
    return Board();
  }

  /// 获取指定位置的棋子
  ///
  /// 参数：
  /// - x: 列坐标 (0-8)
  /// - y: 行坐标 (0-9)
  ///
  /// 返回：该位置的棋子，如果位置无效或为空则返回 null
  Piece? get(int x, int y) {
    // 检查坐标是否在棋盘内
    if (!BoardConstants.isInsideBoard(x, y)) {
      return null;
    }

    return grid[y][x];
  }

  /// 设置指定位置的棋子
  ///
  /// 参数：
  /// - x: 列坐标 (0-8)
  /// - y: 行坐标 (0-9)
  /// - piece: 要放置的棋子（null 表示移除棋子）
  void set(int x, int y, Piece? piece) {
    // 检查坐标是否在棋盘内
    if (!BoardConstants.isInsideBoard(x, y)) {
      return;
    }

    grid[y][x] = piece;
  }

  /// 查找指定阵营的将/帅位置
  ///
  /// 参数：
  /// - side: 阵营（红方/黑方）
  ///
  /// 返回：将/帅的位置，如果找不到返回 null
  Position? findKing(Side side) {
    // 遍历整个棋盘
    for (int y = 0; y < BoardConstants.rows; y++) {
      for (int x = 0; x < BoardConstants.cols; x++) {
        final piece = grid[y][x];

        // 检查是否是目标阵营的棋子，且拥有将/帅技能
        if (piece != null && piece.side == side && piece.hasSkill(SkillType.king)) {
          return Position(x, y);
        }
      }
    }

    return null; // 未找到
  }

  /// 清空棋盘
  void clear() {
    for (int y = 0; y < BoardConstants.rows; y++) {
      for (int x = 0; x < BoardConstants.cols; x++) {
        grid[y][x] = null;
      }
    }
  }

  /// 复制棋盘（深拷贝）
  Board copy() {
    final newGrid = List.generate(
      BoardConstants.rows,
      (y) => List<Piece?>.from(grid[y]),
    );
    return Board._(newGrid);
  }

  /// 获取所有棋子及其位置
  /// 返回：[(piece, position), ...]
  List<(Piece, Position)> getAllPieces() {
    final pieces = <(Piece, Position)>[];

    for (int y = 0; y < BoardConstants.rows; y++) {
      for (int x = 0; x < BoardConstants.cols; x++) {
        final piece = grid[y][x];
        if (piece != null) {
          pieces.add((piece, Position(x, y)));
        }
      }
    }

    return pieces;
  }

  /// 获取指定阵营的所有棋子及其位置
  List<(Piece, Position)> getPiecesBySide(Side side) {
    return getAllPieces().where((tuple) => tuple.$1.side == side).toList();
  }

  /// 统计棋盘上的棋子数量
  int get pieceCount {
    int count = 0;
    for (int y = 0; y < BoardConstants.rows; y++) {
      for (int x = 0; x < BoardConstants.cols; x++) {
        if (grid[y][x] != null) {
          count++;
        }
      }
    }
    return count;
  }

  /// 创建副本（深拷贝）
  Board copyWith() {
    final board = Board();

    // 复制所有棋子
    for (int y = 0; y < BoardConstants.rows; y++) {
      for (int x = 0; x < BoardConstants.cols; x++) {
        board.grid[y][x] = grid[y][x];
      }
    }

    return board;
  }

  /// 设置初始棋局
  void setupInitial() {
    // 创建红方棋子（带初始技能）
    _setupRedPieces();

    // 创建黑方棋子（带初始技能）
    _setupBlackPieces();
  }

  /// 设置红方初始棋子
  void _setupRedPieces() {
    // 红方车（0,9）和（8,9）
    set(0, 9, Piece.withSkills(1, Side.red, '车', [SkillType.rook]));
    set(8, 9, Piece.withSkills(2, Side.red, '车', [SkillType.rook]));

    // 红方马（1,9）和（7,9）
    set(1, 9, Piece.withSkills(3, Side.red, '馬', [SkillType.knight]));
    set(7, 9, Piece.withSkills(4, Side.red, '馬', [SkillType.knight]));

    // 红方相（2,9）和（6,9）
    set(2, 9, Piece.withSkills(5, Side.red, '相', [SkillType.bishop]));
    set(6, 9, Piece.withSkills(6, Side.red, '相', [SkillType.bishop]));

    // 红方士（3,9）和（5,9）
    set(3, 9, Piece.withSkills(7, Side.red, '士', [SkillType.advisor]));
    set(5, 9, Piece.withSkills(8, Side.red, '士', [SkillType.advisor]));

    // 红方帅（4,9）
    set(4, 9, Piece.withSkills(9, Side.red, '帥', [SkillType.king]));

    // 红方炮（1,7）和（7,7）
    set(1, 7, Piece.withSkills(10, Side.red, '炮', [SkillType.cannon]));
    set(7, 7, Piece.withSkills(11, Side.red, '炮', [SkillType.cannon]));

    // 红方兵（0,6）、（2,6）、（4,6）、（6,6）、（8,6）
    set(0, 6, Piece.withSkills(12, Side.red, '兵', [SkillType.pawn]));
    set(2, 6, Piece.withSkills(13, Side.red, '兵', [SkillType.pawn]));
    set(4, 6, Piece.withSkills(14, Side.red, '兵', [SkillType.pawn]));
    set(6, 6, Piece.withSkills(15, Side.red, '兵', [SkillType.pawn]));
    set(8, 6, Piece.withSkills(16, Side.red, '兵', [SkillType.pawn]));
  }

  /// 设置黑方初始棋子
  void _setupBlackPieces() {
    // 黑方车（0,0）和（8,0）
    set(0, 0, Piece.withSkills(17, Side.black, '车', [SkillType.rook]));
    set(8, 0, Piece.withSkills(18, Side.black, '车', [SkillType.rook]));

    // 黑方马（1,0）和（7,0）
    set(1, 0, Piece.withSkills(19, Side.black, '馬', [SkillType.knight]));
    set(7, 0, Piece.withSkills(20, Side.black, '馬', [SkillType.knight]));

    // 黑方象（2,0）和（6,0）
    set(2, 0, Piece.withSkills(21, Side.black, '象', [SkillType.bishop]));
    set(6, 0, Piece.withSkills(22, Side.black, '象', [SkillType.bishop]));

    // 黑方士（3,0）和（5,0）
    set(3, 0, Piece.withSkills(23, Side.black, '士', [SkillType.advisor]));
    set(5, 0, Piece.withSkills(24, Side.black, '士', [SkillType.advisor]));

    // 黑方将（4,0）
    set(4, 0, Piece.withSkills(25, Side.black, '將', [SkillType.king]));

    // 黑方炮（1,2）和（7,2）
    set(1, 2, Piece.withSkills(26, Side.black, '炮', [SkillType.cannon]));
    set(7, 2, Piece.withSkills(27, Side.black, '炮', [SkillType.cannon]));

    // 黑方卒（0,3）、（2,3）、（4,3）、（6,3）、（8,3）
    set(0, 3, Piece.withSkills(28, Side.black, '卒', [SkillType.pawn]));
    set(2, 3, Piece.withSkills(29, Side.black, '卒', [SkillType.pawn]));
    set(4, 3, Piece.withSkills(30, Side.black, '卒', [SkillType.pawn]));
    set(6, 3, Piece.withSkills(31, Side.black, '卒', [SkillType.pawn]));
    set(8, 3, Piece.withSkills(32, Side.black, '卒', [SkillType.pawn]));
  }

  /// 创建初始棋盘布局
  static Board initial() {
    final board = Board();
    board.setupInitial();
    return board;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Board {');

    for (int y = 0; y < BoardConstants.rows; y++) {
      buffer.write('  $y: ');
      for (int x = 0; x < BoardConstants.cols; x++) {
        final piece = grid[y][x];
        if (piece == null) {
          buffer.write(' . ');
        } else {
          buffer.write(' ${piece.label ?? '?'} ');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('}');
    return buffer.toString();
  }
}
