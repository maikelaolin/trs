# Mindustry 基础框架落地与二次开发指南

| 项目 | 内容 |
|---|---|
| 文档名称 | 以 Mindustry 为基础框架的落地与二次开发指南 |
| 基础框架 | Anuken/Mindustry v160.7（Java / GPL-3.0） |
| 目标游戏 | 即时战斗 + 建筑产金 + 制造军队 + 对外战争 |
| 本地路径规划 | `E:/codex/chuanqi/engine/mindustry`（框架源码） |
| 文档版本 | v1.0（2026-10-25） |

---

## 目录

1. 落地总览
2. 环境搭建
3. 获取框架源码
4. 构建与运行
5. 二次开发三条路线与推荐
6. Mod 开发详解
7. 玩法改造映射：从 Mindustry 到本项目
8. 服务器部署
9. 开源协议合规（必读）
10. 常见问题
11. 下一步行动清单

---

## 1. 落地总览

```
本项目 (chuanqi)
├── engine/mindustry/      # 基础框架（Mindustry 源码，git 管理）
├── mods/chuanqi/          # 本项目游戏内容（HJSON 配置 + JS 脚本）
├── docs/                  # 文档
└── server/                # 服务端部署（jar + 配置 + 地图）
```

核心策略：**Mindustry 提供引擎层（渲染、网络、物理、寻路、实体系统、UI 框架、模组加载器），本项目通过 Mod 提供全部游戏内容（建筑、兵种、科技树、地图、规则），必要时以 Fork 补丁方式修改引擎层**。

Mindustry 已经原生具备的、直接可复用的能力：

| 能力 | Mindustry 原生机制 |
|---|---|
| 建筑建造 | 网格放置、建造动画、升级、拆除、蓝图（schematic） |
| 资源产出 | 钻头采矿、工厂加工（配方制）、传送带物流、电力网 |
| 制造军队 | 单位工厂（地面/空中/海军）按配方生产单位 |
| 即时战斗 | 自动索敌、弹道/激光/导弹、伤害与状态效果 |
| 对外战争 | 战役扇区（Sector）进攻、PvP、敌人波次（Waves） |
| 多人联机 | 服务器权威 + ArcNet（TCP/UDP）、断线重连、管理指令 |
| 跨平台 | Windows / macOS / Linux / Android / iOS / 专用服务器 |
| 数据驱动 | HJSON 内容定义 + 科技树 + 本地化 bundles |

---

## 2. 环境搭建

### 2.1 JDK 17（必须，其他版本不行）

官方 README 明确要求：**JDK 17，其他 JDK 版本将无法工作**。

- 下载：Eclipse Temurin 17（https://adoptium.net/temurin/releases/?os=any&arch=any&version=17）
- 国内镜像：清华大学开源软件镜像站 `https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/windows/`
- 本机规划安装路径：`E:/codex/tools/jdk-17`
- 验证：
  ```bash
  export JAVA_HOME="/e/codex/tools/jdk-17"
  "$JAVA_HOME/bin/java" -version
  # 应输出 openjdk version "17.x"
  ```

### 2.2 Gradle（无需单独安装）

仓库自带 Gradle Wrapper（`gradlew` / `gradlew.bat`），首次执行时自动下载匹配的 Gradle 发行版（需能访问 services.gradle.org）。

### 2.3 Android SDK（仅打包安卓端需要）

- 下载 "Command line tools only"（https://developer.android.com/studio#command-tools）
- 解压后把内容放进 `cmdline-tools/latest/`，执行 `sdkmanager --licenses`
- 设置环境变量 `ANDROID_HOME` 指向 SDK 目录
- 桌面端与服务端开发**不需要** Android SDK

### 2.4 推荐开发工具

- **IntelliJ IDEA**（Community 版即可，Gradle 项目原生支持）
- VS Code + Mindustry HJSON 扩展（写 HJSON 内容时有补全和字段校验）

---

## 3. 获取框架源码

### 3.1 标准方式（网络正常时）

