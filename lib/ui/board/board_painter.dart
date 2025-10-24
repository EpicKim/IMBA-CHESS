// 棋盘绘制器
// 功能：绘制棋盘、棋子、高亮、移动提示等

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/board.dart';
import '../../models/piece.dart';
import '../../models/move.dart';
import '../../skills/skill.dart';
import '../../game_provider/game_provider.dart';
import '../../core/constants.dart';
import '../../core/grid_system.dart';

/// 棋盘UI配置常量
class BoardUIConfig {
  // 颜色配置
  static const Color boardBackgroundColor = Color(0xFFE6C9A8); // 棋盘背景色（浅木色）
  static const Color boardBorderColor = Colors.black; // 棋盘边框颜色
  static const Color redPieceColor = Color(0xFFFF6B6B); // 红方棋子颜色
  static const Color blackPieceColor = Color(0xFF2C2C2C); // 黑方棋子颜色
  static const Color skillBadgeColor = Color.fromRGBO(255, 217, 51, 0.9); // 技能徽章颜色

  // 高亮颜色
  static const Color selectedHighlightColor = Colors.green; // 选中棋子的高亮颜色
  static const Color lastMoveHighlightColor = Colors.yellow; // 上一步移动的高亮颜色
  static const Color legalMoveHintColor = Colors.blue; // 合法移动提示颜色

  // 尺寸比例（相对于 cellSize）
  static const double gridLineWidth = 0.032; // 网格线宽度
  static const double markLineWidth = 0.024; // 特殊标记线宽度
  static const double pieceBorderWidth = 0.04; // 棋子边框宽度
  static const double pieceRadius = 0.42; // 棋子半径
  static const double pieceFontSize = 0.40; // 棋子文字大小
  static const double badgeRadius = 0.19; // 技能徽章半径
  static const double badgeFontSize = 0.19; // 技能徽章文字大小
  static const double badgeBorderWidth = 0.03; // 技能徽章边框宽度

  // 移动提示配置
  static const double moveDotRadius = 0.13; // 移动点半径
  static const double captureDotRadius = 0.4; // 吃子圆圈半径
  static const double captureDotWidth = 0.05; // 吃子圆圈线宽
}

/// 棋盘绘制器
/// 使用 CustomPainter 绘制棋盘的所有元素
class BoardPainter extends CustomPainter {
  final Board board; // 棋盘数据
  final GridSystem gridSystem; // 坐标系统
  final Position? selectedPiece; // 选中的棋子位置
  final List<Move> legalMoves; // 合法移动列表
  final Move? lastMove; // 上一步移动
  final TurnPhase? gamePhase; // 游戏阶段
  final Skill? selectedSkill; // 选中的技能
  final Side? currentSide; // 当前行动方
  final Side? localPlayerSide; // 本地玩家阵营（用于判断技能赋予时的可选棋子）
  final double animationTime; // 动画时间（用于脉冲效果）

  BoardPainter({
    required this.board,
    required this.gridSystem,
    this.selectedPiece,
    this.legalMoves = const [],
    this.lastMove,
    this.gamePhase,
    this.selectedSkill,
    this.currentSide,
    this.localPlayerSide,
    this.animationTime = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制棋盘背景（只在棋盘区域内）
    _drawBackground(canvas);

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

    // 6. 绘制棋子
    _drawPieces(canvas);

    // 7. 绘制合法移动提示（在棋子之后绘制，这样红圈不会被棋子覆盖）
    _drawLegalMoveHints(canvas, legalMoves);
  }

  /// 绘制棋盘背景（只在棋盘区域内，确保边距一致）
  void _drawBackground(Canvas canvas) {
    final paint = Paint()
      ..color = BoardUIConfig.boardBackgroundColor
      ..style = PaintingStyle.fill;

    // 计算棋盘实际区域（从第一个格子到最后一个格子）
    final topLeft = gridSystem.gridToScreen(0, 0);
    final bottomRight = gridSystem.gridToScreen(
      BoardConstants.boardWidth - 1,
      BoardConstants.boardHeight - 1,
    );

    canvas.drawRect(
      Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy),
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
        // 左右边界线：完整绘制（y=0 到 y=9）
        final start = gridSystem.gridToScreen(x, 0);
        final end = gridSystem.gridToScreen(x, BoardConstants.boardHeight - 1);
        canvas.drawLine(start, end, paint);
      } else {
        // 中间竖线：楚河处断开
        // 上半部分（黑方区域）：y=0 到 y=4
        final topStart = gridSystem.gridToScreen(x, 0);
        final topEnd = gridSystem.gridToScreen(x, 4);
        canvas.drawLine(topStart, topEnd, paint);

        // 下半部分（红方区域）：y=5 到 y=9
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
    final markSize = gridSystem.cellSize * 0.13; // 标记尺寸
    final markOffset = gridSystem.cellSize * 0.19; // 标记偏移

    // 绘制四个角的标记（左上、右上、左下、右下）
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
    // 只在下棋阶段显示移动提示
    if (gamePhase != TurnPhase.playing) {
      return;
    }

    for (final move in moves) {
      final center = gridSystem.gridToScreen(move.to.x, move.to.y);

      if (move.isCapture) {
        // 吃子：根据当前行动方使用不同颜色
        // 红方吃子用红色，黑方吃子用绿色
        final captureColor = currentSide == Side.red
            ? Colors.red.withOpacity(0.9) // 红方用红色
            : const Color(0xFF00FF00).withOpacity(0.9); // 黑方用绿色

        final capturePaint = Paint()
          ..color = captureColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = gridSystem.cellSize * BoardUIConfig.captureDotWidth;
        canvas.drawCircle(center, gridSystem.cellSize * BoardUIConfig.captureDotRadius, capturePaint);
      } else {
        // 移动：绘制蓝色实心圆
        final movePaint = Paint()
          ..color = BoardUIConfig.legalMoveHintColor.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, gridSystem.cellSize * BoardUIConfig.moveDotRadius, movePaint);
      }
    }
  }

