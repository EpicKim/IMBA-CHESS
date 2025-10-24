# IMBA 象棋 (imba_chess)

> 带技能系统的中国象棋 Flutter 跨平台应用
>
> 改造自 LÖVE2D 原项目 `LOVE-CHESS`

---

## 📖 项目简介

IMBA 象棋是一款创新的中国象棋游戏，特色功能包括：

- ✅ 完整的中国象棋规则实现
- ✅ 技能系统（棋子可获得多个技能）
- ✅ 技能卡选择机制
- ✅ AI 对手（Alpha-Beta 剪枝搜索）
- ✅ 车/炮技能动画效果
- ✅ 玩家系统（本地/AI/联机）

本项目将原 LÖVE2D (Lua) 项目改造为 Flutter 跨平台应用，支持：

- 🖥️ **Desktop**: Windows, macOS, Linux
- 📱 **Mobile**: Android, iOS
- 🌐 **Web**: 浏览器运行（未来支持）

---

## 🚀 快速开始

### 环境要求

- Flutter SDK ≥ 3.24.0
- Dart ≥ 3.4.0

### 安装依赖

```bash
# 克隆项目
cd /Users/stuff/LOVE-CHESS/imba_chess

# 安装依赖（如需代理）
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890
flutter pub get

# 检查项目状态
flutter doctor
flutter analyze
```

### 运行项目

```bash
# 在 macOS 上运行
flutter run -d macos

# 在 Windows 上运行
flutter run -d windows

# 在 Linux 上运行
flutter run -d linux

# 在 Android 设备/模拟器上运行
flutter run -d android

# 在 iOS 设备/模拟器上运行
flutter run -d ios

# 查看所有可用设备
flutter devices
```

### 运行测试

```bash
flutter test
```

---

## 📂 项目结构

```
imba_chess/
├── lib/
│   ├── main.dart                       # 应用入口 ✅
│   ├── core/                           # 核心业务逻辑
│   │   ├── constants.dart              # 常量定义 ✅
│   │   ├── skills/
│   │   │   ├── skill_types.dart        # 技能枚举 ✅
│   │   │   ├── skill_system.dart       # 技能系统（待实现）
│   │   │   └── generators/             # 各技能走法生成器（待实现）
│   │   ├── grid_system.dart            # 坐标系统（待实现）
│   │   ├── move_generator.dart         # 走法生成（待实现）
│   │   └── move_executor.dart          # 走子执行（待实现）
│   ├── models/                         # 数据模型
│   │   ├── board.dart                  # 棋盘模型 ✅
│   │   ├── piece.dart                  # 棋子模型 ✅
│   │   ├── skill.dart                  # 技能模型 ✅
│   │   ├── move.dart                   # 走法模型 ✅
│   │   ├── game_state.dart             # 游戏状态（待实现）
│   │   └── player.dart                 # 玩家抽象（待实现）
│   ├── ai/                             # AI 系统（待实现）
│   ├── controllers/                    # 业务控制器（待实现）
│   ├── providers/                      # 状态提供者（待实现）
│   ├── widgets/                        # UI 组件（待实现）
│   ├── animations/                     # 动画组件（待实现）
│   ├── screens/                        # 页面（待实现）
│   └── utils/                          # 工具类（待实现）
├── assets/                             # 资源文件
│   ├── images/                         # 图像资源 ✅
│   ├── audios/                         # 音频资源 ✅
│   └── fonts/                          # 字体文件 ✅
├── test/                               # 测试文件
└── pubspec.yaml                        # 项目配置 ✅
```

---

## 📋 开发进度

参见项目根目录的 `../todo.md` 文件。

### 当前状态

✅ **Phase 1: 项目初始化** - 已完成

- [x] 创建 Flutter 项目结构
- [x] 配置项目依赖
- [x] 设计目录结构
- [x] 配置多平台支持
- [x] 复制资源文件

🔄 **Phase 2: 核心游戏逻辑** - 进行中 (60%)

- [x] 常量定义和枚举
- [x] 技能类型枚举
- [x] 走法模型
- [x] 技能模型
- [x] 棋子类
- [x] 棋盘数据结构
- [ ] 技能走法生成器（7 个技能）
- [ ] 走法生成系统
- [ ] 游戏状态管理

⏳ **Phase 3-8** - 待开始

- Phase 3: UI 渲染层
- Phase 4: AI 系统
- Phase 5: 动画和音效
- Phase 6: 游戏流程
- Phase 7: 玩家系统
- Phase 8: 辅助功能

---

## 🛠️ 技术栈

### 核心框架

- **Flutter** 3.24.0+
- **Dart** 3.4.0+

### 依赖包

- `provider` ^6.1.2 - 状态管理
- `audioplayers` ^6.1.0 - 音频播放
- `shared_preferences` ^2.3.2 - 本地存储
- `path_provider` ^2.1.4 - 文件路径
- `equatable` ^2.0.5 - 值对象比较
- `logger` ^2.4.0 - 日志系统
- `flutter_screenutil` ^5.9.3 - 屏幕适配
- `google_fonts` ^6.2.1 - 字体管理

---

## 📝 代码规范

1. **每行代码都要写中文注释**（按用户要求）
2. 使用 `flutter_lints` 进行代码检查
3. 遵循 Dart 官方代码风格
4. 使用不可变数据结构（`@immutable`, `Equatable`）
5. 分离业务逻辑和 UI 层

---

## 🔗 相关链接

- [原 LÖVE2D 项目](../README.md)
- [开发 TODO](../todo.md)
- [Flutter 官方文档](https://flutter.dev)
- [Dart 语言指南](https://dart.dev/guides)

---

## 👥 贡献

本项目由 LÖVE2D 原项目改造而来，参考了原项目的所有 Lua 源文件。

### 源文件映射

| Lua 源文件                 | Dart 实现                          | 状态 |
| -------------------------- | ---------------------------------- | ---- |
| `src/game/constants.lua`   | `lib/core/constants.dart`          | ✅   |
| `src/skills/init.lua`      | `lib/core/skills/skill_types.dart` | ✅   |
| `src/game/Board.lua`       | `lib/models/board.dart`            | ✅   |
| `src/game/Piece.lua`       | `lib/models/piece.dart`            | ✅   |
| `src/skills/BaseSkill.lua` | `lib/models/skill.dart`            | ✅   |
| `src/game/MoveGen.lua`     | `lib/models/move.dart` (部分)      | 🔄   |
| `main.lua`                 | `lib/main.dart`                    | 🔄   |
| ...                        | ...                                | ⏳   |

---

## 📄 许可证

与原项目保持一致。

---

## 📧 联系

如有问题或建议，请参考原项目。

---

**最后更新**: 2025-10-24
**版本**: v0.1.0 (Alpha)
**状态**: 🚧 开发中