```bash
git clone --depth 1 https://github.com/Anuken/Mindustry.git E:/codex/chuanqi/engine/mindustry
cd E:/codex/chuanqi/engine/mindustry
git remote add upstream https://github.com/Anuken/Mindustry.git   # 便于后续同步上游
```

### 3.2 网络受限时（本机实际采用的方式）

本机测试结果：`api.github.com` 与 `codeload.github.com` 可通，但 `github.com` 的 git smart-HTTP 协议被代理阻断（`git clone` 报 schannel SSL 握手失败）。解决方案：下载官方 tarball 后本地初始化 git：

```bash
# 下载源码包（约 300MB）
curl -L -o mindustry.tar.gz https://codeload.github.com/Anuken/Mindustry/tar.gz/refs/heads/master
# 解压（tar 内顶层目录为 Mindustry-master/）
tar -xzf mindustry.tar.gz
mv Mindustry-mindustry/* E:/codex/chuanqi/engine/mindustry/
cd E:/codex/chuanqi/engine/mindustry
git init && git add -A && git commit -m "vendor: Mindustry v160.7 upstream snapshot"
```

后续同步上游：重新下载新版本 tarball，用 `git diff` 对比差异后再合并。

### 3.3 不想编译时（快速体验/验证）

- 官方每提交自动构建 bleeding-edge 版本：https://github.com/Anuken/MindustryBuilds/releases
- 正式版 jar 内含专用服务器（Releases 页面），解压即用

---

## 4. 构建与运行

在 `engine/mindustry` 目录下执行（Windows 用 `gradlew.bat`，Linux/macOS 先 `chmod +x ./gradlew`）：

| 目的 | 命令 | 产物 |
|---|---|---|
| 运行桌面版（开发调试） | `gradlew desktop:run` | — |
| 打包桌面版 | `gradlew desktop:dist` | `desktop/build/libs/Mindustry.jar` |
| 打包专用服务器 | `gradlew server:dist` | `server/build/libs/server-release.jar` |
| 打包安卓 APK | `gradlew android:assembleDebug` | `android/build/outputs/apk/*.apk` |
| 重新打包贴图图集 | `gradlew tools:pack` | — |

注意事项：
- 首次构建 Gradle 需下载依赖（Gradle 发行版 + libGDX/Arc 等），**可能需要几分钟，请耐心等待**。
- `core/src/mindustry/gen` 是构建时生成的代码，不要手动编辑。
- 编译前确保 `java -version` 是 17，否则会报奇怪的编译错误。

### 4.1 加载自己的 Mod

构建/运行后，把 mod 目录放入对应平台的 mods 文件夹：

| 平台 | 路径 |
|---|---|
| Windows | `%appdata%/Mindustry/mods/` |
| Linux | `~/.local/share/Mindustry/mods/` |
| macOS | `~/Library/Application Support/Mindustry/mods/` |
| Steam | `steam/steamapps/common/Mindustry/saves/mods/` |
| Android | `/storage/emulated/0/Android/data/io.anuke.mindustry/files/mods` |

开发期也可以在项目内直接引用（见 6.7）。

---

## 5. 二次开发三条路线与推荐

| 路线 | 做法 | 优点 | 缺点 | 适用 |
|---|---|---|---|---|
| **A. 纯 Mod** | 不改源码，全部内容走 mod（HJSON + JS） | 可随时升级上游版本；GPL 传染面最小；内容与引擎分离 | 深度玩法逻辑（新 UI、新游戏循环）受限 | 内容量调整、数值重构、换皮 |
| **B. Fork 源码** | 直接改 `core/src/mindustry` | 无所不能 | 与上游同步困难；分发时全部修改须 GPL 开源 | 引擎级改造 |
| **C. 混合（推荐）** | 引擎打"最小补丁"Fork + 内容走 Mod | 平衡灵活与可维护 | 需要工程纪律（补丁要小且记录） | 正式项目 |

