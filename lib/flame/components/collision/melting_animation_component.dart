// 熔化动画组件
// 功能：Rook吃子时的熔化效果

import 'dart:ui';
import 'package:flutter/material.dart' show Color;
import '../piece_sprite_component.dart';

/// 熔化动画组件
/// Rook吃子时，被吃棋子的熔化效果（像烧纸片一样从头到脚烧毁）
class MeltingAnimationComponent extends PieceSpriteComponent {
  // 动画进度（0→1）
  double _progress = 0.0;

  // 动画持续时间（秒）
  static const double duration = 0.8;

  // 动画完成回调
  final void Function()? onComplete;

  /// 构造函数
  MeltingAnimationComponent({
    required super.piece,
    required super.gridX,
    required super.gridY,
    required super.gridSystem,
    required super.spriteCache,
    this.onComplete,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // 更新动画进度
    _progress += dt / duration;

    if (_progress >= 1.0) {
      _progress = 1.0;

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

    // 使用ClipRect限制渲染区域（从上往下逐渐缩小）
    final radius = gridSystem.cellSize * 0.42;
    final clipHeight = radius * 2 * (1 - _progress);

    canvas.clipRect(Rect.fromLTWH(
      -radius,
      -radius,
      radius * 2,
      clipHeight,
    ));

    // 应用颜色渐变效果
    // 正常 → 橙色 → 暗红 → 黑色 → 消失
    Color color;
    if (_progress < 0.25) {
      // 正常 → 橙色
      color = Color.lerp(
        const Color(0xFFFFFFFF),
        const Color(0xFFFF8800),
        _progress / 0.25,
      )!;
    } else if (_progress < 0.5) {
      // 橙色 → 暗红
      color = Color.lerp(
        const Color(0xFFFF8800),
        const Color(0xFF880000),
        (_progress - 0.25) / 0.25,
      )!;
    } else if (_progress < 0.75) {
      // 暗红 → 黑色
      color = Color.lerp(
        const Color(0xFF880000),
        const Color(0xFF000000),
        (_progress - 0.5) / 0.25,
      )!;
    } else {
      // 黑色 → 透明
      color = Color.lerp(
        const Color(0xFF000000),
        const Color(0x00000000),
        (_progress - 0.75) / 0.25,
      )!;
    }

    // 应用颜色滤镜
    final paint = Paint()..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
    canvas.saveLayer(null, paint);

    // 绘制棋子
    super.render(canvas);

    // 恢复canvas状态
    canvas.restore();
    canvas.restore();
  }
}
