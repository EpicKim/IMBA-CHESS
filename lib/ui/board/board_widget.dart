// 棋盘交互组件
// 参考源文件: src/areas/BoardArea.lua
// 功能：结合棋盘绘制和用户交互

import 'package:flutter/material.dart';
import '../../models/board.dart';
import '../../models/move.dart';
import '../../models/skill.dart';
import '../../models/game_phase.dart';
import '../../core/grid_system.dart';
import '../../core/constants.dart';
import 'board_painter.dart';

/// 棋盘交互组件
///
/// 将棋盘绘制和用户交互结合在一起
class BoardWidget extends StatefulWidget {
  /// 棋盘数据
  final Board board;

  /// 选中的棋子位置
  final Position? selectedPiece;

  /// 合法移动列表
  final List<Move> legalMoves;

  /// 上一步移动
  final Move? lastMove;

  /// 本地玩家阵营
  final Side? localPlayerSide;

  /// 点击回调
  final void Function(int x, int y)? onTap;

  /// 游戏阶段
  final GamePhase? gamePhase;

  /// 选中的技能
  final Skill? selectedSkill;

  /// 当前行动方
  final Side? currentSide;

  /// 构造函数
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

class _BoardWidgetState extends State<BoardWidget> with SingleTickerProviderStateMixin {
  /// 坐标系统
  late GridSystem gridSystem;

  /// 动画控制器（用于脉冲效果）
  late AnimationController _animationController;

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
    // 使用 LayoutBuilder 获取实际尺寸后初始化
    // 这里先使用默认值，实际会在 build 中动态计算
    gridSystem = GridSystem(
      boardOffset: const Offset(40, 40),
      cellSize: 60.0,
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
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // 计算合适的格子大小
        final cellSizeByWidth = (availableWidth - 80) / BoardConstants.boardWidth;
        final cellSizeByHeight = (availableHeight - 80) / BoardConstants.boardHeight;
        final cellSize = cellSizeByWidth < cellSizeByHeight ? cellSizeByWidth : cellSizeByHeight;

        // 计算棋盘偏移量（居中）
        final boardWidth = BoardConstants.boardWidth * cellSize;
        final boardHeight = BoardConstants.boardHeight * cellSize;
        final offsetX = (availableWidth - boardWidth) / 2;
        final offsetY = (availableHeight - boardHeight) / 2;

        // 更新坐标系统
        gridSystem = GridSystem(
          boardOffset: Offset(offsetX, offsetY),
          cellSize: cellSize,
        );

        if (widget.localPlayerSide != null) {
          gridSystem.setLocalPlayerSide(widget.localPlayerSide!);
        }

        return GestureDetector(
          onTapDown: _handleTapDown,
          child: Container(
            width: availableWidth,
            height: availableHeight,
            color: const Color(0xFF8B7355), // 边框颜色（深木色）
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(availableWidth, availableHeight),
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
                  );
                },
              ),
            ),
          ),
        );
      },
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
      // 调用回调函数
      widget.onTap!(gridPos.x, gridPos.y);
    }
  }
}
