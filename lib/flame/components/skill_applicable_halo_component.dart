// 可赋予技能的蓝色光圈组件
// 功能：在技能赋予阶段显示可选棋子的提示

import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/grid_system.dart';

/// 蓝色光圈组件
/// 在技能赋予阶段显示在可选棋子周围
class SkillApplicableHaloComponent extends PositionComponent {
  // 坐标系统
  final GridSystem gridSystem;

  // 网格坐标
  final int gridX;
  final int gridY;

  /// 构造函数
  SkillApplicableHaloComponent({
    required this.gridSystem,
    required this.gridX,
    required this.gridY,
  }) : super();

  @override
  Future<void> onLoad() async {
    // 设置位置：使用相对于父组件（BoardSpriteComponent）的坐标
    final componentPos = gridSystem.gridToComponentCoord(gridX, gridY);
    position = Vector2(componentPos.dx, componentPos.dy);

    // 设置尺寸
    final radius = gridSystem.cellSize * 0.45 * 1.4; // 最外层半径
    size = Vector2(radius * 2, radius * 2);

    // 设置锚点为中心
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radius = gridSystem.cellSize * 0.45; // 基础半径

    // 5层光圈，从外到内
    // 最外层光晕
    final paint1 = Paint()
      ..color = const Color.fromRGBO(76, 153, 255, 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 1.4, paint1);

    // 外层光晕
    final paint2 = Paint()
      ..color = const Color.fromRGBO(89, 165, 255, 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 1.3, paint2);

    // 外环蓝色
    final paint3 = Paint()
      ..color = const Color.fromRGBO(102, 178, 255, 0.65)
      ..strokeWidth = gridSystem.cellSize * 0.065
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius * 1.26, paint3);

    // 中环亮蓝色
    final paint4 = Paint()
      ..color = const Color.fromRGBO(128, 204, 255, 0.75)
      ..strokeWidth = gridSystem.cellSize * 0.04
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius * 1.12, paint4);

    // 内环最亮蓝色
    final paint5 = Paint()
      ..color = const Color.fromRGBO(153, 217, 255, 0.85)
      ..strokeWidth = gridSystem.cellSize * 0.025
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius * 1.03, paint5);
  }
}
