// 棋子精灵组件
// 功能：显示棋子（支持精灵图和文字混合）

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, TextPainter, TextSpan, TextStyle, TextDirection, TextAlign, FontWeight;
import '../../models/piece.dart';
import '../../core/grid_system.dart';
import '../../core/constants.dart';
import '../../skills/skill_types.dart';
import '../../ui/board/board_painter.dart';
import '../sprite_cache.dart';

/// 棋子精灵组件
/// 显示单个棋子（支持精灵图和文字绘制）
class PieceSpriteComponent extends PositionComponent {
  // 棋子数据
  final Piece piece;

  // 网格坐标
  final int gridX;
  final int gridY;

  // 坐标系统
  final GridSystem gridSystem;

  // 精灵缓存
  final SpriteCache spriteCache;

  // 棋子精灵（如果有）
  Sprite? _sprite;

  // 是否可见
  double opacity = 1.0;

  /// 构造函数
  PieceSpriteComponent({
    required this.piece,
    required this.gridX,
    required this.gridY,
    required this.gridSystem,
    required this.spriteCache,
  }) : super();

  @override
  Future<void> onLoad() async {
    // 设置位置：使用相对于父组件（BoardSpriteComponent）的坐标
    // gridToComponentCoord 返回的是相对于父组件左上角的坐标
    final componentPos = gridSystem.gridToComponentCoord(gridX, gridY);
    position = Vector2(componentPos.dx, componentPos.dy);

    // 设置尺寸
    final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;
    size = Vector2(radius * 2, radius * 2);

    // 设置锚点为中心（position 指向棋子中心，正好对齐网格线交叉点）
    anchor = Anchor.topLeft;

    // 根据棋子技能加载对应精灵
    _loadSprite();

    print('[PieceSpriteComponent.onLoad] 棋子(${piece.label}) grid($gridX,$gridY) -> componentPos($componentPos) -> position($position)');
  }

  /// 加载棋子精灵
  void _loadSprite() {
    // 检查是否有车技能（使用车的精灵图）
    if (piece.hasSkill(SkillType.rook)) {
      final key = piece.side == Side.red ? 'rook_red' : 'rook_black';
      _sprite = spriteCache.get(key);
      return;
    }

    // 检查是否有炮技能（使用炮的精灵图）
    if (piece.hasSkill(SkillType.cannon)) {
      // 注意：这里假设红方和黑方都使用同一个炮精灵，如果有分别的精灵需要修改
      _sprite = spriteCache.get('cannon_red');
      return;
    }

    // 其他棋子不使用精灵图（用文字绘制）
    _sprite = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 如果不可见，跳过绘制
    if (opacity <= 0) {
      return;
    }

    // 保存canvas状态
    canvas.save();

    // 应用透明度
    if (opacity < 1.0) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, opacity));
    }

    if (_sprite != null) {
      // 使用精灵图绘制
      _drawSprite(canvas);
    } else {
      // 使用文字绘制
      _drawText(canvas);
    }

    // 绘制技能徽章
    _drawSkillBadges(canvas);

    // 恢复canvas状态
    if (opacity < 1.0) {
      canvas.restore();
    }
    canvas.restore();
  }

  /// 绘制精灵图
  void _drawSprite(Canvas canvas) {
    if (_sprite == null) return;

    final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;

    // 绘制棋子底色圆形
    final bgPaint = Paint()
      ..color = piece.side == Side.red ? BoardUIConfig.redPieceColor : BoardUIConfig.blackPieceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, bgPaint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = BoardUIConfig.boardBorderColor
      ..strokeWidth = gridSystem.cellSize * BoardUIConfig.pieceBorderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    // 在圆形内绘制精灵图
    _sprite!.render(
      canvas,
      position: Vector2(-radius, -radius),
      size: Vector2(radius * 2, radius * 2),
    );
  }

  /// 绘制文字棋子
  void _drawText(Canvas canvas) {
    final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;

    // 绘制棋子底色
    final bgPaint = Paint()
      ..color = piece.side == Side.red ? BoardUIConfig.redPieceColor : BoardUIConfig.blackPieceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, bgPaint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = BoardUIConfig.boardBorderColor
      ..strokeWidth = gridSystem.cellSize * BoardUIConfig.pieceBorderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    // 绘制文字
    if (piece.label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: piece.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: gridSystem.cellSize * BoardUIConfig.pieceFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'DingLieZhuHai',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        ),
      );
    }
  }

  /// 绘制技能徽章
  void _drawSkillBadges(Canvas canvas) {
    // 获取额外技能（跳过主技能）
    final extraSkills = piece.skillsList.length > 1 ? piece.skillsList.sublist(1) : [];

    for (var i = 0; i < extraSkills.length; i++) {
      final skill = extraSkills[i];
      final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;

      // 计算徽章角度
      final angle = (i * math.pi / (extraSkills.length + 0.5)) - math.pi / 4;
      final badgePos = Offset(
        math.cos(angle) * (radius * 0.75),
        math.sin(angle) * (radius * 0.75),
      );
      final badgeRadius = gridSystem.cellSize * BoardUIConfig.badgeRadius;

      // 绘制徽章圆形
      canvas.drawCircle(
        badgePos,
        badgeRadius,
        Paint()
          ..color = BoardUIConfig.skillBadgeColor
          ..style = PaintingStyle.fill,
      );

      // 绘制徽章边框
      canvas.drawCircle(
        badgePos,
        badgeRadius,
        Paint()
          ..color = const Color.fromRGBO(76, 51, 25, 1.0)
          ..strokeWidth = gridSystem.cellSize * BoardUIConfig.badgeBorderWidth
          ..style = PaintingStyle.stroke,
      );

      // 绘制徽章文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: skill.getDisplayName(piece.side),
          style: TextStyle(
            color: const Color.fromRGBO(51, 25, 0, 1.0),
            fontSize: gridSystem.cellSize * BoardUIConfig.badgeFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'DingLieZhuHai',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          badgePos.dx - textPainter.width / 2,
          badgePos.dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// 更新位置
  void updatePosition(int newX, int newY) {
    final componentPos = gridSystem.gridToComponentCoord(newX, newY);
    position = Vector2(componentPos.dx, componentPos.dy);
  }
}
