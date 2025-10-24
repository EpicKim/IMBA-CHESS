// 游戏阶段枚举
// 参考源文件: src/stages/StageConstants.lua
// 功能：定义游戏的不同阶段

import 'move.dart';
import 'skill.dart';

/// 游戏阶段枚举
///
/// 定义游戏过程中的各个阶段
enum GamePhase {
  /// 正常对局阶段
  play,

  /// 技能选择阶段
  selectSkill,

  /// 棋子选择阶段（技能应用目标）
  selectPiece,

  /// 游戏结束阶段
  gameOver,
}

/// UI状态类
///
/// 存储当前UI相关的状态信息
class UIState {
  /// 当前游戏阶段
  final GamePhase phase;

  /// 选中的棋子位置
  final Position? selectedPiece;

  /// 可用技能列表（在技能选择阶段使用）
  final List<Skill> availableSkills;

  /// 选中的技能（在技能选择阶段使用）
  final Skill? selectedSkill;

  /// 消息提示
  final String? message;

  /// 构造函数
  const UIState({
    this.phase = GamePhase.play,
    this.selectedPiece,
    this.availableSkills = const [],
    this.selectedSkill,
    this.message,
  });

  /// 创建副本
  UIState copyWith({
    GamePhase? phase,
    Position? selectedPiece,
    bool clearSelectedPiece = false,
    List<Skill>? availableSkills,
    Skill? selectedSkill,
    bool clearSelectedSkill = false,
    String? message,
    bool clearMessage = false,
  }) {
    return UIState(
      phase: phase ?? this.phase,
      selectedPiece: clearSelectedPiece ? null : (selectedPiece ?? this.selectedPiece),
      availableSkills: availableSkills ?? this.availableSkills,
      selectedSkill: clearSelectedSkill ? null : (selectedSkill ?? this.selectedSkill),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
