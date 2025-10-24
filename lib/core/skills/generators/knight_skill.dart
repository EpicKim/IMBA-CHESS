// 马技能走法生成器
// 参考源文件: src/skills/knight.lua
// 走法规则: 日字走法（注意：本游戏不检查蹩马腿）

import '../../../models/move.dart';
import '../../../models/board.dart';
import '../../constants.dart';

/// 马技能走法生成函数
///
/// 注意：本游戏中马技能不检查蹩马腿
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateKnightMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 马的8个可能移动位置（日字的8个方向）
  final candidates = [
    [1, 2], // 右一，下二
    [-1, 2], // 左一，下二
    [1, -2], // 右一，上二
    [-1, -2], // 左一，上二
    [2, 1], // 右二，下一
    [2, -1], // 右二，上一
    [-2, 1], // 左二，下一
    [-2, -1], // 左二，上一
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

/// 按阵营返回显示名称（均为：马）
String getKnightDisplayName(Side side) {
  return '马';
}
