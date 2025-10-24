// 相/象技能走法生成器
// 参考源文件: src/skills/bishop.lua
// 走法规则: 田字走法，不能过河（注意：本游戏不检查塞象眼）

import '../../../models/move.dart';
import '../../../models/board.dart';
import '../../constants.dart';

/// 相/象技能走法生成函数
///
/// 注意：
/// 1. 本游戏中象技能不检查塞象眼
/// 2. 相/象不能过河
///
/// 参数:
/// - state: 游戏状态对象
/// - x, y: 棋子当前位置
/// - side: 棋子所属阵营
/// - piece: 棋子对象
///
/// 返回: 走法列表
List<Move> generateBishopMoves(dynamic state, int x, int y, Side side, dynamic piece) {
  final moves = <Move>[];
  final board = state.board as Board;

  // 相/象的4个可能移动位置（田字的4个对角）
  final candidates = [
    [2, 2], // 右二，下二
    [2, -2], // 右二，上二
    [-2, 2], // 左二，下二
    [-2, -2], // 左二，上二
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

    // 检查是否过河
    // 红方（side == red）：不能到 y < 5 的区域
    // 黑方（side == black）：不能到 y >= 5 的区域
    if (side == Side.red && ty < 5) {
      continue; // 红相过河
    }
    if (side == Side.black && ty >= 5) {
      continue; // 黑象过河
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
/// 红方：相，黑方：象
String getBishopDisplayName(Side side) {
  return side == Side.red ? '相' : '象';
}
