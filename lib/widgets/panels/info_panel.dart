// 信息面板
// 参考源文件: src/areas/InfoArea.lua
// 功能：显示游戏信息（当前回合、选中棋子、合法移动数等）

import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/piece.dart';
import '../../models/move.dart';
import '../../core/constants.dart';

/// 信息面板组件
///
/// 显示游戏实时信息
class InfoPanel extends StatelessWidget {
  /// 游戏状态
  final GameState gameState;

  /// 选中的棋子
  final Piece? selectedPiece;

  /// 合法移动列表
  final List<Move> legalMoves;

  /// 构造函数
  const InfoPanel({
    super.key,
    required this.gameState,
    this.selectedPiece,
    this.legalMoves = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Text(
              '游戏信息',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 当前回合信息
            _buildInfoRow(
              '当前回合',
              '第 ${gameState.fullmoveCount} 回合',
            ),
            _buildInfoRow(
              '行动方',
              gameState.sideToMove == Side.red ? '红方' : '黑方',
              color: gameState.sideToMove == Side.red ? Colors.red : Colors.blueGrey,
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 选中棋子信息
            if (selectedPiece != null) ...[
              _buildInfoRow(
                '选中棋子',
                selectedPiece!.label ?? '?',
                color: selectedPiece!.side == Side.red ? Colors.red : Colors.blueGrey,
              ),
              _buildInfoRow(
                '技能数量',
                '${selectedPiece!.skillsList.length} 个',
              ),
              _buildInfoRow(
                '合法移动',
                '${legalMoves.length} 种',
              ),

              // 技能列表
              const SizedBox(height: 8),
              const Text(
                '拥有技能：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...selectedPiece!.skillsList.map((skill) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '• ${skill.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
            ] else ...[
              const Text(
                '未选中棋子',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 游戏统计信息
            _buildInfoRow(
              '移动步数',
              '${gameState.history.length} 步',
            ),
            _buildInfoRow(
              '半回合计数',
              '${gameState.halfmoveClock}',
            ),

            // 游戏状态警告
            if (gameState.isInCheck()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '将军！',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
