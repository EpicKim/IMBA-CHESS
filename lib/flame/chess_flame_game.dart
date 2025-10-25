// Flame游戏主类
// 功能：管理所有精灵组件，接收Provider状态更新

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Offset, Color;
import '../game_provider/game_provider.dart';
import '../game_provider/game_state.dart';
import '../models/board.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../core/grid_system.dart';
import '../core/constants.dart';
import '../skills/skill_types.dart';
import '../skills/skill.dart';
import '../ui/board/board_painter.dart'; // 导入BoardUIConfig
import 'components/board_sprite_component.dart';
import 'components/piece_sprite_component.dart';
import 'components/moving_sprite_component.dart';
import 'components/skill_applicable_halo_component.dart';
import 'sprite_cache.dart';
import 'audio_manager.dart';

/// Flame游戏主类
/// 管理所有精灵组件，处理状态同步和动画
class ChessFlameGame extends FlameGame {
  // 游戏Provider（由外部注入）
  GameProvider? provider;

  // 坐标系统（立即初始化，避免 LateInitializationError）
  GridSystem gridSystem = GridSystem(
    boardOffset: const Offset(40, 40),
    cellSize: 60.0,
  );

  // 精灵缓存
  final spriteCache = SpriteCache();

  // 棋盘精灵
  BoardSpriteComponent? boardSprite;

  // 是否正在执行移动动画
  bool _isAnimating = false;

  // 上一次同步的游戏状态
  Board? _lastBoard;
  Move? _lastMove;
  TurnPhase? _lastPhase;
  Skill? _lastSelectedSkill;
  Side? _lastLocalPlayerSide;

  /// 构造函数
  ChessFlameGame() : super();

  // @override
  // Color backgroundColor() => const Color(0xFFF5F5DC); // 设置游戏背景色为米色

  @override
  Color backgroundColor() => const Color.fromARGB(255, 255, 255, 255);

  @override
  Future<void> onLoad() async {
    // 预加载精灵资源
    await spriteCache.preload();

    // 预加载音效资源
    await AudioManager.preload();

    // 初始化棋盘精灵
    await _initBoardSprite();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    print('[ChessFlameGame] onGameResize: $size');

    // 计算cellSize（与原逻辑一致：85%空间+40px边距）
    final availableWidth = size.x * 0.85;
    final availableHeight = size.y * 0.85;
    final cellSizeByWidth = availableWidth / BoardConstants.boardWidth;
    final cellSizeByHeight = availableHeight / BoardConstants.boardHeight;
    final cellSize = cellSizeByWidth < cellSizeByHeight ? cellSizeByWidth : cellSizeByHeight;

    print('[ChessFlameGame] 计算得到cellSize: $cellSize');

    // 更新GridSystem的cellSize（不重新创建对象）
    gridSystem.cellSize = cellSize;

    // gridSystem.boardOffset 保持固定为(40, 40)，这是组件内部的边距
    // 不需要修改，因为它只用于组件内部的坐标转换

    // 如果有本地玩家阵营，应用翻转
    if (provider != null) {
      gridSystem.setLocalPlayerSide(provider!.localPlayerSide);
    }

    // 计算棋盘组件的尺寸（纯网格尺寸，无额外边距）
    final boardWidth = BoardConstants.boardWidth * cellSize;
    final boardHeight = BoardConstants.boardHeight * cellSize;

    // 计算棋盘组件在Flame世界中的居中位置
    final boardOffsetX = (size.x - boardWidth) / 2;
    final boardOffsetY = (size.y - boardHeight) / 2;

    print('[ChessFlameGame] 棋盘尺寸: ($boardWidth, $boardHeight), 居中位置: ($boardOffsetX, $boardOffsetY)');

    // 更新棋盘精灵位置和尺寸
    if (boardSprite != null) {
      boardSprite!.position = Vector2(boardOffsetX, boardOffsetY);
      boardSprite!.size = Vector2(boardWidth, boardHeight);

      // 重要：需要通知所有棋子更新它们的位置
      _syncPiecesPosition();

      print('[ChessFlameGame] 已更新BoardSprite position: ${boardSprite!.position}, size: ${boardSprite!.size}');
    }
  }

  /// 初始化棋盘精灵
  Future<void> _initBoardSprite() async {
    boardSprite = BoardSpriteComponent(
      board: Board.initial(),
      gridSystem: gridSystem,
      onTap: (x, y) {
        // 转发点击事件给Provider
        if (provider != null) {
          provider!.handleBoardTap(x, y);
        }
      },
    );
    add(boardSprite!);

    // 初始化棋子（使用初始棋盘状态）
    _syncPieces(Board.initial());
  }

