# 动膳 · MoveMenu

根据个人资料、每天的活动量和饮食限制，生成可替换的四餐菜单。iPhone 原生 SwiftUI 项目，iOS 26 使用 Liquid Glass 系统组件，兼容 iOS 17 及以上版本。

这是 **0.1.0 开发首版源码**。已提供 Xcode 工程、核心逻辑、界面、HealthKit 读取和测试；已通过 GitHub Actions 的 16 项核心测试和 Xcode 26.3 的 iOS Simulator 构建；尚未进行真机运行验证。不是可直接安装的 IPA，也未上架或进入 TestFlight。

## 首版包含

| 模块 | 行为 |
| --- | --- |
| 个人档案 | 年龄、公式性别参数、身高、体重、维持 / 温和减脂 / 支持增肌目标 |
| 饮食限制 | 均衡、蛋奶素、纯植物；9 类过敏原与逐项食材排除 |
| 每日运动 | 快走、慢跑、力量、瑜伽，按日期添加和删除；可填写全天活动热量 |
| Apple 健康 | 主动授权后读取活动热量、步数、运动分钟；再次点击同步更新 |
| 每日菜单 | 23 道示例菜谱组合成早餐、午餐、晚餐、加餐；克数、做法、估算营养 |
| 个性化 | 活动量改变份量；增肌目标优先筛选蛋白质能量占比较高的可用菜谱；同一天结果稳定，换餐仅影响指定餐次 |
| 界面 | 今日菜单 / 运动 / 我的；原生导航与玻璃按钮；动态字体、深色模式、减少动态效果兼容 |
| 本地数据 | 原子写入、iOS 文件保护、按本地日历分日；可删除全部记录；不上传或进入 iCloud 备份 |

## 在 Mac 上运行

1. 安装 **Xcode 26 或更新版本**，打开 `MoveMenu.xcodeproj`。工程已生成，无需 CocoaPods、XcodeGen 或第三方 SDK。
2. 选择 `MoveMenu` scheme 和 iPhone 模拟器，点击 Run。首次启动需要确认或修改示例资料。
3. 安装到真机时，在 Signing & Capabilities 中选择自己的开发团队，修改为可用的 Bundle Identifier，并让签名配置包含 HealthKit capability。
4. 在 iOS 26 设备查看 Liquid Glass；iOS 17 / 18 使用普通原生按钮兼容样式。需要用 iOS 26 SDK 编译，即使运行目标是旧系统。
5. 如 Apple 健康没有记录或不授权，切换到“按运动估算”或“手动填活动热量”。

```bash
swift test
xcodebuild -project MoveMenu.xcodeproj -scheme MoveMenu \
  -sdk iphonesimulator -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Swift Package 只包含独立核心层，可在 Swift 6 工具链执行 16 个测试方法；其中一项遍历全部 512 种过敏原组合。iOS 层由 Xcode 单独编译。

## 仓库与验证

仓库：[gptcookman7-maker/movemeun](https://github.com/gptcookman7-maker/movemeun)。应用名称为 MoveMenu / 动膳，仓库路径沿用现有拼写。

2026-09-06 修复了 Xcode 工程的序列化类型：XML 数字字段会让 Xcode 在加载工程时触发 `archiveObjectVersionString ... NSString` 断言。工程现已使用原生 OpenStep 表示，保留全部 Target、文件引用和构建设置。

[已通过的构建与测试](https://github.com/gptcookman7-maker/movemeun/actions/runs/34010434206)：16 项核心测试、0 失败；iOS Simulator 构建成功。完整说明见 `docs/VALIDATION.md`。请重新拉取 main 或下载最新源码，旧 ZIP 不包含此修复。

## 目录

| 路径 | 用途 |
| --- | --- |
| `MoveMenu/Core` | 资料模型、运动净消耗、菜单规则、23 道菜谱及 30 种食材 |
| `MoveMenu/Services` | HealthKit 只读接入、本地状态存储 |
| `MoveMenu/Views` | 三个主页面、档案编辑、食材与做法详情、原生玻璃按钮 |
| `MoveMenu/Resources` | 权限说明、HealthKit entitlement、隐私清单 |
| `MoveMenu.xcodeproj` | 可直接打开的 iOS 工程与共享 scheme |
| `Tests` | 核心逻辑测试，无网络依赖 |
| `.github/workflows/ci.yml` | Swift 测试和 iOS Simulator 构建配置，推送后执行 |
| `docs/PRODUCT.md` | 产品边界、后续里程碑、验收流程 |
| `docs/NUTRITION.md` | 算法口径、估算假设及参考来源 |

## 发布前还需要

真实设备上的编译、Liquid Glass 与辅助功能验收；HealthKit 授权、拒绝和多数据源验证；正式 App 图标；营养师审核与食材数据库授权校核；Apple 签名、隐私政策及 TestFlight 配置。

本版无云账号、后台自动同步、推送、实际摄入日志或付费功能。修改档案会按新资料重新估算过去日期的菜单，不能当作历史实际饮食记录。数据保留在当前设备，删除应用或换机可能丢失。

## 手机交互预览

[打开动膳交互预览](https://movemenu-preview.gptcookman7.chatgpt.site)

可调整运动量、换餐、设置饮食偏好和切换深色模式。这是网页设计与交互预览，玻璃材质由 CSS 模拟，不是原生 iOS 运行截图；Apple 健康同步与原生 Liquid Glass 仍需真机验收。
