// 游戏常量和枚举定义
// 参考源文件: src/game/constants.lua

/// 阵营枚举（红方/黑方）
enum Side {
  red, // 红方（索引0）
  black, // 黑方（索引1）
}

/// 棋盘常量类
class BoardConstants {
  // 棋盘几何参数
  static const int cols = 9; // 棋盘列数（横向）
  static const int rows = 10; // 棋盘行数（纵向）

  // 别名（为了兼容性）
  static const int boardWidth = cols; // 棋盘宽度
  static const int boardHeight = rows; // 棋盘高度

  // 默认UI参数（实际运行时会动态计算）
  static const double defaultCellSize = 64.0; // 默认格子大小（像素）
  static const double boardMargin = 40.0; // 棋盘边距（像素）

  // 九宫格范围定义
  static const redPalace = PalaceArea(
    xMin: 3, // 红方九宫格最小列索引
    xMax: 5, // 红方九宫格最大列索引
    yMin: 7, // 红方九宫格最小行索引
    yMax: 9, // 红方九宫格最大行索引
  );

  static const blackPalace = PalaceArea(
    xMin: 3, // 黑方九宫格最小列索引
    xMax: 5, // 黑方九宫格最大列索引
    yMin: 0, // 黑方九宫格最小行索引
    yMax: 2, // 黑方九宫格最大行索引
  );

  // 九宫格边界常量（用于advisor_skill.dart）
  static const int redPalaceLeft = 3;
  static const int redPalaceRight = 5;
  static const int redPalaceTop = 7;
  static const int redPalaceBottom = 9;
  static const int blackPalaceLeft = 3;
  static const int blackPalaceRight = 5;
  static const int blackPalaceTop = 0;
  static const int blackPalaceBottom = 2;

  // 楚河汉界位置（第4行和第5行之间是河）
  static const int riverY = 4;

  // 辅助函数：检查坐标是否在棋盘范围内
  static bool isInsideBoard(int x, int y) {
    return x >= 0 && x < cols && y >= 0 && y < rows;
  }

  // 辅助函数：检查坐标是否在九宫格内
  static bool isInsidePalace(Side side, int x, int y) {
    final palace = (side == Side.red) ? redPalace : blackPalace;
    return x >= palace.xMin && x <= palace.xMax && y >= palace.yMin && y <= palace.yMax;
  }

  // 获取指定阵营的前进方向
  // 红方在下方（y值大），向上走是减小y；黑方在上方，向下走是增加y
  static int forwardDir(Side side) {
    return (side == Side.red) ? -1 : 1;
  }

  // 阵营转换为索引（用于数组访问）
  static int sideToIndex(Side side) {
    return side == Side.red ? 0 : 1;
  }

  // 索引转换为阵营
  static Side indexToSide(int index) {
    return index == 0 ? Side.red : Side.black;
  }

  // 获取对手阵营
  static Side opponentSide(Side side) {
    return side == Side.red ? Side.black : Side.red;
  }
}

/// 九宫格区域定义
class PalaceArea {
  final int xMin; // 最小列索引
  final int xMax; // 最大列索引
  final int yMin; // 最小行索引
  final int yMax; // 最大行索引

  const PalaceArea({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });
}
