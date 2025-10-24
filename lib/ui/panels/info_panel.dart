// 信息面板
// 参考源文件: src/areas/InfoArea.lua
// 功能：显示游戏信息（当前回合、选中棋子、合法移动数等）

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../game_provider/game_state.dart';
import '../../models/piece.dart';
import '../../models/move.dart';
import '../../core/constants.dart';
import '../../game_provider/game_provider.dart';

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
    // 从GameProvider获取玩家信息
    final game = context.watch<GameProvider>();
    final currentPlayer = game.getPlayerBySide(gameState.sideToMove);

    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '游戏信息',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            SizedBox(height: 8.h),

            // 当前回合信息
            _buildInfoRow(
              '当前回合',
              '第 ${gameState.fullmoveCount} 回合',
            ),
            _buildInfoRow(
              '行动方',
              '${gameState.sideToMove == Side.red ? '红方' : '黑方'}${currentPlayer != null ? ' (${currentPlayer.name})' : ''}',
              color: gameState.sideToMove == Side.red ? Colors.red : Colors.blueGrey,
            ),

            SizedBox(height: 8.h),
            const Divider(),
            SizedBox(height: 8.h),

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
              SizedBox(height: 8.h),
              Text(
                '拥有技能：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 4.h),
              ...selectedPiece!.skillsList.map((skill) {
                return Padding(
                  padding: EdgeInsets.only(left: 16.w, top: 2.h),
                  child: Text(
                    '• ${skill.getDisplayName(selectedPiece!.side)}',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                );
              }),
            ] else ...[
              Text(
                '未选中棋子',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18.sp,
                ),
              ),
            ],

            SizedBox(height: 8.h),
            const Divider(),
            SizedBox(height: 8.h),

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
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 28.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '将军！',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
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
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
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
