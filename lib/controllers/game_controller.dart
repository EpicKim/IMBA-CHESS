// 游戏控制器
// 参考源文件: src/stages/StageManager.lua, main.lua
// 功能：统一管理游戏流程、玩家交互、状态转换

import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/game_phase.dart';
import '../players/player.dart';
import '../models/move.dart';
import '../models/skill.dart';
import '../models/piece.dart';
import '../core/constants.dart';
import '../core/move_generator.dart';
import '../skills/skill_types.dart';

/// 游戏控制器
///
/// 管理整个游戏的流程和状态
class GameController extends ChangeNotifier {
  /// 游戏状态
  GameState _gameState;

  /// UI状态
  UIState _uiState;

  /// 红方玩家
  Player? _redPlayer;

  /// 黑方玩家
  Player? _blackPlayer;

  /// 是否正在执行AI回合
  bool _isAIThinking = false;

  /// 上次触发技能选择的回合数（用于判断是否需要触发技能选择）
  int _lastSkillSelectionFullmove = -1;

  /// 是否已完成初始技能选择（红方、黑方）
  final Map<Side, bool> _initialSkillSelected = {
    Side.red: false,
    Side.black: false,
  };

  /// 构造函数
  GameController()
      : _gameState = GameState.initial(),
        _uiState = const UIState() {
    // 开局时立即触发技能选择（在setPlayers后会自动调用）
    Future.microtask(() => _checkAndStartSkillSelection());
  }

  /// 获取游戏状态
  GameState get gameState => _gameState;

  /// 获取UI状态
  UIState get uiState => _uiState;

  /// 获取当前玩家
  Player? get currentPlayer {
    return _gameState.sideToMove == Side.red ? _redPlayer : _blackPlayer;
  }

  /// 是否正在AI思考
  bool get isAIThinking => _isAIThinking;

  /// 设置玩家
  void setPlayers(Player redPlayer, Player blackPlayer) {
    _redPlayer = redPlayer;
    _blackPlayer = blackPlayer;
    notifyListeners();

    // 开局时，如果当前玩家是MePlayer，触发技能选择
    _checkAndStartSkillSelection();
  }

  /// 开始新游戏
  void startNewGame() {
    _gameState = GameState.initial();
    _uiState = const UIState();
    _lastSkillSelectionFullmove = -1;
    _initialSkillSelected[Side.red] = false;
    _initialSkillSelected[Side.black] = false;
    notifyListeners();

    // 开局时，触发技能选择（从红方开始）
    _checkAndStartSkillSelection();
  }

  /// 处理棋盘点击
  ///
  /// 参数:
  /// - x, y: 点击的网格坐标
  void handleBoardTap(int x, int y) {
    // 如果正在AI思考，忽略点击
    if (_isAIThinking) {
      return;
    }

    // 如果当前玩家不是本地玩家，忽略点击
    if (currentPlayer?.isMe != true) {
      return;
    }

    // 根据当前阶段处理点击
    switch (_uiState.phase) {
      case GamePhase.play:
        _handlePlayPhaseTap(x, y);
        break;

      case GamePhase.selectPiece:
        _handleSelectPiecePhaseTap(x, y);
        break;

      case GamePhase.selectSkill:
        // 技能选择阶段不处理棋盘点击
        break;

      case GamePhase.gameOver:
        // 游戏结束阶段不处理点击
        break;
    }
  }

  /// 处理正常对局阶段的点击
  void _handlePlayPhaseTap(int x, int y) {
    final piece = _gameState.board.get(x, y);

    // 如果已经选中了棋子
    if (_uiState.selectedPiece != null) {
      final selectedPos = _uiState.selectedPiece!;

      // 检查是否点击了合法移动目标
      final legalMoves = MoveGenerator.getLegalMoves(
        _gameState,
        selectedPos.x,
        selectedPos.y,
      );

      final targetMove = legalMoves.where((m) => m.to.x == x && m.to.y == y).firstOrNull;

      if (targetMove != null) {
        // 执行移动
        _executeMove(targetMove);
        return;
      }

      // 如果点击了己方其他棋子，切换选中
      if (piece != null && piece.side == _gameState.sideToMove) {
        _selectPiece(x, y);
        return;
      }

      // 否则取消选中
      _deselectPiece();
    } else {
      // 未选中棋子，尝试选中点击的棋子
      if (piece != null && piece.side == _gameState.sideToMove) {
        _selectPiece(x, y);
      }
    }
  }

