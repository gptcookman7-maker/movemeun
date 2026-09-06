# 构建与测试验证

验证日期：2026-09-06。验证源码提交：`65b52dd7387072f500892b9d73838c9680b20c69`。

[GitHub Actions 完整记录](https://github.com/gptcookman7-maker/movemeun/actions/runs/34010434206)

| 项目 | 结果 |
| --- | --- |
| 菜单核心测试 | 16 项通过，0 失败；包括全部 512 种过敏原组合 |
| iOS Simulator 构建 | Xcode 26.3、iOS Simulator 26.2 SDK，Debug、关闭签名，BUILD SUCCEEDED |
| 项目载入 | 修复 OpenStep 序列化后可正常加载，未再触发 NSString 类型断言 |
| 编译日志 | 无编译错误；存在未使用 AppIntents 的元数据提取提示，不影响构建 |
| 真机运行 | 尚未执行 |
| Apple 健康授权与实际同步 | 仍需真机验收 |
| Liquid Glass 原生渲染 | 仍需模拟器 / 真机运行验收，编译通过不等于视觉验收 |
| 网页交互预览 | 独立设计预览，使用同一菜谱数据与对应规则；不读取 Apple 健康，不是原生截图 |

## 本次修复

旧 project.pbxproj 将 Xcode 工程标量保存为 XML integer。Xcode 工程读取器要求对象版本等字段为字符串，因此在编译前就发生崩溃，并输出大量调用栈。

本次将工程转换为 Xcode 原生 OpenStep 格式，保留 42 个工程对象及原有标识和源文件关系，没有绕过测试、删除功能或降低 SDK 要求。

预览规则另已检查：运动影响能量、只替换选中餐次、纯植物与大豆排除、非法数据和专业方案阻断，以及 512 种过敏原组合。网页材质是 CSS 模拟，数据仅保留于当前页面内存。
