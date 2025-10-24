// IMBA象棋 Widget 测试文件

import 'package:flutter_test/flutter_test.dart';
import 'package:imba_chess/main.dart';

void main() {
  testWidgets('应用启动测试', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const ImbaChessApp());

    // 验证标题是否显示
    expect(find.text('IMBA象棋'), findsOneWidget);

    // 验证副标题是否显示
    expect(find.text('带技能系统的中国象棋'), findsOneWidget);

    // 验证开始游戏按钮是否显示
    expect(find.text('开始游戏'), findsOneWidget);
  });
}
