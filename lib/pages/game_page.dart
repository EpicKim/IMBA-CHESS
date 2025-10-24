// 游戏主页面
// 参考源文件: main.lua
// 功能：整合所有UI组件，展示完整游戏界面

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/panels/info_panel.dart';
import '../widgets/panels/skill_panel.dart';
import '../models/me_player.dart';
import '../models/ai_player.dart';
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
  late GameController _gameController;

  @override
  void initState() {
    super.initState();

    // 初始化游戏控制器
    _gameController = GameController();

    // 设置玩家（默认：玩家 vs AI）
    _gameController.setPlayers(
      MePlayer(
        id: 'me',
        name: '玩家',
        side: Side.red,
      ),
      AIPlayer(
        id: 'ai',
        name: 'AI',
        side: Side.black,
        difficultyLevel: 3,
        thinkingTime: 3000,
      ),
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IMBA象棋'),
          centerTitle: true,
          backgroundColor: const Color(0xFF8B7355),
          actions: [
            // 撤销按钮
            Consumer<GameController>(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: controller.gameState.history.isEmpty ? null : () => controller.undoMove(),
                  tooltip: '悔棋',
                );
              },
            ),

            // 重新开始按钮
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showRestartDialog(),
              tooltip: '重新开始',
            ),

            // 设置按钮
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(),
              tooltip: '设置',
            ),
          ],
        ),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 信息面板
                Consumer<GameController>(
                  builder: (context, controller, _) {
                    final selectedPiece = controller.uiState.selectedPiece != null
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

                const SizedBox(height: 16),

                // AI思考指示器
                Consumer<GameController>(
                  builder: (context, controller, _) {
                    if (controller.isAIThinking) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              const Text('AI思考中...'),
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
          child: Consumer<GameController>(
            builder: (context, controller, _) {
              return BoardWidget(
                board: controller.gameState.board,
                selectedPiece: controller.uiState.selectedPiece,
                legalMoves: controller.getSelectedPieceLegalMoves(),
                lastMove: controller.gameState.history.lastOrNull,
                localPlayerSide: Side.red, // 默认红方视角
                onTap: (x, y) => controller.handleBoardTap(x, y),
                gamePhase: controller.uiState.phase,
                selectedSkill: controller.uiState.selectedSkill,
                currentSide: controller.gameState.sideToMove,
              );
            },
          ),
        ),

        // 右侧面板
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer<GameController>(
              builder: (context, controller, _) {
                return SkillPanel(
                  availableSkills: controller.uiState.availableSkills,
                  selectedSkill: controller.uiState.selectedSkill,
                  isSelecting: controller.uiState.phase == GamePhase.selectSkill,
                  message: controller.uiState.message ?? '',
                  onSkillSelected: (skill) => controller.selectSkillCard(skill),
                );
              },
            ),
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
          child: Consumer<GameController>(
            builder: (context, controller, _) {
              return BoardWidget(
                board: controller.gameState.board,
                selectedPiece: controller.uiState.selectedPiece,
                legalMoves: controller.getSelectedPieceLegalMoves(),
                lastMove: controller.gameState.history.lastOrNull,
                localPlayerSide: Side.red,
                onTap: (x, y) => controller.handleBoardTap(x, y),
                gamePhase: controller.uiState.phase,
                selectedSkill: controller.uiState.selectedSkill,
                currentSide: controller.gameState.sideToMove,
              );
            },
          ),
        ),

        // 信息区域
        Expanded(
          flex: 2,
          child: Consumer<GameController>(
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
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            const Text('AI思考中...'),
                          ],
                        ),
                      ),

                    // 简化的信息显示
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip(
                            '回合',
                            '${controller.gameState.fullmoveCount}',
                          ),
                          _buildInfoChip(
                            '行动方',
                            controller.gameState.sideToMove == Side.red ? '红' : '黑',
                            color: controller.gameState.sideToMove == Side.red ? Colors.red : Colors.blueGrey,
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
      ],
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(String label, String value, {Color? color}) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color?.withOpacity(0.2),
      labelStyle: TextStyle(
        color: color ?? Colors.black,
        fontWeight: FontWeight.bold,
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
              _gameController.startNewGame();
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