  /// 绘制所有棋子
  void _drawPieces(Canvas canvas) {
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null) {
          // 检查是否在技能赋予阶段需要绘制蓝色光圈提示
          // 只有在selectPiece阶段（已选择技能卡，正在选择棋子）且是本地玩家的棋子时才显示
          if (gamePhase == TurnPhase.selectPiece && selectedSkill != null && localPlayerSide != null && piece.side == localPlayerSide && !piece.hasSkill(selectedSkill!.typeId)) {
            // 绘制蓝色光圈提示该棋子可以被赋予技能
            _drawSkillApplicableHalo(canvas, x, y);
          }

          _drawPiece(canvas, piece, x, y);
        }
      }
    }
  }

  /// 绘制可赋予技能的蓝色光圈（多层光晕效果）
  void _drawSkillApplicableHalo(Canvas canvas, int x, int y) {
    final center = gridSystem.gridToScreen(x, y);
    final radius = gridSystem.cellSize * 0.45; // 基础半径

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
      ..strokeWidth = gridSystem.cellSize * 0.065
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.26, paint3);

    // 中环亮蓝色
    final paint4 = Paint()
      ..color = const Color.fromRGBO(128, 204, 255, 0.75)
      ..strokeWidth = gridSystem.cellSize * 0.04
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.12, paint4);

    // 内环最亮蓝色
    final paint5 = Paint()
      ..color = const Color.fromRGBO(153, 217, 255, 0.85)
      ..strokeWidth = gridSystem.cellSize * 0.025
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 1.03, paint5);
  }

  /// 绘制单个棋子
  void _drawPiece(Canvas canvas, Piece piece, int x, int y) {
    final center = gridSystem.gridToScreen(x, y);
    final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;

    // 绘制棋子底色
    final bgPaint = Paint()
      ..color = piece.side == Side.red ? BoardUIConfig.redPieceColor : BoardUIConfig.blackPieceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // 绘制棋子边框
    final borderPaint = Paint()
      ..color = BoardUIConfig.boardBorderColor
      ..strokeWidth = gridSystem.cellSize * BoardUIConfig.pieceBorderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);

    // 绘制棋子文字
    _drawPieceText(canvas, piece.label, center);

    // 绘制额外技能徽章
    _drawSkillBadges(canvas, piece, center, radius);
  }

  /// 绘制棋子文字
  void _drawPieceText(Canvas canvas, String? label, Offset center) {
    if (label == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
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
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  /// 绘制技能徽章
  void _drawSkillBadges(Canvas canvas, Piece piece, Offset center, double pieceRadius) {
    // 获取额外技能（跳过主技能，绘制其他技能）
    final extraSkills = piece.skillsList.length > 1 ? piece.skillsList.sublist(1) : <Skill>[];

    for (var i = 0; i < extraSkills.length; i++) {
      final skill = extraSkills[i];
      // 计算徽章角度，分散在棋子周围
      final angle = (i * math.pi / (extraSkills.length + 0.5)) - math.pi / 4;
      final badgePos = Offset(
        center.dx + math.cos(angle) * (pieceRadius * 0.75),
        center.dy + math.sin(angle) * (pieceRadius * 0.75),
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

      // 绘制徽章文字（技能名称，根据棋子阵营显示）
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

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.selectedPiece != selectedPiece ||
        oldDelegate.legalMoves != legalMoves ||
        oldDelegate.lastMove != lastMove ||
        oldDelegate.gamePhase != gamePhase ||
        oldDelegate.selectedSkill != selectedSkill ||
        oldDelegate.currentSide != currentSide ||
        oldDelegate.localPlayerSide != localPlayerSide ||
        (oldDelegate.animationTime - animationTime).abs() > 0.01;
  }
}
