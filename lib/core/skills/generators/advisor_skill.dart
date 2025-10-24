// 士技能走法生成器
// 参考源文件: src/skills/advisor.lua
// 走法规则: 沿对角线走一步，不能离开九宫

import '../../../models/move.dart';
import '../../../models/board.dart';
import '../../constants.dart';

/// 士技能走法生成函数
///
/// 士的走法规则：
/// 1. 只能沿对角线移动一步
/// 2. 不能离开九宫格
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateAdvisorMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 士的4个可能移动位置（对角线方向）
  final candidates = [
    [1, 1], // 右下
    [1, -1], // 右上
    [-1, 1], // 左下
    [-1, -1], // 左上
  ];

  // 遍历所有可能的移动方向
  for (final candidate in candidates) {
    // 计算目标位置
    final tx = x + candidate[0];
    final ty = y + candidate[1];

    // 检查目标位置是否在棋盘内
    if (!BoardConstants.isInsideBoard(tx, ty)) {
      continue;
    }

    // 检查是否在九宫内
    // 红方九宫：x: 3-5, y: 7-9
    // 黑方九宫：x: 3-5, y: 0-2
    if (side == Side.red) {
      // 红方士必须在红方九宫内
      if (tx < BoardConstants.redPalaceLeft || tx > BoardConstants.redPalaceRight || ty < BoardConstants.redPalaceTop || ty > BoardConstants.redPalaceBottom) {
        continue;
      }
    } else {
      // 黑方士必须在黑方九宫内
      if (tx < BoardConstants.blackPalaceLeft || tx > BoardConstants.blackPalaceRight || ty < BoardConstants.blackPalaceTop || ty > BoardConstants.blackPalaceBottom) {
        continue;
      }
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

/// 按阵营返回显示名称（均为：士）
String getAdvisorDisplayName(Side side) {
  return '士';
}