**推荐工作流**：
1. 内容（建筑/兵种/子弹/科技树/地图/本地化）→ 全部放 `mods/chuanqi/`；
2. 引擎行为（如把"核心被摧毁即失败"改成"主城耐久度"、新增战争结算 UI）→ 在 Fork 里打**小而集中的补丁**，每个补丁独立提交，注明修改原因，便于未来 rebase 上游；
3. 每季度尝试同步一次上游版本，用 `git diff` 审查冲突。

---

## 6. Mod 开发详解

### 6.1 mod.hjson（元数据，必须）

位于 mod 根目录，HJSON 格式：

```hjson
name: "chuanqi"                    // 小写连字符命名，游戏内引用用
displayName: "传奇·战争"
author: chuanqi-team
description: "建造建筑获取金币，制造军队，对外战争。"
version: "1.0"
minGameVersion: "160.7"            // 必填，>136 的数字
dependencies: [ ]
hidden: false                      // 创建了内容就不能设 true
```

### 6.2 Mod 目录结构

```
chuanqi/
├── mod.hjson
├── content/
│   ├── items/        # 物品（金币、粮食、铁矿……）
│   ├── blocks/       # 建筑（金矿、兵营、城墙、炮塔……）
│   ├── liquids/      # 液体
│   ├── units/        # 兵种（步兵、弓手、骑兵……）
│   ├── weather/      # 天气
│   └── ...
├── maps/             # 地图
├── bundles/          # 本地化 bundle_zh_CN.properties
├── sounds/           # ogg/mp3
├── schematics/       # 蓝图
├── scripts/          # JavaScript 脚本（Rhino）
├── sprites-override/ # 覆盖原版贴图
└── sprites/          # 自有贴图
```

**文件命名规则**：全部小写 + 连字符（`gold-mine.json`，不能 `Gold Mine.json`）。文件名词干就是游戏内该内容的 ID。

### 6.3 用 HJSON 定义内容

任何内容的 JSON 第一行用 `type` 指定类型，之后是该类型的字段（字段区分大小写）：

```hjson
// content/items/gold.hjson
type: item
name: 金币
description: 战争机器的血液。
```

```hjson
// content/blocks/gold-mine.hjson —— 建筑：持续产出金币
type: GenericCrafter        // 通用制造机（按配方生产）
health: 120
size: 2
update: true
hasItems: true
craftTime: 60
outputItem: { item: gold, amount: 1 }   // 每 60 tick 产出 1 金币
consumes: { power: 0.5 }                // 消耗电力
requirements: [ gold/10 ]
category: crafting
research: core-shard        // 科技树父节点（放在 core-shard 之后）
researchCostMultiplier: 0.5
```

```hjson
// content/units/infantry.hjson —— 兵种
type: mech
name: 步兵
health: 100
speed: 0.4
armor: 2
weapons: [
  { name: spear, x: 0, y: 0, shootY: 3,
    bullet: { type: BasicBulletType, damage: 12, speed: 3, lifetime: 30 } }
]
requirements: [ gold/30 ]
```

### 6.4 HJSON 格式要点

- 支持注释（`#`、`//`、`/* */`）、无引号字符串、多行字符串、数组免逗号。
- 任何合法 JSON 都合法；反过来不成立（别用标准 JSON 解析器处理 HJSON）。
- 本地化优先：`name`/`description` 可不写在内容文件里，放 bundles：
  ```properties
  # bundles/bundle_zh_CN.properties
  block.chuanqi-gold-mine.name = 金矿
  block.chuanqi-gold-mine.description = 源源不断产出金币。
  item.chuanqi-gold.name = 金币
  ```

### 6.5 科技树（research）

```hjson
research: duo                       // 放在原版 duo 之后解锁
research: { parent: duo, requirements: [ copper/100 ] }   // 自定义父节点与研究消耗
```

研究成本自动计算：blocks = `60 * multiplier + requirements^1.11 * 20 * multiplier`；units = `requirements * multiplier`（UnitType 默认 50）。

### 6.6 贴图规范

