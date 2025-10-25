// 棋盘精灵组件
// 功能：绘制棋盘网格、高亮、特殊标记

import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors;
import '../../models/board.dart';
import '../../models/move.dart';
import '../../core/grid_system.dart';
import '../../core/constants.dart';
import '../../ui/board/board_painter.dart';

/// 棋盘精灵组件
/// 负责绘制棋盘背景、网格线、高亮效果
/// 管理所有棋子和光圈作为子组件
class BoardSpriteComponent extends PositionComponent with TapCallbacks {
  // 棋盘数据
  Board board;

  // 坐标系统
  final GridSystem gridSystem;

  // 选中的棋子位置
  Position? selectedPiece;

  // 合法移动列表
  List<Move> legalMoves;

  // 上一步移动
  Move? lastMove;

  // 点击回调
  final void Function(int x, int y)? onTap;

  // 棋子精灵映射（key: "x,y"）- 作为子组件管理
  final Map<String, Component> pieces = {};

  // 蓝色光圈组件列表 - 作为子组件管理
  final List<Component> halos = [];

  /// 构造函数
  BoardSpriteComponent({
    required this.board,
    required this.gridSystem,
    this.selectedPiece,
    this.legalMoves = const [],
    this.lastMove,
    this.onTap,
  }) : super();

  @override
  Future<void> onLoad() async {
    // 设置锚点为左上角，这样子组件的相对坐标就是从(0,0)开始
    anchor = Anchor.topLeft;

    // 设置组件尺寸（纯网格尺寸，无额外边距）
    size = Vector2(
      BoardConstants.boardWidth * gridSystem.cellSize,
      BoardConstants.boardHeight * gridSystem.cellSize,
    );

    print('[BoardSpriteComponent] 加载完成 - size: $size, anchor: $anchor, cellSize: ${gridSystem.cellSize}');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. 绘制棋盘背景
    _drawBackground(canvas);

    // 2. 绘制网格线
    _drawGrid(canvas);

    // 3. 绘制特殊标记
    _drawSpecialMarks(canvas);

    // 4. 绘制上一步移动高亮
    if (lastMove != null) {
      _drawLastMoveHighlight(canvas, lastMove!);
    }

    // 5. 绘制选中高亮
    if (selectedPiece != null) {
      _drawSelectedHighlight(canvas, selectedPiece!);
    }

    // 6. 绘制合法移动提示
    _drawLegalMoveHints(canvas, legalMoves);

    // Debug: 打印子组件信息（每60帧打印一次，避免刷屏）
    if (DateTime.now().millisecondsSinceEpoch % 1000 < 16) {
      print('[BoardSpriteComponent.render] 子组件数: ${children.length}, 棋子数: ${pieces.length}');
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 将点击坐标转换为网格坐标
    final localPos = event.localPosition;
    final gridPos = gridSystem.screenToGrid(localPos.x, localPos.y);

    if (gridPos != null && onTap != null) {
      onTap!(gridPos.x, gridPos.y);
    }
  }

  /// 绘制棋盘背景
  void _drawBackground(Canvas canvas) {
    final paint = Paint()
      ..color = BoardUIConfig.boardBackgroundColor
      ..style = PaintingStyle.fill;

    // 棋盘占满整个组件
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  /// 绘制棋盘网格线
  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = BoardUIConfig.boardBorderColor
      ..strokeWidth = gridSystem.cellSize * BoardUIConfig.gridLineWidth
      ..style = PaintingStyle.stroke;

    // 绘制横线
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      final startPos = gridSystem.gridToScreen(0, y);
      final endPos = gridSystem.gridToScreen(BoardConstants.boardWidth - 1, y);
      canvas.drawLine(startPos, endPos, paint);
    }

    // 绘制竖线
    for (var x = 0; x < BoardConstants.boardWidth; x++) {
      if (x == 0 || x == BoardConstants.boardWidth - 1) {
        // 左右边界线：完整绘制
        final start = gridSystem.gridToScreen(x, 0);
        final end = gridSystem.gridToScreen(x, BoardConstants.boardHeight - 1);
        canvas.drawLine(start, end, paint);
      } else {
        // 中间竖线：楚河处断开
        final topStart = gridSystem.gridToScreen(x, 0);
        final topEnd = gridSystem.gridToScreen(x, 4);
        canvas.drawLine(topStart, topEnd, paint);

        final bottomStart = gridSystem.gridToScreen(x, 5);
        final bottomEnd = gridSystem.gridToScreen(x, 9);
        canvas.drawLine(bottomStart, bottomEnd, paint);
      }
    }

    // 绘制九宫格斜线
    _drawPalaceDiagonals(canvas, paint);
  }

