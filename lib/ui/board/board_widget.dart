// 棋盘交互组件
// 功能：结合棋盘绘制和用户交互

import 'package:flutter/material.dart';
import '../../models/board.dart';
import '../../models/move.dart';
import '../../models/skill.dart';
import '../../models/game_phase.dart';
import '../../core/grid_system.dart';
import '../../core/constants.dart';
import 'board_painter.dart';

/// 棋盘Widget配置常量
class BoardWidgetConfig {
  static const double boardPadding = 40.0; // 棋盘内边距
  static const double boardSizeRatio = 0.85; // 棋盘占可用空间的比例
}

/// 棋盘交互组件
/// 结合棋盘绘制和用户交互
class BoardWidget extends StatefulWidget {
  final Board board; // 棋盘数据
  final Position? selectedPiece; // 选中的棋子位置
  final List<Move> legalMoves; // 合法移动列表
  final Move? lastMove; // 上一步移动
  final Side? localPlayerSide; // 本地玩家阵营
  final void Function(int x, int y)? onTap; // 点击回调
  final GamePhase? gamePhase; // 游戏阶段
  final Skill? selectedSkill; // 选中的技能
  final Side? currentSide; // 当前行动方

  const BoardWidget({
    super.key,
    required this.board,
    this.selectedPiece,
    this.legalMoves = const [],
    this.lastMove,
    this.localPlayerSide,
    this.onTap,
    this.gamePhase,
    this.selectedSkill,
    this.currentSide,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late GridSystem gridSystem; // 坐标系统
  late AnimationController _animationController; // 动画控制器（用于脉冲效果）

  @override
  void initState() {
    super.initState();
    _initGridSystem();
    // 初始化动画控制器（循环动画）
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果本地玩家阵营改变，重新初始化坐标系统
    if (oldWidget.localPlayerSide != widget.localPlayerSide) {
      _initGridSystem();
    }
  }

  /// 初始化坐标系统
  void _initGridSystem() {
    gridSystem = GridSystem(
      boardOffset: const Offset(
          BoardWidgetConfig.boardPadding, BoardWidgetConfig.boardPadding),
      cellSize: 60.0, // 默认值，实际会在 build 中动态计算
    );
    if (widget.localPlayerSide != null) {
      gridSystem.setLocalPlayerSide(widget.localPlayerSide!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间计算棋盘尺寸
        final cellSize = _calculateCellSize(constraints);
        final boardSize = _calculateBoardSize(cellSize);
        _updateGridSystem(cellSize);
        return _buildBoardContainer(boardSize);
      },
    );
  }

  /// 计算格子大小（基于可用空间）
  double _calculateCellSize(BoxConstraints constraints) {
    final cellSizeByWidth =
        (constraints.maxWidth * BoardWidgetConfig.boardSizeRatio) /
            BoardConstants.boardWidth;
    final cellSizeByHeight =
        (constraints.maxHeight * BoardWidgetConfig.boardSizeRatio) /
            BoardConstants.boardHeight;
    return cellSizeByWidth < cellSizeByHeight
        ? cellSizeByWidth
        : cellSizeByHeight;
  }

  /// 计算棋盘实际尺寸（格子大小 × 格子数量 + 内边距）
  Size _calculateBoardSize(double cellSize) {
    final width = BoardConstants.boardWidth * cellSize +
        BoardWidgetConfig.boardPadding * 2;
    final height = BoardConstants.boardHeight * cellSize +
        BoardWidgetConfig.boardPadding * 2;
    return Size(width, height);
  }

  /// 更新坐标系统（boardOffset 只是棋盘内部边距）
  void _updateGridSystem(double cellSize) {
    gridSystem = GridSystem(
      boardOffset: const Offset(
          BoardWidgetConfig.boardPadding, BoardWidgetConfig.boardPadding),
      cellSize: cellSize,
    );
    if (widget.localPlayerSide != null) {
      gridSystem.setLocalPlayerSide(widget.localPlayerSide!);
    }
  }

  /// 构建棋盘容器（返回固定尺寸的棋盘，让外层 Center 来居中）
  Widget _buildBoardContainer(Size boardSize) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => CustomPaint(
          size: boardSize,
          painter: BoardPainter(
            board: widget.board,
            gridSystem: gridSystem,
            selectedPiece: widget.selectedPiece,
            legalMoves: widget.legalMoves,
            lastMove: widget.lastMove,
            gamePhase: widget.gamePhase,
            selectedSkill: widget.selectedSkill,
            currentSide: widget.currentSide,
            animationTime: _animationController.value * 2 * 3.14159, // 转换为弧度
          ),
        ),
      ),
    );
  }

  /// 处理点击事件
  void _handleTapDown(TapDownDetails details) {
    // 将屏幕坐标转换为网格坐标
    final gridPos = gridSystem.screenToGrid(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    if (gridPos != null && widget.onTap != null) {
      widget.onTap!(gridPos.x, gridPos.y);
    }
  }
}