- 尺寸 = `32 × size`（2×2 建筑 → 64×64 PNG）。
- 必须 **32 位 RGBA** PNG，否则游戏崩溃（Pixmap decode error）。
- 放 `sprites/`（按名称查找），炮塔会找 `<name>-heat` 等后缀；炮塔贴图四周留透明边（游戏会加深色边框）。
- 覆盖原版贴图放 `sprites-override/`。

### 6.7 JavaScript 脚本（轻量逻辑）

`scripts/main.js` 用 Rhino 引擎执行，可访问游戏 API（`Vars.content`、`print()`、事件钩子），适合：
- 注册自定义 UI 按钮/热键
- 定时事件（如整点刷 NPC 攻城）
- 内容动态生成与改字段

纹理包、纯 JS 插件类 mod 的 `hidden` 应设 `true`（避免联机版本校验冲突）；创建了内容的 mod 不能 hidden。

### 6.8 Java 插件（JVM Mod，深度逻辑）

需要修改引擎行为时，写 Java mod（jar），可覆写 `ApplicationListener`、注册自定义 `Block`/`UnitType` 子类、劫持 UI。适用于：
- 新的游戏循环（如把胜利条件从"核心存活"改为"主城耐久 + 金币掠夺结算"）
- 对外战争的匹配/结算前后端逻辑

> 官方 Wiki 有完整 Modding Classes API 索引（Ability / Block / BulletType / Draw / Weapon / UnitType 等），地址：https://mindustrygame.github.io/docs/ （Javadoc）。

---

## 7. 玩法改造映射：从 Mindustry 到本项目

Mindustry 原版循环是"自动化生产 + 防守波次"，本项目要的是"建筑产金 + 造兵 + 对外战争"。改造映射如下：

| 本项目需求 | Mindustry 机制 | 改造动作 |
|---|---|---|
| 建造建筑获取金钱 | Item（铜/铅…）+ GenericCrafter | 重命名/重定义核心物品为"金币"；新增金币产出建筑链（金矿→炼金厂→金库） |
| 制造军队 | 单位工厂（Ground/Air Factory） | 新增三类军营（步兵营/弓手营/骑兵营），各自 recipe；兵种定义见 6.3 |
| 即时战斗 | 自动索敌 + 武器系统 | 保留原生即时战斗；通过 JS 脚本把"玩家框选编队出征"做成主循环 |
| 对外战争 | Sector 战役 / PvP | 用 Java 插件实现"匹配→实时战斗房间→掠夺结算"；先做异步战报（服务端模拟），再升级实时 |
| 主城/基地 | Core（核心） | 用 Java 插件把 Core 改为"主城"：有耐久度、被摧毁判定胜负、提供初始金币 |
| 人口上限 | 单位数量软限制 | 新增"民居"建筑提供人口上限，超限禁止生产 |
| 离线收益 | 无（原版无挂机产出） | Java 插件 + 服务端定时任务按建筑产出结算离线金币 |

**分阶段改造建议**：

1. **第 1 阶段（纯 Mod）**：换内容——金币物品、金矿/军营/民居建筑、三个兵种、科技树、中文 bundles。此阶段即可玩到"建矿产金→造兵"的循环。
2. **第 2 阶段（JS 脚本）**：加规则——NPC 定时攻城波次、编队出征指令、简单掠夺结算。
3. **第 3 阶段（Java 插件/Fork）**：改循环——主城耐久度、实时 PvP 匹配与房间、离线收益结算、反外怪校验。

---

## 8. 服务器部署

### 8.1 构建与运行

```bash
cd engine/mindustry
gradlew server:dist                      # 产出 server/build/libs/server-release.jar
java -jar server/build/libs/server-release.jar
```

服务器为无头模式（headless），通过控制台指令管理（`Administration.java` 提供玩家管理、封禁、存档等指令）。

### 8.2 服务器放 Mod

把 `mods/chuanqi/` 放入服务器工作目录的 `mods/` 文件夹（或配置 `--mod` 参数），启动时自动加载。联机时客户端需装同一 mod（内容型 mod 会做版本校验，见 `hidden` 字段说明）。

### 8.3 网络模型

