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

  // 设置窗口选项：指定初始大小避免闪烁
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1600, 1000), // 设置初始窗口大小，与 ScreenUtilInit 设计稿尺寸一致
    center: true, // 窗口居中显示
    backgroundColor: Colors.transparent, // 设置透明背景避免白屏
    skipTaskbar: false, // 显示在任务栏
    titleBarStyle: TitleBarStyle.normal, // 标准标题栏
    title: 'IMBA象棋', // 窗口标题
  );

  // 等待窗口准备就绪后再显示，避免闪烁
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // 显示窗口
    await windowManager.focus(); // 获取焦点
  });

  runApp(const ImbaChessApp());
}

/// 应用根组件
class ImbaChessApp extends StatefulWidget {
  const ImbaChessApp({super.key});

  @override
  State<ImbaChessApp> createState() => _ImbaChessAppState();
}

class _ImbaChessAppState extends State<ImbaChessApp> {
  @override
  void initState() {
    super.initState();
    // 延迟执行最大化，确保应用完全启动后再最大化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 延迟 500ms 再最大化，确保所有初始化完成
      await Future.delayed(const Duration(milliseconds: 500));
      await windowManager.maximize(); // 窗口最大化
    });
  }

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
