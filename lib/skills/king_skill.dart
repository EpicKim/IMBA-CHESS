// 将/帅技能走法生成器
// 参考源文件: src/skills/king.lua
// 走法规则: 在四个正方向走一步（Imba象棋：无九宫格限制）

import '../models/move.dart';
import '../models/board.dart';
import '../core/constants.dart';

/// 将/帅技能走法生成函数
///
/// Imba象棋规则：
/// 1. 只能在四个正方向走一步（上下左右）
/// 2. 【无九宫格限制】- 可以在全棋盘范围内移动
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateKingMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 将/帅可以走的四个方向：右、左、下、上
  final directions = [
    [1, 0], // 右
    [-1, 0], // 左
    [0, 1], // 下
    [0, -1], // 上
  ];

  // 遍历所有可能的移动方向
  for (final dir in directions) {
    // 计算目标位置
    final tx = x + dir[0];
    final ty = y + dir[1];

    // 检查目标位置是否在棋盘内
    if (!BoardConstants.isInsideBoard(tx, ty)) {
      continue;
    }

    // Imba象棋特性：将/帅技能不受九宫格限制！
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
/// 红方：帅，黑方：将
String getKingDisplayName(Side side) {
  return side == Side.red ? '帅' : '将';
}