Mindustry 联机为**服务器权威**：客户端上报指令、服务端运行世界逻辑并广播快照。做"对外战争"时：
- 简单方案：直接复用内置多人房间（开房间 → 双方进场 → 打），掠夺结算由插件在战斗结束时读写数据库。
- 进阶方案：自研匹配服 + 多个 Mindustry 专用服务器进程，房间制横向扩容。

---

## 9. 开源协议合规（必读）

Mindustry 采用 **GPL-3.0**：

1. **允许**：自由使用、修改、再分发（包括商业发行）。
2. **义务**：一旦向他人分发你的修改版（可执行文件也算分发），**必须以 GPL-3.0 提供完整对应源代码**，包括你对引擎的修改。
3. **SaaS 场景**：仅提供网络服务不分发软件时，GPL-3.0 不触发开源义务（这点与 AGPL 不同）。
4. **资产版权**：Mindustry 的代码是 GPL，但其美术/音频资源版权归作者所有，**重新分发时需保留原作者的署名与许可声明**；自有内容不要直接拷贝其素材商用，应自制或使用 CC0 素材。
5. **实务建议**：
   - 客户端 exe/jar 若要上架 Steam/移动端商店，随包附带开源声明与源码获取方式（如 GitHub 仓库链接）；
   - `mods/chuanqi/` 自有代码建议同步开源（既然整体必须开源，开源还能换取社区生态）；
   - 修改引擎时保持补丁干净、注释清晰，方便对外发布源代码时通过审查。

---

## 10. 常见问题

| 问题 | 原因与解决 |
|---|---|
| 编译报莫名错误 | JDK 版本不是 17。`java -version` 确认，或设 `JAVA_HOME`。 |
| `Permission denied`（Linux/mac） | `chmod +x ./gradlew`（一次性） |
| 贴图相关崩溃 "Pixmap decode error" | PNG 不是 32 位 RGBA，用图像工具重新导出 |
| 内容名无效/找不到 | 文件名必须小写连字符；`type` 字段拼写；字段大小写敏感（`hitSize`≠`hitsize`） |
| 联机时 mod 版本不匹配 | 内容型 mod 不能 `hidden: true`；双方 mod 版本一致 |
| NullPointerException | 内容定义缺少必填字段，对照原版同类型内容补全 |
| 单位不走/不攻击 | 检查 `aiController`、`targetAir`/`targetGround`、武器 `x/y` 坐标 |
| 构建极慢 | 首次下载依赖属正常；可配置国内 Maven 镜像加速 |
| git clone 失败（schannel SSL） | 见 3.2：改用 codeload tarball 下载 |
| tick 概念 | 1 tick = 1/60 秒；tilesize 内部为 8 世界单位；射程 = lifetime × speed |

---

## 11. 下一步行动清单

- [ ] 安装 JDK 17 并配置 `JAVA_HOME`
- [ ] 获取框架源码到 `engine/mindustry`（git clone 或 tarball）
- [ ] `gradlew desktop:dist` 跑通首次构建（验证环境）
- [ ] `gradlew desktop:run` 启动原版游戏，熟悉操作与机制
- [ ] 创建 `mods/chuanqi/` 骨架：mod.hjson + 金币物品 + 金矿建筑 + 步兵单位
- [ ] 进入游戏加载 mod，验证内容显示与生产链
- [ ] 按第 7 章三阶段路线推进改造

---

## 附：关键参考

- 仓库：https://github.com/Anuken/Mindustry
- 官方构建（免编译）：https://github.com/Anuken/MindustryBuilds/releases
- Javadoc API：https://mindustrygame.github.io/docs/
- Modding Wiki：https://mindustrygame.github.io/wiki/modding/1-modding/
- 脚本（JS）开发：https://mindustrygame.github.io/wiki/modding/3-scripting/
- Java/JVM Mod：https://mindustrygame.github.io/wiki/modding/2-plugins/
- 贴图规范：https://mindustrygame.github.io/wiki/modding/4-spriting/

*本文档中的命令、字段与路径均来自官方 README 与 Wiki（2026-10-25 核实），版本升级后请以仓库最新文档为准。*
