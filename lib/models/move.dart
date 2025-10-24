// 走法数据模型
// 参考源文件: src/game/MoveGen.lua

import 'package:equatable/equatable.dart';
import '../skills/skill.dart';

/// 棋盘位置（坐标）
class Position extends Equatable {
  final int x; // 列坐标 (0-8)
  final int y; // 行坐标 (0-9)

  const Position(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';

  /// 复制并修改
  Position copyWith({int? x, int? y}) {
    return Position(x ?? this.x, y ?? this.y);
  }
}

/// 走法类
/// 表示一步棋的移动（从起点到终点）
class Move extends Equatable {
  final Position from; // 起始位置
  final Position to; // 目标位置
  final int? capturedPieceId; // 被吃棋子的ID（null表示未吃子）
  final Skill? bySkill; // 发起该走法的技能实例（用于动画判断）
  final bool isCapture; // 是否为吃子走法
  final String? note; // 备注信息

  const Move({
    required this.from,
    required this.to,
    this.capturedPieceId,
    this.bySkill,
    this.isCapture = false,
    this.note,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        capturedPieceId,
        bySkill,
        isCapture,
        note,
      ];

  @override
  String toString() {
    final captureText = isCapture ? ' (吃子)' : '';
    return 'Move{$from → $to$captureText}';
  }

  /// 复制并修改部分字段
  Move copyWith({
    Position? from,
    Position? to,
    int? capturedPieceId,
    Skill? bySkill,
    bool? isCapture,
    String? note,
  }) {
    return Move(
      from: from ?? this.from,
      to: to ?? this.to,
      capturedPieceId: capturedPieceId ?? this.capturedPieceId,
      bySkill: bySkill ?? this.bySkill,
      isCapture: isCapture ?? this.isCapture,
      note: note ?? this.note,
    );
  }

  /// 创建简单走法（不指定技能）
  factory Move.simple({
    required int fromX,
    required int fromY,
    required int toX,
    required int toY,
    int? capturedPieceId,
  }) {
    return Move(
      from: Position(fromX, fromY),
      to: Position(toX, toY),
      capturedPieceId: capturedPieceId,
      isCapture: capturedPieceId != null,
    );
  }
}