  /// 处理棋子选择阶段的点击
  void _handleSelectPiecePhaseTap(int x, int y) {
    // 调用技能赋予逻辑
    _applySkillToPiece(x, y);
  }

  /// 选中棋子
  void _selectPiece(int x, int y) {
    _uiState = _uiState.copyWith(
      selectedPiece: Position(x, y),
    );
    notifyListeners();
  }

  /// 取消选中
  void _deselectPiece() {
    _uiState = _uiState.copyWith(clearSelectedPiece: true);
    notifyListeners();
  }

  /// 执行移动
  void _executeMove(Move move) {
    // 应用移动
    _gameState = _gameState.applyMove(move);

    // 清除选中状态
    _uiState = _uiState.copyWith(clearSelectedPiece: true);

    // 立即通知UI更新，显示吃子效果
    notifyListeners();

    // 检查游戏是否结束
    if (_gameState.isGameOver()) {
      _uiState = _uiState.copyWith(
        phase: GamePhase.gameOver,
        message: _getGameOverMessage(),
      );
      notifyListeners();
      return;
    }

    // 检查是否需要触发技能选择（参考Lua: shouldTriggerSkillSelection）
    if (_lastSkillSelectionFullmove < _gameState.fullmoveCount) {
      // 触发技能选择流程
      _checkAndStartSkillSelection();
      return;
    }

    // 如果下一个玩家是AI，延迟执行AI回合（让UI先更新）
    if (currentPlayer?.isAI == true) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _executeAITurn();
      });
    }
  }

  /// 执行AI回合
  Future<void> _executeAITurn() async {
    _isAIThinking = true;
    notifyListeners();

    try {
      // 获取AI走法
      final move = await currentPlayer!.play(_gameState);

      if (move != null) {
        _executeMove(move);
      }
    } catch (e) {
      print('[GameController] AI执行出错: $e');
    } finally {
      _isAIThinking = false;
      notifyListeners();
    }
  }

  /// 撤销上一步
  void undoMove() {
    if (_gameState.history.isEmpty) {
      return;
    }

    _gameState = _gameState.undoMove();
    _uiState = _uiState.copyWith(
      clearSelectedPiece: true,
      phase: GamePhase.play,
    );
    notifyListeners();
  }

  /// 检查并开始技能选择流程（本地玩家和AI玩家都需要）
  void _checkAndStartSkillSelection() {
    final currentSide = _gameState.sideToMove;

    // 检查当前玩家是否已完成初始技能选择
    if (_initialSkillSelected[currentSide] == true) {
      // 已选择过初始技能，检查是否需要后续技能选择
      if (_lastSkillSelectionFullmove >= _gameState.fullmoveCount) {
        // 不需要技能选择，直接进入下棋阶段
        if (currentPlayer?.isAI == true) {
          _executeAITurn();
        }
        return;
      }
    }

    // 生成3张随机技能卡
    final availableSkills = _generateSkillCards();

    // 如果当前玩家是AI，自动执行技能选择
    if (currentPlayer?.isAI == true) {
      _executeAISkillSelection(availableSkills);
      return;
    }

    // 如果当前玩家是本地玩家，进入技能选择阶段
    if (currentPlayer?.isMe == true) {
      _uiState = _uiState.copyWith(
        phase: GamePhase.selectSkill,
        availableSkills: availableSkills,
        clearSelectedSkill: true,
        message: '请选择一个技能',
      );
      notifyListeners();
    }
  }

  /// 执行AI的技能选择流程
  Future<void> _executeAISkillSelection(List<Skill> availableSkills) async {
    _isAIThinking = true;
    notifyListeners();

    try {
      // 让AI选择技能
      final selectedSkill = await currentPlayer!.chooseSkill(
        availableSkills,
        _gameState,
      );

      if (selectedSkill != null) {
        // AI选择一个己方棋子来赋予技能
        final targetPiece = _findBestPieceForSkill(selectedSkill);

        if (targetPiece != null) {
          // 赋予技能
          final newSkills = [...targetPiece.piece.skillsList, selectedSkill];
          final newPiece = Piece(
            id: targetPiece.piece.id,
            side: targetPiece.piece.side,
            label: targetPiece.piece.label,
            skillsList: newSkills,
          );

          // 更新棋盘
          final newBoard = _gameState.board.copyWith();
          newBoard.set(targetPiece.x, targetPiece.y, newPiece);

          _gameState = _gameState.copyWith(board: newBoard);

          // 标记当前阵营已完成初始技能选择
          final currentSide = _gameState.sideToMove;
          _initialSkillSelected[currentSide] = true;

          // 更新最后技能选择回合数
          _lastSkillSelectionFullmove = _gameState.fullmoveCount;

          print('[AI] 选择了技能: ${selectedSkill.name}, 赋予给位置(${targetPiece.x}, ${targetPiece.y})的棋子');
        }
      }
    } catch (e) {
      print('[GameController] AI技能选择出错: $e');
    } finally {
      _isAIThinking = false;
      notifyListeners();

      // 检查是否双方都完成了初始技能选择
      final redDone = _initialSkillSelected[Side.red] ?? false;
      final blackDone = _initialSkillSelected[Side.black] ?? false;

      if (redDone && blackDone) {
        // 双方都选完技能，强制切换到红方先下棋
        _gameState = _gameState.copyWith(
          sideToMove: Side.red,
        );
        notifyListeners();

        // 如果红方是AI，开始下棋
        if (currentPlayer?.isAI == true) {
          _executeAITurn();
        }
      } else {
        // 还有玩家未选技能，切换到下一个玩家选技能
        // 切换阵营
        _gameState = _gameState.copyWith(
          sideToMove: _gameState.sideToMove == Side.red ? Side.black : Side.red,
        );
        notifyListeners();

        // 触发下一个玩家的技能选择
        _checkAndStartSkillSelection();
      }
    }
  }

  /// 为技能选择最佳棋子
  /// 优先级：车 > 马 > 炮 > 其他
  ({Piece piece, int x, int y})? _findBestPieceForSkill(Skill skill) {
    final board = _gameState.board;
    final side = _gameState.sideToMove;

    // 收集所有己方棋子
    final candidates = <({Piece piece, int x, int y, int priority})>[];

    for (var y = 0; y < BoardConstants.boardHeight; y++) {
      for (var x = 0; x < BoardConstants.boardWidth; x++) {
        final piece = board.get(x, y);

        if (piece != null && piece.side == side) {
          // 如果已有该技能，跳过
          if (piece.hasSkill(skill.typeId)) {
            continue;
          }

          // 根据棋子类型分配优先级
          int priority = 0;
          if (piece.hasSkill(SkillType.rook)) {
            priority = 3; // 车最高优先级
          } else if (piece.hasSkill(SkillType.knight)) {
            priority = 2; // 马次之
          } else if (piece.hasSkill(SkillType.cannon)) {
            priority = 2; // 炮次之
          } else {
            priority = 1; // 其他
          }

          candidates.add((piece: piece, x: x, y: y, priority: priority));
        }
      }
    }

    // 如果没有候选者，返回null
    if (candidates.isEmpty) {
      return null;
    }

    // 按优先级排序，选择优先级最高的
    candidates.sort((a, b) => b.priority.compareTo(a.priority));

    final best = candidates.first;
    return (piece: best.piece, x: best.x, y: best.y);
  }

  /// 生成3张随机技能卡
  List<Skill> _generateSkillCards() {
    final allSkillTypes = SkillType.values;
    final selected = <SkillType>{};
    final skills = <Skill>[];

    // 随机选择3个不重复的技能
    while (skills.length < 3 && selected.length < allSkillTypes.length) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % allSkillTypes.length;
      final skillType = allSkillTypes[randomIndex];

      if (!selected.contains(skillType)) {
        selected.add(skillType);
        skills.add(skillDefinitions[skillType]!);
      }
    }

    return skills;
  }

  /// 选择技能卡
  void selectSkillCard(Skill skill) {
    if (_uiState.phase != GamePhase.selectSkill) {
      return;
    }

    // 记录选中的技能
    _uiState = _uiState.copyWith(
      selectedSkill: skill,
      phase: GamePhase.selectPiece,
      message: '请点击一个己方棋子来赋予该技能',
    );

    notifyListeners();
  }

  /// 处理技能赋予（在selectPiece阶段点击棋子）
  void _applySkillToPiece(int x, int y) {
    final piece = _gameState.board.get(x, y);
    final selectedSkill = _uiState.selectedSkill;

    // 检查是否可以赋予技能
    if (piece == null || selectedSkill == null) {
      return;
    }

    // 必须是当前行动方的棋子
    if (piece.side != _gameState.sideToMove) {
      _uiState = _uiState.copyWith(
        message: '只能给己方棋子赋予技能！',
      );
      notifyListeners();
      return;
    }

    // 检查是否已有该技能
    if (piece.hasSkill(selectedSkill.typeId)) {
      _uiState = _uiState.copyWith(
        message: '该棋子已拥有此技能！',
      );
      notifyListeners();
      return;
    }

    // 赋予技能：创建新棋子（添加技能）
    final newSkills = [...piece.skillsList, selectedSkill];
    final newPiece = Piece(
      id: piece.id,
      side: piece.side,
      label: piece.label,
      skillsList: newSkills,
    );

    // 更新棋盘
    final newBoard = _gameState.board.copyWith();
    newBoard.set(x, y, newPiece);

    _gameState = _gameState.copyWith(board: newBoard);

    // 标记当前阵营已完成初始技能选择
    final currentSide = _gameState.sideToMove;
    _initialSkillSelected[currentSide] = true;

    // 更新最后技能选择回合数
    _lastSkillSelectionFullmove = _gameState.fullmoveCount;

    // 检查是否双方都完成了初始技能选择
    final redDone = _initialSkillSelected[Side.red] ?? false;
    final blackDone = _initialSkillSelected[Side.black] ?? false;

    if (redDone && blackDone) {
      // 双方都选完技能，强制切换到红方先下棋
      _gameState = _gameState.copyWith(
        sideToMove: Side.red,
      );

      _uiState = _uiState.copyWith(
        phase: GamePhase.play,
        availableSkills: [],
        clearSelectedSkill: true,
        message: '技能已赋予！双方开始对弈，红方先动',
      );
      notifyListeners();

      // 如果红方是AI，执行AI回合
      if (currentPlayer?.isAI == true) {
        _executeAITurn();
      }
    } else {
      // 还有玩家未选技能，切换到下一个玩家
      _uiState = _uiState.copyWith(
        phase: GamePhase.play,
        availableSkills: [],
        clearSelectedSkill: true,
        message: '技能已赋予！等待对方选择技能',
      );

      // 切换阵营
      _gameState = _gameState.copyWith(
        sideToMove: _gameState.sideToMove == Side.red ? Side.black : Side.red,
      );

      notifyListeners();

      // 触发下一个玩家的技能选择
      _checkAndStartSkillSelection();
    }
  }

  /// 获取游戏结束消息
  String _getGameOverMessage() {
    final result = _gameState.getResult();

    switch (result) {
      case 'red_win':
        return '红方胜利！';
      case 'black_win':
        return '黑方胜利！';
      case 'draw':
        return '和棋！';
      default:
        return '游戏结束';
    }
  }

  /// 获取选中棋子的合法移动
  List<Move> getSelectedPieceLegalMoves() {
    if (_uiState.selectedPiece == null) {
      return [];
    }

    return MoveGenerator.getLegalMoves(
      _gameState,
      _uiState.selectedPiece!.x,
      _uiState.selectedPiece!.y,
    );
  }
}
