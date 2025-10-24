// 游戏状态类型定义
// 功能：定义游戏回合阶段和UI状态

import '../models/move.dart';
import '../models/skill.dart';

/// 回合阶段枚举
/// 用于管理一个完整回合的流程
enum TurnPhase {
  /// 技能选择阶段（双方同时选择技能，不分先后）
  skillSelection,

  /// 棋子选择阶段（技能应用目标）
  selectPiece,

  /// 技能显示阶段（双方选择完成后，显示对方选择的技能）
  skillReveal,

  /// 下棋阶段（红方先动，黑方后动）
  playing,

  /// 游戏结束阶段
  gameOver,
}

/// UI状态类
///
/// 存储当前UI相关的状态信息
class UIState {
  /// 当前游戏阶段
  final TurnPhase phase;

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
    this.phase = TurnPhase.playing,
    this.selectedPiece,
    this.availableSkills = const [],
    this.selectedSkill,
    this.message,
  });

  /// 创建副本
  UIState copyWith({
    TurnPhase? phase,
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
