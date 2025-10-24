// 棋盘绘制器
// 参考源文件: src/areas/BoardArea.lua
// 功能：绘制棋盘、棋子、高亮、移动提示等

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/board.dart';
import '../../models/piece.dart';
import '../../models/move.dart';
import '../../models/skill.dart';
import '../../models/game_phase.dart';
import '../../core/constants.dart';
import '../../core/grid_system.dart';

/// 棋盘绘制器
///
/// 使用 CustomPainter 绘制棋盘的所有元素
class BoardPainter extends CustomPainter {
  /// 棋盘数据
  final Board board;

  /// 坐标系统
  final GridSystem gridSystem;

  /// 选中的棋子位置
  final Position? selectedPiece;

  /// 合法移动列表
  final List<Move> legalMoves;

  /// 上一步移动
  final Move? lastMove;

  /// 游戏阶段
  final GamePhase? gamePhase;

  /// 选中的技能
  final Skill? selectedSkill;

  /// 当前行动方
  final Side? currentSide;

  /// 动画时间（用于脉冲效果）
  final double animationTime;

  /// 构造函数
  BoardPainter({
    required this.board,
    required this.gridSystem,
    this.selectedPiece,
    this.legalMoves = const [],
    this.lastMove,
    this.gamePhase,
    this.selectedSkill,
    this.currentSide,
    this.animationTime = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制棋盘背景
    _drawBackground(canvas, size);

    // 2. 绘制棋盘网格线
    _drawGrid(canvas);

    // 3. 绘制特殊标记（九宫格、炮位、兵位）
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

    // 7. 绘制棋子
    _drawPieces(canvas);
  }

  /// 绘制棋盘背景
  void _drawBackground(Canvas canvas, Size size) {
    // 棋盘背景色（浅木色）
    final paint = Paint()
      ..color = const Color(0xFFE6C9A8)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  /// 绘制棋盘网格线
  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 绘制横线
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      final startPos = gridSystem.gridToScreen(0, y);
      final endPos = gridSystem.gridToScreen(BoardConstants.boardWidth - 1, y);

      canvas.drawLine(startPos, endPos, paint);
    }

    // 绘制竖线
    for (var x = 0; x < BoardConstants.boardWidth; x++) {
      // 上半部分（黑方区域）：y=0 到 y=4
      final topStart = gridSystem.gridToScreen(x, 0);
      final topEnd = gridSystem.gridToScreen(x, 4);
      canvas.drawLine(topStart, topEnd, paint);

      // 下半部分（红方区域）：y=5 到 y=9
      final bottomStart = gridSystem.gridToScreen(x, 5);
      final bottomEnd = gridSystem.gridToScreen(x, 9);
      canvas.drawLine(bottomStart, bottomEnd, paint);
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
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 炮位和兵位的标记位置
    final markPositions = [
      // 炮位
      (1, 2), (7, 2), // 黑方炮
      (1, 7), (7, 7), // 红方炮
      // 兵位
      (0, 3), (2, 3), (4, 3), (6, 3), (8, 3), // 黑方兵
      (0, 6), (2, 6), (4, 6), (6, 6), (8, 6), // 红方兵
    ];

    for (final pos in markPositions) {
      _drawPositionMark(canvas, pos.$1, pos.$2, paint);
    }
  }

  /// 绘制位置标记（小角标）
  void _drawPositionMark(Canvas canvas, int x, int y, Paint paint) {
    final center = gridSystem.gridToScreen(x, y);
    const markSize = 8.0;
    const markOffset = 12.0;

    // 绘制四个角的标记
    final corners = [
      [-1, -1], [1, -1], [-1, 1], [1, 1], // 左上、右上、左下、右下
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
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // 高亮起始位置
    final fromBounds = gridSystem.getCellBounds(move.from.x, move.from.y);
    canvas.drawRect(fromBounds, paint);

    // 高亮目标位置
    final toBounds = gridSystem.getCellBounds(move.to.x, move.to.y);
    canvas.drawRect(toBounds, paint);
  }

  /// 绘制选中高亮
  void _drawSelectedHighlight(Canvas canvas, Position pos) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final bounds = gridSystem.getCellBounds(pos.x, pos.y);
    canvas.drawRect(bounds, paint);
  }

  /// 绘制合法移动提示
  void _drawLegalMoveHints(Canvas canvas, List<Move> moves) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (final move in moves) {
      final center = gridSystem.gridToScreen(move.to.x, move.to.y);

      // 如果是吃子，绘制大圆圈；否则绘制小圆点
      final radius = move.isCapture ? 25.0 : 8.0;

      if (move.isCapture) {
        // 吃子：绘制空心圆
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 3.0;
      } else {
        // 移动：绘制实心圆
        paint.style = PaintingStyle.fill;
      }

      canvas.drawCircle(center, radius, paint);
    }
  }

