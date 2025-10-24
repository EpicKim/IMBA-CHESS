// IMBA象棋 Flutter 版本 - 应用入口
// 原项目：LÖVE2D 中国象棋游戏
// 参考源文件: main.lua

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'pages/game_page.dart';

void main() {
  runApp(const ImbaChessApp());
}

/// 应用根组件
class ImbaChessApp extends StatelessWidget {
  const ImbaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ScreenUtilInit 进行屏幕适配
    return ScreenUtilInit(
      // 设计稿尺寸（基于原LÖVE2D项目的默认窗口）
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
          home: const GameHomePage(),
        );
      },
    );
  }
}

/// 游戏主页面（临时占位，后续会实现完整功能）
class GameHomePage extends StatelessWidget {
  const GameHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2A26), // 深色背景
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 游戏标题
            Text(
              'IMBA象棋',
              style: TextStyle(
                fontSize: 72.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700), // 金色
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // 副标题
            Text(
              '带技能系统的中国象棋',
              style: TextStyle(
                fontSize: 24.sp,
                color: Colors.white70,
              ),
            ),

            SizedBox(height: 80.h),

            // 开始游戏按钮
            ElevatedButton(
              onPressed: () {
                // 跳转到游戏画面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513), // 棕色
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 48.w,
                  vertical: 16.h,
                ),
                textStyle: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('开始游戏'),
            ),

            SizedBox(height: 60.h),

            // 项目信息
            Text(
              'Flutter 版本 v1.0.0\n改造自 LÖVE2D 项目',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white38,
                height: 1.5,
              ),
            ),

            SizedBox(height: 40.h),

            // 开发进度提示
            Container(
              padding: EdgeInsets.all(20.w),
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '✅ 核心功能已完成',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.greenAccent,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '游戏逻辑、UI渲染、AI系统、玩家系统',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white60,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '点击"开始游戏"体验完整象棋对弈！',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
