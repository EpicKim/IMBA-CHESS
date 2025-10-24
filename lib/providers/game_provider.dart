// 游戏Provider
// 参考源文件: src/stages/StageManager.lua, main.lua
// 功能：统一管理游戏流程、玩家交互、状态转换、玩家数据

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

/// 回合阶段枚举
/// 用于管理一个完整回合的流程
enum TurnPhase {
  /// 技能选择阶段（双方同时选择技能，不分先后）
  skillSelection,

  /// 技能显示阶段（双方选择完成后，显示对方选择的技能）
  skillReveal,

  /// 下棋阶段（红方先动，黑方后动）
  playing,
}

/// 游戏Provider
///
/// 管理整个游戏的流程、状态和玩家数据
class GameProvider extends ChangeNotifier {
  /// 游戏状态
  GameState _gameState;

  /// UI状态
  UIState _uiState;

  /// 红方玩家
  Player? _redPlayer;

  /// 黑方玩家
  Player? _blackPlayer;

  /// 当前回合阶段（技能选择 -> 技能显示 -> 下棋）
  TurnPhase _turnPhase = TurnPhase.skillSelection;

  /// 当前回合的技能选择状态（记录每方是否选择完成）
  final Map<Side, bool> _skillSelectedThisRound = {
    Side.red: false,
    Side.black: false,
  };

  /// 当前回合选择的技能（临时存储，等双方都选完后一起应用）
  final Map<Side, ({Skill skill, int x, int y})?> _selectedSkillsThisRound = {
    Side.red: null,
    Side.black: null,
  };

  /// 当前回合的下棋状态
  final Map<Side, bool> _movePlayedThisRound = {
    Side.red: false,
    Side.black: false,
  };

  /// 当前是否正在等待玩家操作（用于UI显示加载状态）
  bool _isWaitingForPlayer = false;

  /// 构造函数
  GameProvider()
      : _gameState = GameState.initial(),
        _uiState = const UIState() {
    // 开局时立即触发技能选择（在setPlayers后会自动调用）
    Future.microtask(() => _startTurnPhase());
  }

  /// 获取游戏状态
  GameState get gameState => _gameState;

  /// 获取UI状态
  UIState get uiState => _uiState;

  /// 获取红方玩家
  Player? get redPlayer => _redPlayer;

  /// 获取黑方玩家
  Player? get blackPlayer => _blackPlayer;

  /// 根据阵营获取玩家
  ///
  /// 参数:
  /// - side: 阵营
  ///
  /// 返回: 对应阵营的玩家
  Player? getPlayerBySide(Side side) {
    return side == Side.red ? _redPlayer : _blackPlayer;
  }

  /// 获取当前玩家
  Player? get currentPlayer {
    return getPlayerBySide(_gameState.sideToMove);
  }

  /// 是否正在等待玩家操作
  bool get isWaitingForPlayer => _isWaitingForPlayer;

  /// 获取当前回合阶段
  TurnPhase get turnPhase => _turnPhase;

  /// 获取本地玩家的阵营（用于棋盘翻转）
  /// 如果没有本地玩家，默认返回红方视角
  Side get localPlayerSide {
    // 检查红方玩家是否是本地玩家
    if (_redPlayer?.isMe == true) {
      return Side.red;
    }
    // 检查黑方玩家是否是本地玩家
    if (_blackPlayer?.isMe == true) {
      return Side.black;
    }
    // 默认红方视角
    return Side.red;
  }

  /// 获取本地玩家
  Player? get localPlayer {
    if (_redPlayer?.isMe == true) {
      return _redPlayer;
    }
    if (_blackPlayer?.isMe == true) {
      return _blackPlayer;
    }
    return null;
  }

  /// 设置玩家
  ///
  /// 参数:
  /// - redPlayer: 红方玩家
  /// - blackPlayer: 黑方玩家
  void setPlayers(Player redPlayer, Player blackPlayer) {
    _redPlayer = redPlayer;
    _blackPlayer = blackPlayer;
    notifyListeners();

    // 开局时，触发技能选择
    _startTurnPhase();
  }

  /// 清空玩家数据
  void clearPlayers() {
    _redPlayer = null;
    _blackPlayer = null;
    notifyListeners();
  }

  /// 开始新游戏
  void startNewGame() {
    // 重置游戏状态
    _gameState = GameState.initial();
    _uiState = const UIState();

    // 重置回合阶段和状态
    _turnPhase = TurnPhase.skillSelection;
    _skillSelectedThisRound[Side.red] = false;
    _skillSelectedThisRound[Side.black] = false;
    _selectedSkillsThisRound[Side.red] = null;
    _selectedSkillsThisRound[Side.black] = null;
    _movePlayedThisRound[Side.red] = false;
    _movePlayedThisRound[Side.black] = false;
    _isWaitingForPlayer = false;

    notifyListeners();

    // 开局时，触发技能选择
    _startTurnPhase();
  }

