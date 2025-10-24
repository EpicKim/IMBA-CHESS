// AI控制器
// 参考源文件: src/ai/AI.lua
// 功能：统一AI接口，支持迭代加深、超时控制、技能选择

import 'dart:async';
import '../models/move.dart';
import '../models/game_state.dart';
import '../models/skill.dart';
import '../core/constants.dart';
import 'search.dart';
import 'greedy.dart';

/// AI控制器
///
/// 统一管理AI行为，包括：
/// - 走法选择（迭代加深搜索）
/// - 技能选择
/// - 超时控制
class AIController {
  /// 搜索器
  final Search _search = Search();

  /// AI难度等级
  final int difficultyLevel;

  /// 每步思考时间（毫秒）
  final int thinkingTime;

  /// 构造函数
  ///
  /// 参数:
  /// - difficultyLevel: 难度等级（1-5），影响搜索深度
  /// - thinkingTime: 每步思考时间（毫秒）
  AIController({
    this.difficultyLevel = 3,
    this.thinkingTime = 3000,
  });

  /// 选择最佳走法
  ///
  /// 使用迭代加深搜索，在时间限制内尽可能深入搜索
  ///
  /// 参数:
  /// - gameState: 当前游戏状态
  /// - side: AI阵营
  ///
  /// 返回: 最佳走法（异步）
  Future<Move?> chooseMove(GameState gameState, Side side) async {
    // 在后台线程中执行AI计算，避免阻塞UI
    return await Future(() {
      // 重置搜索状态
      _search.reset();
      _search.setTimeout(thinkingTime);

      Move? bestMove;
      int bestScore = -999999;

      // 根据难度等级确定最大搜索深度
      final maxDepth = _getMaxDepth();

      // 迭代加深搜索
      for (var depth = 1; depth <= maxDepth; depth++) {
        // 搜索当前深度
        final result = _search.findBestMove(gameState, depth, side);

        // 如果超时，使用上一次的结果
        if (_search.isTimeout) {
          print('[AI] 搜索超时，使用深度 ${depth - 1} 的结果');
          break;
        }

        // 更新最佳走法
        if (result.move != null) {
          bestMove = result.move;
          bestScore = result.score;

          print('[AI] 深度 $depth: 分数 $bestScore, 节点 ${_search.nodesSearched}');
        }

        // 如果找到必胜走法，提前结束
        if (bestScore > 800000) {
          print('[AI] 找到必胜走法，提前结束搜索');
          break;
        }
      }

      // 如果Alpha-Beta搜索失败，使用贪心算法作为后备
      if (bestMove == null) {
        print('[AI] Alpha-Beta搜索失败，使用贪心算法');
        bestMove = GreedyAI.chooseMove(gameState, side);
      }

      return bestMove;
    });
  }

  /// 选择技能
  ///
  /// 参数:
  /// - availableSkills: 可用技能列表
  /// - gameState: 当前游戏状态
  /// - side: AI阵营
  ///
  /// 返回: 选中的技能（异步）
  Future<Skill?> chooseSkill(
    List<Skill> availableSkills,
    GameState gameState,
    Side side,
  ) async {
    if (availableSkills.isEmpty) {
      return null;
    }

    // 简单策略：随机选择一个技能
    // TODO: 实现更智能的技能选择策略
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟思考

    return availableSkills.first;
  }

  /// 根据难度等级获取最大搜索深度
  int _getMaxDepth() {
    switch (difficultyLevel) {
      case 1:
        return 2; // 简单
      case 2:
        return 3; // 普通
      case 3:
        return 4; // 困难
      case 4:
        return 5; // 专家
      case 5:
        return 6; // 大师
      default:
        return 4;
    }
  }

  /// 获取AI思考进度（用于UI显示）
  ///
  /// 返回: (搜索节点数, 是否完成)
  ({int nodesSearched, bool isDone}) getProgress() {
    return (
      nodesSearched: _search.nodesSearched,
      isDone: _search.isTimeout,
    );
  }

  /// 清除AI缓存
  void clearCache() {
    _search.reset();
  }
}
