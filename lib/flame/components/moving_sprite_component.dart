// 移动精灵组件
// 功能：表示运动中的棋子，带朝向计算

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'piece_sprite_component.dart';

/// 移动精灵组件
/// 显示移动中的棋子（带朝向和移动动画）
class MovingSpriteComponent extends PieceSpriteComponent {
  // 目标位置（网格坐标）
  final int targetX;
  final int targetY;

  // 移动完成回调
  final void Function()? onMoveComplete;

  /// 构造函数
  MovingSpriteComponent({
    required super.piece,
    required super.gridX,
    required super.gridY,
    required this.targetX,
    required this.targetY,
    required super.gridSystem,
    required super.spriteCache,
    this.onMoveComplete,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 计算朝向角度（如果有精灵图）
    _calculateRotation();

    // 添加移动动画
    _startMoveAnimation();
  }

  /// 计算旋转角度
  void _calculateRotation() {
    // 计算从当前位置到目标位置的方向（使用相对于父组件的坐标）
    final fromPos = gridSystem.gridToComponentCoord(gridX, gridY);
    final toPos = gridSystem.gridToComponentCoord(targetX, targetY);

    final dx = toPos.dx - fromPos.dx;
    final dy = toPos.dy - fromPos.dy;

    // 计算角度（精灵图默认朝北，所以需要减去 pi/2）
    final targetAngle = math.atan2(dy, dx) - math.pi / 2;

    // 应用旋转
    angle = targetAngle;
  }

  /// 开始移动动画
  void _startMoveAnimation() {
    // 计算目标坐标（相对于父组件）
    final targetComponentPos = gridSystem.gridToComponentCoord(targetX, targetY);
    final targetVector = Vector2(targetComponentPos.dx, targetComponentPos.dy);

    // 添加移动效果（0.5秒移动到目标位置）
    final moveEffect = MoveEffect.to(
      targetVector,
      EffectController(duration: 0.5),
      onComplete: () {
        // 移动完成，触发回调
        if (onMoveComplete != null) {
          onMoveComplete!();
        }
      },
    );

    add(moveEffect);
  }
}
