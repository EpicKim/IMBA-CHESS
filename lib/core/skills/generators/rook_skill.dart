// 车技能走法生成器
// 参考源文件: src/skills/rook.lua
// 走法规则: 沿直线走任意步（横向或纵向）

import '../../../models/move.dart';
import '../../../models/board.dart';
import '../../constants.dart';

/// 车技能走法生成函数
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateRookMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 车可以沿四个方向移动：右、左、下、上
  final directions = [
    [1, 0], // 向右
    [-1, 0], // 向左
    [0, 1], // 向下
    [0, -1], // 向上
  ];

  // 遍历四个方向
  for (final dir in directions) {
    // 沿该方向生成一条直线上的所有走法
    _generateLine(moves, board, x, y, dir[0], dir[1], side);
  }

  return moves;
}

/// 内部辅助函数：沿指定方向生成一条直线上的所有走法
///
/// 参数:
/// - moves: 走法列表（输出）
/// - board: 棋盘对象
/// - x, y: 起始位置
/// - dx, dy: 移动方向
/// - side: 棋子所属阵营
void _generateLine(List<Move> moves, Board board, int x, int y, int dx, int dy, Side side) {
  // 从起始位置开始，沿方向前进
  var cx = x + dx;
  var cy = y + dy;

  // 持续移动直到超出棋盘或遇到障碍
  while (BoardConstants.isInsideBoard(cx, cy)) {
    // 检查当前位置是否有棋子
    final targetPiece = board.get(cx, cy);

    if (targetPiece != null) {
      // 遇到棋子
      if (targetPiece.side != side) {
        // 敌方棋子：可以吃，但不能继续前进
        moves.add(Move(
          from: Position(x, y),
          to: Position(cx, cy),
          capturedPieceId: targetPiece.id,
          isCapture: true,
        ));
      }
      // 己方棋子：不能吃，不能继续前进
      break;
    } else {
      // 空位：可以走
      moves.add(Move(
        from: Position(x, y),
        to: Position(cx, cy),
      ));
    }

    // 继续沿方向前进
    cx += dx;
    cy += dy;
  }
}

/// 按阵营返回显示名称（均为：车）
String getRookDisplayName(Side side) {
  return '车';
}
