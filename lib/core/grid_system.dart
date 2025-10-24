// 坐标系统
// 参考源文件: src/game/GridSystem.lua
// 功能：屏幕坐标与棋盘坐标的转换，支持棋盘翻转

import 'dart:ui';
import 'constants.dart';

/// 棋盘坐标系统类
///
/// 负责：
/// 1. 屏幕坐标 ↔ 网格坐标的转换
/// 2. 支持棋盘翻转（本地玩家视角）
/// 3. 判断点击是否在棋盘范围内
class GridSystem {
  /// 棋盘绘制区域的偏移量（左上角坐标）
  final Offset boardOffset;

  /// 每个格子的大小
  final double cellSize;

  /// 本地玩家阵营（用于棋盘翻转）
  Side? localPlayerSide;

  /// 构造函数
  ///
  /// 参数:
  /// - boardOffset: 棋盘绘制区域的左上角坐标
  /// - cellSize: 每个格子的大小
  GridSystem({
    required this.boardOffset,
    required this.cellSize,
  });

  /// 设置本地玩家阵营
  ///
  /// 当设置为红方时，棋盘正常显示；
  /// 当设置为黑方时，棋盘翻转180度
  ///
  /// 参数:
  /// - side: 本地玩家阵营
  void setLocalPlayerSide(Side side) {
    localPlayerSide = side;
  }

  /// 屏幕坐标转换为网格坐标
  ///
  /// 参数:
  /// - screenX, screenY: 屏幕坐标
  ///
  /// 返回: 网格坐标 (x, y)，如果不在棋盘范围内则返回 null
  ({int x, int y})? screenToGrid(double screenX, double screenY) {
    // 转换为相对于棋盘左上角的坐标
    final relativeX = screenX - boardOffset.dx;
    final relativeY = screenY - boardOffset.dy;

    // 转换为网格坐标
    var gridX = (relativeX / cellSize).round();
    var gridY = (relativeY / cellSize).round();

    // 如果本地玩家是黑方，需要翻转坐标
    if (localPlayerSide == Side.black) {
      gridX = BoardConstants.boardWidth - 1 - gridX;
      gridY = BoardConstants.boardHeight - 1 - gridY;
    }

    // 检查是否在棋盘范围内
    if (!BoardConstants.isInsideBoard(gridX, gridY)) {
      return null;
    }

    return (x: gridX, y: gridY);
  }

  /// 网格坐标转换为屏幕坐标（棋子中心点）
  ///
  /// 参数:
  /// - gridX, gridY: 网格坐标
  ///
  /// 返回: 屏幕坐标
  Offset gridToScreen(int gridX, int gridY) {
    // 如果本地玩家是黑方，需要翻转坐标
    var displayX = gridX;
    var displayY = gridY;

    if (localPlayerSide == Side.black) {
      displayX = BoardConstants.boardWidth - 1 - gridX;
      displayY = BoardConstants.boardHeight - 1 - gridY;
    }

    // 计算屏幕坐标（格子中心点）
    final screenX = boardOffset.dx + displayX * cellSize;
    final screenY = boardOffset.dy + displayY * cellSize;

    return Offset(screenX, screenY);
  }

  /// 检查屏幕坐标是否在棋盘范围内
  ///
  /// 参数:
  /// - screenX, screenY: 屏幕坐标
  ///
  /// 返回: true=在棋盘内，false=不在棋盘内
  bool isScreenPointInBoard(double screenX, double screenY) {
    return screenToGrid(screenX, screenY) != null;
  }

  /// 检查屏幕坐标是否点击在棋子上
  ///
  /// 参数:
  /// - screenX, screenY: 屏幕坐标
  /// - gridX, gridY: 棋子的网格坐标
  /// - hitRadius: 点击判定半径
  ///
  /// 返回: true=点击在棋子上，false=未点击在棋子上
  bool isClickOnPiece(double screenX, double screenY, int gridX, int gridY, {double hitRadius = 25.0}) {
    // 获取棋子的屏幕坐标
    final pieceScreenPos = gridToScreen(gridX, gridY);

    // 计算距离
    final dx = screenX - pieceScreenPos.dx;
    final dy = screenY - pieceScreenPos.dy;
    final distance = dx * dx + dy * dy;

    // 判断是否在点击半径内
    return distance <= hitRadius * hitRadius;
  }

  /// 获取指定格子的边界矩形
  ///
  /// 参数:
  /// - gridX, gridY: 网格坐标
  ///
  /// 返回: 格子的屏幕边界矩形
  Rect getCellBounds(int gridX, int gridY) {
    final topLeft = gridToScreen(gridX, gridY);

    return Rect.fromLTWH(
      topLeft.dx - cellSize / 2,
      topLeft.dy - cellSize / 2,
      cellSize,
      cellSize,
    );
  }

  /// 获取整个棋盘的边界矩形
  ///
  /// 返回: 棋盘的屏幕边界矩形
  Rect getBoardBounds() {
    return Rect.fromLTWH(
      boardOffset.dx,
      boardOffset.dy,
      BoardConstants.boardWidth * cellSize,
      BoardConstants.boardHeight * cellSize,
    );
  }
}