  /// 绘制九宫格斜线
  void _drawPalaceDiagonals(Canvas canvas, Paint paint) {
    // 黑方九宫格斜线
    canvas.drawLine(
      gridSystem.gridToScreen(3, 0),
      gridSystem.gridToScreen(5, 2),
      paint,
    );
    canvas.drawLine(
      gridSystem.gridToScreen(5, 0),
      gridSystem.gridToScreen(3, 2),
      paint,
    );

    // 红方九宫格斜线
    canvas.drawLine(
      gridSystem.gridToScreen(3, 7),
      gridSystem.gridToScreen(5, 9),
      paint,
    );
    canvas.drawLine(
      gridSystem.gridToScreen(5, 7),
      gridSystem.gridToScreen(3, 9),
      paint,
    );
  }

  /// 绘制特殊标记（炮位、兵位）
  void _drawSpecialMarks(Canvas canvas) {
    final paint = Paint()
      ..color = BoardUIConfig.boardBorderColor
      ..strokeWidth = gridSystem.cellSize * BoardUIConfig.markLineWidth
      ..style = PaintingStyle.stroke;

    // 炮位和兵位的标记位置
    final markPositions = [
      (1, 2), (7, 2), // 黑方炮
      (1, 7), (7, 7), // 红方炮
      (0, 3), (2, 3), (4, 3), (6, 3), (8, 3), // 黑方兵
      (0, 6), (2, 6), (4, 6), (6, 6), (8, 6), // 红方兵
    ];

    for (final pos in markPositions) {
      _drawPositionMark(canvas, pos.$1, pos.$2, paint);
    }
  }

  /// 绘制位置标记
  void _drawPositionMark(Canvas canvas, int x, int y, Paint paint) {
    final center = gridSystem.gridToScreen(x, y);
    final markSize = gridSystem.cellSize * 0.13;
    final markOffset = gridSystem.cellSize * 0.19;

    // 四个角的标记
    final corners = [
      [-1, -1],
      [1, -1],
      [-1, 1],
      [1, 1],
    ];

    for (final corner in corners) {
      final cx = center.dx + corner[0] * markOffset;
      final cy = center.dy + corner[1] * markOffset;

      // 横线
      canvas.drawLine(
        Offset(cx - corner[0] * markSize, cy),
        Offset(cx, cy),
        paint,
      );

      // 竖线
      canvas.drawLine(
        Offset(cx, cy - corner[1] * markSize),
        Offset(cx, cy),
        paint,
      );
    }
  }

  /// 绘制上一步移动高亮
  void _drawLastMoveHighlight(Canvas canvas, Move move) {
    final paint = Paint()
      ..color = BoardUIConfig.lastMoveHighlightColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final fromBounds = gridSystem.getCellBounds(move.from.x, move.from.y);
    canvas.drawRect(fromBounds, paint);

    final toBounds = gridSystem.getCellBounds(move.to.x, move.to.y);
    canvas.drawRect(toBounds, paint);
  }

  /// 绘制选中高亮
  void _drawSelectedHighlight(Canvas canvas, Position pos) {
    final paint = Paint()
      ..color = BoardUIConfig.selectedHighlightColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final bounds = gridSystem.getCellBounds(pos.x, pos.y);
    canvas.drawRect(bounds, paint);
  }

  /// 绘制合法移动提示
  void _drawLegalMoveHints(Canvas canvas, List<Move> moves) {
    for (final move in moves) {
      final center = gridSystem.gridToScreen(move.to.x, move.to.y);

      if (move.isCapture) {
        // 吃子：使用红色圆圈（简化版，不区分红黑方）
        final capturePaint = Paint()
          ..color = Colors.red.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = gridSystem.cellSize * BoardUIConfig.captureDotWidth;
        canvas.drawCircle(
          center,
          gridSystem.cellSize * BoardUIConfig.captureDotRadius,
          capturePaint,
        );
      } else {
        // 移动：蓝色实心圆
        final movePaint = Paint()
          ..color = BoardUIConfig.legalMoveHintColor.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          center,
          gridSystem.cellSize * BoardUIConfig.moveDotRadius,
          movePaint,
        );
      }
    }
  }

  /// 添加棋子精灵作为子组件
  void addPieceSprite(String key, Component piece) {
    add(piece);
    pieces[key] = piece;
    print('[BoardSpriteComponent] 添加棋子组件: $key, 当前子组件数: ${children.length}');
  }

  /// 移除棋子精灵
  void removePieceSprite(String key) {
    pieces[key]?.removeFromParent();
    pieces.remove(key);
  }

  /// 清除所有棋子精灵
  void clearAllPieces() {
    for (final piece in pieces.values) {
      piece.removeFromParent();
    }
    pieces.clear();
  }

  /// 添加光圈组件作为子组件
  void addHalo(Component halo) {
    add(halo);
    halos.add(halo);
  }

  /// 清除所有光圈
  void clearAllHalos() {
    for (final halo in halos) {
      halo.removeFromParent();
    }
    halos.clear();
  }
}
