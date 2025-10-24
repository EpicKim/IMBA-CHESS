// 游戏主页面
// 参考源文件: main.lua
// 功能：整合所有UI组件，展示完整游戏界面

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/game_controller.dart';
import 'board/board_widget.dart';
import 'panels/info_panel.dart';
import 'panels/skill_panel.dart';
import '../players/me_player.dart';
import '../players/ai_player.dart';
import '../models/game_phase.dart';
import '../core/constants.dart';

/// 游戏主页面
///
/// 包含完整的游戏界面：
/// - 棋盘
/// - 信息面板
/// - 技能面板
/// - 操作按钮
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameProvider _gameProvider;

  @override
  void initState() {
    super.initState();

    // 初始化游戏Provider
    _gameProvider = GameProvider();

    // 设置玩家（默认：AI vs 玩家）
    _gameProvider.setPlayers(
      AIPlayer(
        id: 'ai',
        name: 'AI',
        side: Side.red,
        difficultyLevel: 3,
        thinkingTime: 3000,
      ),
      MePlayer(
        id: 'me',
        name: '玩家',
        side: Side.black,
      ),
    );
  }

  @override
  void dispose() {
    _gameProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用ChangeNotifierProvider提供GameProvider
    return ChangeNotifierProvider.value(
      value: _gameProvider,
      child: Scaffold(
        body: Container(
          color: const Color(0xFFF5F5DC),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 响应式布局：根据屏幕尺寸决定布局方式
              final isWideScreen = constraints.maxWidth > 800;

              if (isWideScreen) {
                // 宽屏：横向布局
                return _buildWideLayout();
              } else {
                // 窄屏：纵向布局
                return _buildNarrowLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  /// 构建宽屏布局
  Widget _buildWideLayout() {
    return Row(
      children: [
        // 左侧面板
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // 信息面板
                Consumer<GameProvider>(
                  builder: (context, controller, _) {
                    final selectedPiece =
                        controller.uiState.selectedPiece != null
                            ? controller.gameState.board.get(
                                controller.uiState.selectedPiece!.x,
                                controller.uiState.selectedPiece!.y,
                              )
                            : null;

                    return InfoPanel(
                      gameState: controller.gameState,
                      selectedPiece: selectedPiece,
                      legalMoves: controller.getSelectedPieceLegalMoves(),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                // AI思考指示器
                Consumer<GameProvider>(
                  builder: (context, controller, _) {
                    if (controller.isAIThinking) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              const CircularProgressIndicator(),
                              SizedBox(width: 16.w),
                              Text('AI思考中...',
                                  style: TextStyle(fontSize: 20.sp)),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),

        // 中间：棋盘
        Expanded(
          flex: 5,
          child: Center(
            child: Consumer<GameProvider>(
              builder: (context, controller, _) {
                return BoardWidget(
                  board: controller.gameState.board,
                  selectedPiece: controller.uiState.selectedPiece,
                  legalMoves: controller.getSelectedPieceLegalMoves(),
                  lastMove: controller.gameState.history.lastOrNull,
                  localPlayerSide:
                      controller.localPlayerSide, // 使用本地玩家阵营（棋盘会根据玩家阵营翻转）
                  onTap: (x, y) => controller.handleBoardTap(x, y),
                  gamePhase: controller.uiState.phase,
                  selectedSkill: controller.uiState.selectedSkill,
                  currentSide: controller.gameState.sideToMove,
                );
              },
            ),
          ),
        ),

        // 右侧面板
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // 技能面板
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w),
                  child: Consumer<GameProvider>(
                    builder: (context, controller, _) {
                      return SkillPanel(
                        availableSkills: controller.uiState.availableSkills,
                        selectedSkill: controller.uiState.selectedSkill,
                        isSelecting:
                            controller.uiState.phase == GamePhase.selectSkill,
                        message: controller.uiState.message ?? '',
                        currentSide: controller.gameState.sideToMove,
                        onSkillSelected: (skill) =>
                            controller.selectSkillCard(skill),
                      );
                    },
                  ),
                ),
              ),

              // 操作按钮区域
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建窄屏布局
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // 棋盘
        Expanded(
          flex: 3,
          child: Center(
            child: Consumer<GameProvider>(
              builder: (context, controller, _) {
                return BoardWidget(
                  board: controller.gameState.board,
                  selectedPiece: controller.uiState.selectedPiece,
                  legalMoves: controller.getSelectedPieceLegalMoves(),
                  lastMove: controller.gameState.history.lastOrNull,
                  localPlayerSide:
                      controller.localPlayerSide, // 使用本地玩家阵营（棋盘会根据玩家阵营翻转）
                  onTap: (x, y) => controller.handleBoardTap(x, y),
                  gamePhase: controller.uiState.phase,
                  selectedSkill: controller.uiState.selectedSkill,
                  currentSide: controller.gameState.sideToMove,
                );
              },
            ),
          ),
        ),

        // 信息区域
        Expanded(
          flex: 2,
          child: Consumer<GameProvider>(
            builder: (context, controller, _) {
              final selectedPiece = controller.uiState.selectedPiece != null
                  ? controller.gameState.board.get(
                      controller.uiState.selectedPiece!.x,
                      controller.uiState.selectedPiece!.y,
                    )
                  : null;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // AI思考指示器
                    if (controller.isAIThinking)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        color: Colors.blue.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(width: 16.w),
                            Text('AI思考中...', style: TextStyle(fontSize: 20.sp)),
                          ],
                        ),
                      ),

                    // 简化的信息显示
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip(
                            '回合',
                            '${controller.gameState.fullmoveCount}',
                          ),
                          _buildInfoChip(
                            '行动方',
                            controller.gameState.sideToMove == Side.red
                                ? '红'
                                : '黑',
                            color: controller.gameState.sideToMove == Side.red
                                ? Colors.red
                                : Colors.black,
                          ),
                          if (selectedPiece != null)
                            _buildInfoChip(
                              '选中',
                              selectedPiece.label ?? '?',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 操作按钮区域
        _buildActionButtons(),
      ],
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(String label, String value, {Color? color}) {
    return Chip(
      label: Text('$label: $value', style: TextStyle(fontSize: 18.sp)),
      backgroundColor: color?.withOpacity(0.2),
      labelStyle: TextStyle(
        color: color ?? Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B7355).withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Consumer<GameProvider>(
        builder: (context, controller, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 悔棋按钮
              Expanded(
                child: _buildActionButton(
                  icon: Icons.undo,
                  label: '悔棋',
                  color: const Color(0xFF8B7355),
                  onPressed: controller.gameState.history.isEmpty
                      ? null
                      : () => controller.undoMove(),
                ),
              ),
              SizedBox(width: 12.w),

              // 重新开始按钮
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  label: '重新开始',
                  color: const Color(0xFF8B7355),
                  onPressed: () => _showRestartDialog(),
                ),
              ),
              SizedBox(width: 12.w),

              // 设置按钮
              Expanded(
                child: _buildActionButton(
                  icon: Icons.settings,
                  label: '设置',
                  color: const Color(0xFF8B7355),
                  onPressed: () => _showSettingsDialog(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示重新开始对话框
  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新开始'),
        content: const Text('确定要重新开始游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _gameProvider.startNewGame();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Text('设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
