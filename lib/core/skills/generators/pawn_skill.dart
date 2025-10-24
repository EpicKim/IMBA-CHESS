// 兵/卒技能走法生成器
// 参考源文件: src/skills/pawn.lua
// 走法规则: 前进一步；过河后可左右移动

import '../../../models/move.dart';
import '../../../models/board.dart';
import '../../constants.dart';

/// 兵/卒技能走法生成函数
///
/// 兵/卒的走法规则：
/// 1. 未过河：只能向前走一步
/// 2. 已过河：可以向前、向左、向右走一步（不能后退）
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generatePawnMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 判断是否已过河
  // 红方（side == red）过河：y < 5（进入黑方半场）
  // 黑方（side == black）过河：y >= 5（进入红方半场）
  final hasCrossedRiver = (side == Side.red && y < 5) || (side == Side.black && y >= 5);

  // 候选移动列表
  final candidates = <List<int>>[];

  if (side == Side.red) {
    // 红方兵：向上（-y方向）前进
    candidates.add([0, -1]); // 向上

    // 过河后可以左右移动
    if (hasCrossedRiver) {
      candidates.add([1, 0]); // 向右
      candidates.add([-1, 0]); // 向左
    }
  } else {
    // 黑方卒：向下（+y方向）前进
    candidates.add([0, 1]); // 向下

    // 过河后可以左右移动
    if (hasCrossedRiver) {
      candidates.add([1, 0]); // 向右
      candidates.add([-1, 0]); // 向左
    }
  }

  // 遍历所有可能的移动方向
  for (final candidate in candidates) {
    // 计算目标位置
    final tx = x + candidate[0];
    final ty = y + candidate[1];

    // 检查目标位置是否在棋盘内
    if (!BoardConstants.isInsideBoard(tx, ty)) {
      continue;
    }

    // 获取目标位置的棋子
    final targetPiece = board.get(tx, ty);

    // 如果目标位置为空，或有敌方棋子，则可以走
    if (targetPiece == null || targetPiece.side != side) {
      moves.add(Move(
        from: Position(x, y),
        to: Position(tx, ty),
        capturedPieceId: targetPiece?.id,
        isCapture: targetPiece != null,
      ));
    }
  }

  return moves;
}

/// 按阵营返回显示名称
/// 红方：兵，黑方：卒
String getPawnDisplayName(Side side) {
  return side == Side.red ? '兵' : '卒';
}