  /// 从Provider同步状态
  void syncFromProvider(GameState gameState, UIState uiState) {
    // 更新本地玩家阵营（可能影响坐标翻转）
    if (provider != null && _lastLocalPlayerSide != provider!.localPlayerSide) {
      gridSystem.setLocalPlayerSide(provider!.localPlayerSide);
      _lastLocalPlayerSide = provider!.localPlayerSide;
    }

    // 更新棋盘精灵的数据
    if (boardSprite != null) {
      boardSprite!.board = gameState.board;
      boardSprite!.selectedPiece = uiState.selectedPiece;
      boardSprite!.legalMoves = provider?.getSelectedPieceLegalMoves() ?? [];
      boardSprite!.lastMove = gameState.history.lastOrNull;
    }

    // 检查是否需要执行移动动画
    if (_lastMove != gameState.history.lastOrNull && gameState.history.isNotEmpty && !_isAnimating) {
      final latestMove = gameState.history.last;
      _executeMove(latestMove, gameState.board);
      _lastMove = latestMove;
    }

    // 检查是否需要更新蓝色光圈
    if (_lastPhase != uiState.phase || _lastSelectedSkill != uiState.selectedSkill) {
      _updateHalos(gameState, uiState);
      _lastPhase = uiState.phase;
      _lastSelectedSkill = uiState.selectedSkill;
    }

    // 检查是否需要更新棋子精灵
    if (_lastBoard != gameState.board) {
      _syncPieces(gameState.board);
      _lastBoard = gameState.board;
    }
  }

