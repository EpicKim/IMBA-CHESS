// 炮技能走法生成器
// 参考源文件: src/skills/cannon.lua
// 走法规则: 直线移动或隔一子吃子

import '../models/move.dart';
import '../models/board.dart';
import '../core/constants.dart';

/// 炮技能走法生成函数
///
/// 炮的走法规则：
/// 1. 不吃子时：沿直线走任意步（与车相同）
/// 2. 吃子时：必须隔一个棋子（炮台）才能吃
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateCannonMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 炮可以沿四个方向移动：右、左、下、上
  final directions = [
    [1, 0], // 向右
    [-1, 0], // 向左
    [0, 1], // 向下
    [0, -1], // 向上
  ];

  // 遍历四个方向
  for (final dir in directions) {
    final dx = dir[0];
    final dy = dir[1];

    // 从起始位置开始，沿方向前进
    var cx = x + dx;
    var cy = y + dy;

    // 标记是否已经跳过一个棋子（炮台）
    var jumped = false;

    // 持续移动直到超出棋盘
    while (BoardConstants.isInsideBoard(cx, cy)) {
      // 获取当前位置的棋子
      final targetPiece = board.get(cx, cy);

      if (!jumped) {
        // 未跳台阶段
        if (targetPiece != null) {
          // 遇到棋子，作为炮台
          jumped = true;
        } else {
          // 空位，可以走（不吃子的移动）
          moves.add(Move(
            from: Position(x, y),
            to: Position(cx, cy),
          ));
        }
      } else {
        // 已跳台阶段
        if (targetPiece != null) {
          // 遇到第二个棋子
          if (targetPiece.side != side) {
            // 敌方棋子，可以吃
            moves.add(Move(
              from: Position(x, y),
              to: Position(cx, cy),
              capturedPieceId: targetPiece.id,
              isCapture: true,
            ));
          }
          // 不管是否能吃，都停止继续搜索
          break;
        }
        // 如果是空位，继续前进寻找目标
      }

      // 继续沿方向前进
      cx += dx;
      cy += dy;
    }
  }

  return moves;
}

/// 按阵营返回显示名称（均为：炮）
String getCannonDisplayName(Side side) {
  return '炮';
}
