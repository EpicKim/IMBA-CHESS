// 本地玩家
// 参考源文件: src/players/MePlayer.lua
// 功能：表示本地人类玩家

import 'dart:async';
import 'player.dart';
import 'move.dart';
import 'game_state.dart';
import 'skill.dart';
import '../core/constants.dart';

/// 本地玩家类
///
/// 代表本地人类玩家，走法由UI交互触发
class MePlayer extends Player {
  /// 走法完成器（用于等待UI输入）
  Completer<Move?>? _moveCompleter;

  /// 技能选择完成器（用于等待UI输入）
  Completer<Skill?>? _skillCompleter;

  /// 构造函数
  MePlayer({
    required super.id,
    required super.name,
    required super.side,
  });

  @override
  Future<Move?> play(GameState gameState) async {
    // 创建完成器，等待UI输入
    _moveCompleter = Completer<Move?>();

    // 返回Future，等待UI调用submitMove
    return _moveCompleter!.future;
  }

  /// 提交走法（由UI调用）
  ///
  /// 参数:
  /// - move: 玩家选择的走法
  void submitMove(Move? move) {
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.complete(move);
      _moveCompleter = null;
    }
  }

  @override
  Future<Skill?> chooseSkill(
    List<Skill> availableSkills,
    GameState gameState,
  ) async {
    // 创建完成器，等待UI输入
    _skillCompleter = Completer<Skill?>();

    // 返回Future，等待UI调用submitSkill
    return _skillCompleter!.future;
  }

  /// 提交技能选择（由UI调用）
  ///
  /// 参数:
  /// - skill: 玩家选择的技能
  void submitSkill(Skill? skill) {
    if (_skillCompleter != null && !_skillCompleter!.isCompleted) {
      _skillCompleter!.complete(skill);
      _skillCompleter = null;
    }
  }

  /// 取消等待
  void cancel() {
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.complete(null);
      _moveCompleter = null;
    }

    if (_skillCompleter != null && !_skillCompleter!.isCompleted) {
      _skillCompleter!.complete(null);
      _skillCompleter = null;
    }
  }

  @override
  bool get isMe => true;

  @override
  bool get isAI => false;

  @override
  bool get isOnline => false;
}