  /// 绘制所有棋子
  void _drawPieces(Canvas canvas) {
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null) {
          // 检查是否在技能赋予阶段需要绘制蓝色光圈提示
          if (gamePhase == GamePhase.selectPiece && selectedSkill != null && currentSide != null && piece.side == currentSide && !piece.hasSkill(selectedSkill!.typeId)) {
            // 绘制蓝色脉冲光圈（参考Lua: 多层蓝色光晕效果）
            _drawSkillApplicableHalo(canvas, x, y);
          }

          _drawPiece(canvas, piece, x, y);
        }
      }
    }
  }

  /// 绘制可赋予技能的蓝色光圈（固定不闪烁）
  void _drawSkillApplicableHalo(Canvas canvas, int x, int y) {
    final center = gridSystem.gridToScreen(x, y);
    const radius = 28.0; // 基础半径

    // 最外层蓝色光晕
    final paint1 = Paint()
      ..color = const Color.fromRGBO(76, 153, 255, 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.4, paint1);

    // 外层蓝色光晕
    final paint2 = Paint()
      ..color = const Color.fromRGBO(89, 165, 255, 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.3, paint2);

    // 外环蓝色
    final paint3 = Paint()
      ..color = const Color.fromRGBO(102, 178, 255, 0.65)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.26, paint3);

    // 中环亮蓝色
    final paint4 = Paint()
      ..color = const Color.fromRGBO(128, 204, 255, 0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.12, paint4);

    // 内环最亮蓝色
    final paint5 = Paint()
      ..color = const Color.fromRGBO(153, 217, 255, 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.03, paint5);
  }

  /// 绘制单个棋子
  void _drawPiece(Canvas canvas, Piece piece, int x, int y) {
    final center = gridSystem.gridToScreen(x, y);
    const radius = 22.0;

    // 绘制棋子底色
    final bgPaint = Paint()
      ..color = piece.side == Side.red ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // 绘制棋子边框
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);

    // 绘制棋子文字
    final textSpan = TextSpan(
      text: piece.label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'DingLieZhuHai',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 居中绘制文字
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // 绘制额外技能徽章（参考Lua: 跳过主技能，绘制其他技能）
    final extraSkills = piece.skillsList.length > 1 ? piece.skillsList.sublist(1) : <Skill>[];

    for (var i = 0; i < extraSkills.length; i++) {
      final skill = extraSkills[i];
      // 计算徽章角度（参考Lua: 分散在棋子周围）
      final angle = (i * math.pi / (extraSkills.length + 0.5)) - math.pi / 4;
      final badgeX = center.dx + math.cos(angle) * (radius * 0.75);
      final badgeY = center.dy + math.sin(angle) * (radius * 0.75);

      // 绘制徽章底色（金黄色）
      final badgePaint = Paint()
        ..color = const Color.fromRGBO(255, 217, 51, 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(badgeX, badgeY), 10, badgePaint);

      // 绘制徽章边框
      final badgeBorderPaint = Paint()
        ..color = const Color.fromRGBO(76, 51, 25, 1.0)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(badgeX, badgeY), 10, badgeBorderPaint);

      // 绘制徽章文字（技能名称）
      final badgeTextSpan = TextSpan(
        text: skill.name,
        style: const TextStyle(
          color: Color.fromRGBO(51, 25, 0, 1.0),
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'DingLieZhuHai',
        ),
      );

      final badgeTextPainter = TextPainter(
        text: badgeTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      badgeTextPainter.layout();

      // 居中绘制徽章文字
      badgeTextPainter.paint(
        canvas,
        Offset(
          badgeX - badgeTextPainter.width / 2,
          badgeY - badgeTextPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.selectedPiece != selectedPiece ||
        oldDelegate.legalMoves != legalMoves ||
        oldDelegate.lastMove != lastMove ||
        oldDelegate.gamePhase != gamePhase ||
        oldDelegate.selectedSkill != selectedSkill ||
        oldDelegate.currentSide != currentSide ||
        (oldDelegate.animationTime - animationTime).abs() > 0.01;
  }
}