  /// 处理棋盘点击
  ///
  /// 参数:
  /// - x, y: 点击的网格坐标
  void handleBoardTap(int x, int y) {
    // 根据当前阶段处理点击
    switch (_uiState.phase) {
      case GamePhase.play:
        // 下棋阶段：只有当前玩家是本地玩家时才能操作
        if (currentPlayer?.isMe != true) {
          return;
        }
        _handlePlayPhaseTap(x, y);
        break;

      case GamePhase.selectPiece:
        // 技能赋予阶段：只有本地玩家能操作
        if (localPlayer == null) {
          return;
        }
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

      final targetMove =
          legalMoves.where((m) => m.to.x == x && m.to.y == y).firstOrNull;

      if (targetMove != null) {
        // 执行移动（所有玩家统一处理）
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
    // 记录当前是哪一方在走棋（在applyMove之前）
    final movingSide = _gameState.sideToMove;
    final movingPlayer = getPlayerBySide(movingSide);

    // 应用移动
    _gameState = _gameState.applyMove(move);

    // 清除选中状态
    _uiState = _uiState.copyWith(clearSelectedPiece: true);

    // 通知玩家其走法已被执行（用于完成本地玩家的 Future）
    movingPlayer?.notifyMoveExecuted(move);

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

    // 标记走棋方已完成下棋
    _movePlayedThisRound[movingSide] = true;

    // 检查是否双方都走完了
    if (_movePlayedThisRound[Side.red]! && _movePlayedThisRound[Side.black]!) {
      // 双方都走完了，准备进入新一轮技能选择
      _prepareNextRound();
    } else {
      // 还有玩家未走棋，切换到下一个玩家
      _switchToNextPlayer();
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

  /// ========== 统一的游戏流程管理 ==========

  /// 开始当前回合阶段
  ///
  /// 根据_turnPhase决定是技能选择阶段、技能显示阶段还是下棋阶段
  void _startTurnPhase() {
    if (_turnPhase == TurnPhase.skillSelection) {
      _startSkillSelectionPhase();
    } else if (_turnPhase == TurnPhase.skillReveal) {
      _startSkillRevealPhase();
    } else {
      _startPlayingPhase();
    }
  }

  /// 开始技能选择阶段（双方同时选择）
  void _startSkillSelectionPhase() {
    // 重置技能选择状态
    _skillSelectedThisRound[Side.red] = false;
    _skillSelectedThisRound[Side.black] = false;
    _selectedSkillsThisRound[Side.red] = null;
    _selectedSkillsThisRound[Side.black] = null;

    notifyListeners();

    // 同时请求双方选择技能
    _requestPlayerSkillSelection(Side.red);
    _requestPlayerSkillSelection(Side.black);
  }

  /// 开始技能显示阶段
  void _startSkillRevealPhase() {
    // 将临时存储的技能应用到棋盘上
    if (_selectedSkillsThisRound[Side.red] != null) {
      final redSelection = _selectedSkillsThisRound[Side.red]!;
      _applySkillToPieceInternal(
        redSelection.x,
        redSelection.y,
        redSelection.skill,
        Side.red,
      );
    }

    if (_selectedSkillsThisRound[Side.black] != null) {
      final blackSelection = _selectedSkillsThisRound[Side.black]!;
      _applySkillToPieceInternal(
        blackSelection.x,
        blackSelection.y,
        blackSelection.skill,
        Side.black,
      );
    }

    // 更新UI显示技能显示阶段
    _uiState = _uiState.copyWith(
      phase: GamePhase.play,
      message: '双方技能已显示！',
    );
    notifyListeners();

    // 延迟一段时间，让玩家看到对方选择的技能，然后进入下棋阶段
    Future.delayed(const Duration(milliseconds: 1500), () {
      _turnPhase = TurnPhase.playing;
      _startPlayingPhase();
    });
  }

  /// 开始下棋阶段
  void _startPlayingPhase() {
    // 重置下棋状态
    _movePlayedThisRound[Side.red] = false;
    _movePlayedThisRound[Side.black] = false;

    // 从红方开始走棋
    _gameState = _gameState.copyWith(sideToMove: Side.red);

    // 更新UI状态为下棋阶段
    _uiState = _uiState.copyWith(
      phase: GamePhase.play,
      message: '下棋阶段开始，红方先走',
    );
    notifyListeners();

    // 请求红方走棋
    _requestPlayerMove();
  }

  /// 请求指定玩家选择技能
  void _requestPlayerSkillSelection(Side side) async {
    final player = getPlayerBySide(side);
    if (player == null) return;

    // 生成3张随机技能卡
    final availableSkills = _generateSkillCards();

    // 如果是本地玩家，显示技能选择UI，让UI处理技能选择和棋子选择
    if (player.isMe) {
      _uiState = _uiState.copyWith(
        phase: GamePhase.selectSkill,
        availableSkills: availableSkills,
        clearSelectedSkill: true,
        message: '请选择一个技能',
      );
      notifyListeners();

      // 本地玩家的技能选择由UI处理（selectSkillCard -> _applySkillToPiece）
      // 这里只需等待，不需要额外处理
      try {
        await player.chooseSkill(availableSkills, _gameState);
      } catch (e) {
        print('[GameProvider] ${side == Side.red ? "红方" : "黑方"} 技能选择出错: $e');
      }
      return;
    }

    // 非本地玩家（AI/OnlinePlayer）自动选择
    try {
      // 调用玩家的chooseSkill方法（AI/OnlinePlayer会自动计算）
      final selectedSkill = await player.chooseSkill(
        availableSkills,
        _gameState,
      );

      if (selectedSkill != null) {
        // 选择一个己方棋子来赋予技能
        final targetPiece = _findBestPieceForSkill(selectedSkill, side);

        if (targetPiece != null) {
          // 存储技能选择（不立即应用）
          _selectedSkillsThisRound[side] = (
            skill: selectedSkill,
            x: targetPiece.x,
            y: targetPiece.y,
          );

          // 标记该方已完成技能选择
          _skillSelectedThisRound[side] = true;

          print(
              '[GameProvider] ${side == Side.red ? "红方" : "黑方"} 已选择技能: ${selectedSkill.name}');

          // 检查是否双方都选完了
          if (_skillSelectedThisRound[Side.red]! &&
              _skillSelectedThisRound[Side.black]!) {
            // 双方都选完了，进入技能显示阶段
            _turnPhase = TurnPhase.skillReveal;
            _startSkillRevealPhase();
          }
        }
      }
    } catch (e) {
      print('[GameProvider] ${side == Side.red ? "红方" : "黑方"} 技能选择出错: $e');
    }
  }

  /// 请求当前玩家走棋
  void _requestPlayerMove() async {
    if (currentPlayer == null) return;

    // 标记正在等待玩家操作
    _isWaitingForPlayer = true;
    notifyListeners();

    try {
      // 调用玩家的play方法（本地玩家会等待UI，AI会自动计算）
      final move = await currentPlayer!.play(_gameState);

      if (move != null) {
        _executeMove(move);
      }
    } catch (e) {
      print('[GameProvider] 走棋出错: $e');
    } finally {
      _isWaitingForPlayer = false;
      notifyListeners();
    }
  }

  /// 切换到下一个玩家（仅在下棋阶段使用）
  void _switchToNextPlayer() {
    // 注意：applyMove 已经切换了 sideToMove，所以这里不需要再切换
    // 直接请求下一个玩家（currentPlayer 已经是下一个玩家了）走棋
    _requestPlayerMove();
  }

  /// 准备进入下一轮（从技能选择重新开始）
  void _prepareNextRound() {
    // 切换到技能选择阶段
    _turnPhase = TurnPhase.skillSelection;

    // 延迟一点时间，让UI显示上一轮的结果
    Future.delayed(const Duration(milliseconds: 500), () {
      _startTurnPhase();
    });
  }

  /// 为技能选择最佳棋子
  /// 优先级：车 > 马 > 炮 > 其他
  ({Piece piece, int x, int y})? _findBestPieceForSkill(
      Skill skill, Side side) {
    final board = _gameState.board;

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
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % allSkillTypes.length;
      final skillType = allSkillTypes[randomIndex];

      if (!selected.contains(skillType)) {
        selected.add(skillType);
        skills.add(skillDefinitions[skillType]!);
      }
    }

    return skills;
  }

  /// 选择技能卡（由UI调用，仅用于本地玩家）
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

    // 必须是本地玩家自己的棋子
    if (piece.side != localPlayerSide) {
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

    // 存储技能选择（不立即应用，等对方也选完后一起显示）
    _selectedSkillsThisRound[localPlayerSide] = (
      skill: selectedSkill,
      x: x,
      y: y,
    );

    // 标记本地玩家已完成技能选择
    _skillSelectedThisRound[localPlayerSide] = true;

    // 通知玩家其技能已被选择（用于完成本地玩家的 Future）
    localPlayer?.notifySkillApplied(selectedSkill);

    // 更新UI显示等待对方
    _uiState = _uiState.copyWith(
      phase: GamePhase.play,
      availableSkills: [],
      clearSelectedSkill: true,
      message: '技能已选择！等待对方选择技能...',
    );
    notifyListeners();

    // 检查是否双方都选完了
    if (_skillSelectedThisRound[Side.red]! &&
        _skillSelectedThisRound[Side.black]!) {
      // 双方都选完了，进入技能显示阶段
      _turnPhase = TurnPhase.skillReveal;
      _startSkillRevealPhase();
    }
  }

  /// 内部方法：应用技能到棋子（在技能显示阶段调用）
  void _applySkillToPieceInternal(int x, int y, Skill skill, Side side) {
    final piece = _gameState.board.get(x, y);
    if (piece == null) return;

    // 赋予技能：创建新棋子（添加技能）
    final newSkills = [...piece.skillsList, skill];
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

    print(
        '[GameProvider] ${side == Side.red ? "红方" : "黑方"} 的技能 ${skill.name} 已应用到位置($x, $y)的棋子');
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
