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
  /// 每个格子的大小
  double cellSize;

  /// 本地玩家阵营（用于棋盘翻转）
  Side? localPlayerSide;

  /// 构造函数
  ///
  /// 参数:
  /// - cellSize: 每个格子的大小
  GridSystem({
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
  /// - screenX, screenY: 屏幕坐标（相对于 BoardSpriteComponent 左上角）
  ///
  /// 返回: 网格坐标 (x, y)，如果不在棋盘范围内则返回 null
  ({int x, int y})? screenToGrid(double screenX, double screenY) {
    // BoardSpriteComponent 左上角就是第一个交叉点，无需减去 boardOffset
    // 直接转换为网格坐标
    var gridX = (screenX / cellSize).round();
    var gridY = (screenY / cellSize).round();

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

  /// 网格坐标转换为屏幕坐标（网格线交叉点，即棋子中心点）
  ///
  /// 中国象棋的棋子放在网格线的交叉点上，所以：
  /// - 网格 (0,0) 对应第一个交叉点，位置是 boardOffset
  /// - 网格 (x,y) 对应的交叉点位置是 boardOffset + (x * cellSize, y * cellSize)
  ///
  /// 参数:
  /// - gridX, gridY: 网格坐标
  ///
  /// 返回: 屏幕坐标（网格线交叉点位置，相对于 BoardSpriteComponent 左上角）
  Offset gridToScreen(int gridX, int gridY) {
    // 如果本地玩家是黑方，需要翻转坐标
    var displayX = gridX;
    var displayY = gridY;

    if (localPlayerSide == Side.black) {
      displayX = BoardConstants.boardWidth - 1 - gridX;
      displayY = BoardConstants.boardHeight - 1 - gridY;
    }

    // 计算屏幕坐标（网格线交叉点）
    // BoardSpriteComponent 的左上角 (0,0) 就是第一个网格线交叉点
    // 每个格子的交叉点间距是 cellSize
    final screenX = displayX * cellSize;
    final screenY = displayY * cellSize;

    return Offset(screenX, screenY);
  }

  /// 网格坐标转换为组件内坐标（用于Flame子组件）
  ///
  /// 【架构说明】
  /// BoardSpriteComponent:
  ///   - position: 在 Flame 世界中的居中位置
  ///   - size: 棋盘总尺寸（网格尺寸）
  ///   - anchor: Anchor.topLeft
  ///   - 左上角 (0,0) 就是第一个网格线交叉点
  ///   - 子组件（棋子、光圈）的 position 相对于它的左上角
  ///
  /// 坐标系统：
  ///   - 网格 (0,0) 对应的子组件 position 是 (0, 0)
  ///   - 网格 (x,y) 对应的子组件 position 是 (x * cellSize, y * cellSize)
  ///
  /// 注：棋子的 anchor = Anchor.center，所以 position 指向棋子中心，正好和网格线交叉点对齐。
  ///
  /// 参数:
  /// - gridX, gridY: 网格坐标
  ///
  /// 返回: 组件内坐标（相对于父组件左上角，用于子组件的 position）
  Offset gridToComponentCoord(int gridX, int gridY) {
    // 直接使用 gridToScreen，因为它已经返回了正确的相对坐标
    // （相对于 BoardSpriteComponent 左上角）
    return gridToScreen(gridX, gridY);
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
      0,
      0,
      BoardConstants.boardWidth * cellSize,
      BoardConstants.boardHeight * cellSize,
    );
  }
}
