// 精灵缓存管理器
// 功能：预加载和缓存精灵资源，避免重复加载

import 'package:flame/components.dart';

/// 精灵缓存管理器
/// 预加载所有游戏精灵资源，提供统一访问接口
class SpriteCache {
  // 精灵资源缓存
  final Map<String, Sprite> _spriteCache = {};

  /// 预加载所有精灵资源
  /// 在游戏初始化时调用
  Future<void> preload() async {
    try {
      // 加载车（红方）精灵（Flame会自动添加assets/前缀）
      _spriteCache['rook_red'] = await Sprite.load('rook/rook.png');

      // 加载车（黑方）精灵
      _spriteCache['rook_black'] = await Sprite.load('rook/rook_black.png');

      // 加载炮（红方）精灵
      _spriteCache['cannon_red'] = await Sprite.load('cannon/cannon.png');

      print('[SpriteCache] 精灵资源加载成功');
    } catch (e) {
      print('[SpriteCache] 精灵资源加载失败: $e');
      // 如果加载失败，继续运行但不显示精灵图
    }
  }

  /// 获取精灵资源
  /// 参数：
  /// - key: 精灵键名
  /// 返回：精灵对象，如果不存在返回 null
  Sprite? get(String key) {
    return _spriteCache[key];
  }

  /// 清理所有缓存
  void clear() {
    _spriteCache.clear();
  }
}