  /// 同步棋子精灵（通过BoardSprite管理）
  void _syncPieces(Board board) {
    if (boardSprite == null) {
      print('[ChessFlameGame] ⚠️ boardSprite为null，无法同步棋子');
      return;
    }

    // 收集当前棋盘上的棋子
    final currentPieces = <String, Piece>{};
    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);
        if (piece != null) {
          currentPieces['$x,$y'] = piece;
        }
      }
    }

    print('[ChessFlameGame] 同步棋子: ${currentPieces.length}个棋子');

    // 移除不存在的棋子精灵
    final toRemove = <String>[];
    boardSprite!.pieces.forEach((key, sprite) {
      if (!currentPieces.containsKey(key)) {
        toRemove.add(key);
      }
    });
    for (final key in toRemove) {
      boardSprite!.removePieceSprite(key);
    }

    // 添加新棋子精灵或更新现有精灵
    currentPieces.forEach((key, piece) {
      final coords = key.split(',');
      final x = int.parse(coords[0]);
      final y = int.parse(coords[1]);

      if (!boardSprite!.pieces.containsKey(key)) {
        // 新增棋子（作为boardSprite的子组件）
        final sprite = PieceSpriteComponent(
          piece: piece,
          gridX: x,
          gridY: y,
          gridSystem: gridSystem,
          spriteCache: spriteCache,
        );
        boardSprite!.addPieceSprite(key, sprite);
        print('[ChessFlameGame] 添加棋子: $key (${piece.label})');
      } else {
        // 更新现有棋子的数据（可能技能改变）
        // 简化处理：移除旧精灵，添加新精灵
        boardSprite!.removePieceSprite(key);
        final sprite = PieceSpriteComponent(
          piece: piece,
          gridX: x,
          gridY: y,
          gridSystem: gridSystem,
          spriteCache: spriteCache,
        );
        boardSprite!.addPieceSprite(key, sprite);
      }
    });

    print('[ChessFlameGame] 棋子同步完成，当前棋子数: ${boardSprite!.pieces.length}');
  }

  /// 同步所有棋子的位置（当cellSize变化时调用）
  void _syncPiecesPosition() {
    if (boardSprite == null) return;

    print('[ChessFlameGame] 同步棋子位置... cellSize=${gridSystem.cellSize}, boardOffset=${gridSystem.boardOffset}');
    print('[ChessFlameGame] BoardSprite position=${boardSprite!.position}, size=${boardSprite!.size}, anchor=${boardSprite!.anchor}');

    var count = 0;
    // 更新所有现有棋子的位置
    boardSprite!.pieces.forEach((key, component) {
      if (component is PieceSpriteComponent) {
        // 使用相对于父组件的坐标
        final componentPos = gridSystem.gridToComponentCoord(component.gridX, component.gridY);
        component.position = Vector2(componentPos.dx, componentPos.dy);
        final radius = gridSystem.cellSize * BoardUIConfig.pieceRadius;
        component.size = Vector2(radius * 2, radius * 2);
        count++;

        // 特别关注 (0,0) 位置的黑车
        if (component.gridX == 0 && component.gridY == 0) {
          print('[ChessFlameGame] ⭐ 黑车(0,0): componentPos=$componentPos, position=${component.position}, size=${component.size}, anchor=${component.anchor}');
        }

        // 打印前5个棋子的位置
        if (count <= 5) {
          print('[ChessFlameGame] 更新棋子 grid(${component.gridX},${component.gridY}) -> componentPos($componentPos) -> position(${component.position})');
        }
      }
    });

    print('[ChessFlameGame] 棋子位置同步完成，共更新 $count 个棋子');
  }

  /// 执行移动动画
  Future<void> _executeMove(Move move, Board board) async {
    _isAnimating = true;

    // 获取移动的棋子
    final movingPiece = board.get(move.to.x, move.to.y); // 注意：已经移动后的棋盘
    if (movingPiece == null) {
      _isAnimating = false;
      return;
    }

    // 播放音效
    if (movingPiece.hasSkill(SkillType.rook)) {
      AudioManager.playRook();
    } else if (movingPiece.hasSkill(SkillType.cannon)) {
      AudioManager.playCannon();
    }

    // 隐藏目标位置的棋子精灵
    final targetKey = '${move.to.x},${move.to.y}';
    if (boardSprite != null && boardSprite!.pieces.containsKey(targetKey)) {
      final targetPiece = boardSprite!.pieces[targetKey];
      if (targetPiece is PieceSpriteComponent) {
        targetPiece.opacity = 0;
      }
    }

    // 创建移动精灵（作为boardSprite的子组件）
    final movingSprite = MovingSpriteComponent(
      piece: movingPiece,
      gridX: move.from.x,
      gridY: move.from.y,
      targetX: move.to.x,
      targetY: move.to.y,
      gridSystem: gridSystem,
      spriteCache: spriteCache,
      onMoveComplete: () async {
        // 移动完成后，处理吃子动画
        if (move.isCapture) {
          await _handleCaptureAnimation(move, movingPiece);
        }

        // 恢复目标位置棋子的可见性
        if (boardSprite != null && boardSprite!.pieces.containsKey(targetKey)) {
          final targetPiece = boardSprite!.pieces[targetKey];
          if (targetPiece is PieceSpriteComponent) {
            targetPiece.opacity = 1.0;
          }
        }

        _isAnimating = false;
      },
    );

    boardSprite?.add(movingSprite);
  }

  /// 处理吃子动画
  Future<void> _handleCaptureAnimation(Move move, Piece movingPiece) async {
    // 注意：这里需要从历史记录中获取被吃的棋子
    // 简化处理：创建一个占位动画

    if (movingPiece.hasSkill(SkillType.rook)) {
      // Rook吃子：熔化动画
      // 由于被吃棋子已经从棋盘移除，我们需要从capturedPieceId恢复
      // 简化处理：这里不实现完整动画，只做延迟
      await Future.delayed(const Duration(milliseconds: 300));
    } else if (movingPiece.hasSkill(SkillType.cannon)) {
      // Cannon吃子：撞飞动画
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// 更新蓝色光圈（通过BoardSprite管理）
  void _updateHalos(GameState gameState, UIState uiState) {
    if (boardSprite == null) return;

    // 移除所有旧光圈
    boardSprite!.clearAllHalos();

    // 如果在selectPiece阶段且选中了技能，显示光圈
    if (uiState.phase == TurnPhase.selectPiece && uiState.selectedSkill != null && provider != null) {
      final localPlayerSide = provider!.localPlayerSide;

      for (var y = 0; y < BoardConstants.boardHeight; y++) {
        for (var x = 0; x < BoardConstants.boardWidth; x++) {
          final piece = gameState.board.get(x, y);

          // 检查是否是本地玩家的棋子且未拥有该技能
          if (piece != null && piece.side == localPlayerSide && !piece.hasSkill(uiState.selectedSkill!.typeId)) {
            final halo = SkillApplicableHaloComponent(
              gridSystem: gridSystem,
              gridX: x,
              gridY: y,
            );
            boardSprite!.addHalo(halo);
          }
        }
      }
    }
  }

  @override
  void onRemove() {
    // 清理资源
    spriteCache.clear();
    super.onRemove();
  }
}
