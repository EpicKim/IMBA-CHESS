// 撞飞动画组件
// 功能：Cannon吃子时的撞飞效果

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../models/piece.dart';
import '../../core/grid_system.dart';
import 'piece_sprite_component.dart';
import '../sprite_cache.dart';

/// 撞飞动画组件
/// Cannon吃子时，被吃棋子的撞飞效果（沿移动方向飞出、旋转、缩小）
class KnockbackAnimationComponent extends PieceSpriteComponent {
  // 初始速度
  Vector2 velocity;

  // 角速度（弧度/秒）
  double angularVel;

  // 重力加速度
  static const double gravity = 500.0;

  // 缩放比例
  double _scale = 1.0;

  // 动画完成回调
  final void Function()? onComplete;

  /// 构造函数
  KnockbackAnimationComponent({
    required super.piece,
    required super.gridX,
    required super.gridY,
    required super.gridSystem,
    required super.spriteCache,
    required this.velocity,
    required this.angularVel,
    this.onComplete,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // 更新位置（抛物线轨迹）
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // 更新速度（重力）
    velocity.y += gravity * dt;

    // 更新旋转
    angle += angularVel * dt;

    // 更新缩放（逐渐缩小）
    _scale -= dt * 2.0;

    if (_scale <= 0) {
      _scale = 0;

      // 动画完成，移除自身
      if (onComplete != null) {
        onComplete!();
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 保存canvas状态
    canvas.save();

    // 应用缩放
    canvas.scale(_scale, _scale);

    // 绘制棋子
    super.render(canvas);

    // 恢复canvas状态
    canvas.restore();
  }

  /// 创建撞飞动画（根据移动方向计算初始速度）
  static KnockbackAnimationComponent create({
    required Piece piece,
    required int gridX,
    required int gridY,
    required GridSystem gridSystem,
    required SpriteCache spriteCache,
    required int fromX,
    required int fromY,
    void Function()? onComplete,
  }) {
    // 计算移动方向
    final fromPos = gridSystem.gridToScreen(fromX, fromY);
    final toPos = gridSystem.gridToScreen(gridX, gridY);

    final dx = toPos.dx - fromPos.dx;
    final dy = toPos.dy - fromPos.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // 归一化方向
    final dirX = dx / distance;
    final dirY = dy / distance;

    // 设置初始速度（沿移动方向）
    final initialVelocity = Vector2(dirX * 200, dirY * 200);

    // 设置角速度（随机方向，2-3圈/秒）
    final angularVelocity = (math.Random().nextDouble() + 2) * math.pi * 2;

    return KnockbackAnimationComponent(
      piece: piece,
      gridX: gridX,
      gridY: gridY,
      gridSystem: gridSystem,
      spriteCache: spriteCache,
      velocity: initialVelocity,
      angularVel: angularVelocity,
      onComplete: onComplete,
    );
  }
}
