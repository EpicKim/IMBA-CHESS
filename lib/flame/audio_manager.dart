// 音效管理器
// 功能：预加载和播放游戏音效

import 'package:flame_audio/flame_audio.dart';

/// 音效管理器
/// 负责音效的预加载和播放
class AudioManager {
  /// 预加载所有音效资源
  /// 在游戏初始化时调用
  static Future<void> preload() async {
    try {
      // 预加载车的音效
      // 注意：FlameAudio.audioCache.load 会自动添加 assets/ 前缀
      // 所以这里只需要 audio/rook.mp3，最终路径是 assets/audio/rook.mp3
      await FlameAudio.audioCache.load('rook.mp3');

      // 预加载炮的音效
      await FlameAudio.audioCache.load('cannon.mp3');

      print('[AudioManager] 音效资源加载成功');
    } catch (e) {
      print('[AudioManager] 音效资源加载失败: $e');
      // 如果加载失败，继续运行但不播放音效
    }
  }

  /// 播放车的音效
  static void playRook() {
    try {
      FlameAudio.play('rook.mp3', volume: 0.8);
    } catch (e) {
      print('[AudioManager] 播放车音效失败: $e');
    }
  }

  /// 播放炮的音效
  static void playCannon() {
    try {
      FlameAudio.play('audio/cannon.mp3', volume: 0.8);
    } catch (e) {
      print('[AudioManager] 播放炮音效失败: $e');
    }
  }

  /// 清理音频资源
  static void dispose() {
    FlameAudio.audioCache.clearAll();
  }
}
