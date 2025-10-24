// IMBA象棋 Flutter 版本 - 应用入口
// 原项目：LÖVE2D 中国象棋游戏
// 参考源文件: main.lua

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/game_page.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器并设置窗口化最大
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ImbaChessApp());
}

/// 应用根组件
class ImbaChessApp extends StatelessWidget {
  const ImbaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ScreenUtilInit 进行屏幕适配
    return ScreenUtilInit(
      // 设计稿尺寸（减小设计尺寸，让字体和UI元素相对更大）
      designSize: const Size(1600, 1000),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'IMBA象棋',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // 主题配色
            primarySwatch: Colors.brown,
            useMaterial3: true,
            // 默认字体（后续会使用自定义字体）
            fontFamily: 'DingLieZhuHai',
          ),
          home: const GamePage(),
        );
      },
    );
  }
}
