---
title: iOS 26 Liquid Glass Design Language Research
description: iOS 26 液态玻璃设计语言的视觉原则、SwiftUI API、HIG 指南、关键组件变化和向后兼容性
status: active
date: 2026-04-05
---

# iOS 26 Liquid Glass 设计语言调研

## 1. 核心视觉原则

Liquid Glass 是 Apple 自 iOS 7 扁平化以来最重大的视觉重设计，覆盖所有 Apple 平台。

| 原则 | 描述 |
|------|------|
| **动态半透明** | UI 元素如物理玻璃板，折射并扭曲背后内容。远超传统 `UIBlurEffect` 的模糊效果 |
| **折射 + 高光** | 玻璃表面呈现边缘高光和镜面反射，响应设备陀螺仪和环境光 |
| **深度层级** | 系统定义明确的 z-level 深度层。不同层厚度的玻璃折射强度不同 |
| **环境色吸收** | 玻璃表面微妙地吸收下方内容的颜色，形成动态色调 |
| **边缘发光** | 玻璃元素边缘微微发光，模拟光线捕捉效果，替代传统边框/阴影 |
| **液态动画** | 状态转换使用物理驱动的流体动画，玻璃"融合"、"分离"、"流动" |

## 2. SwiftUI 新 API

### `.glassEffect()` — 主修饰器

```swift
// 基础用法
VStack {
    Text("Hello")
    Image(systemName: "star.fill")
}
.glassEffect()

// 参数化
.glassEffect(
    in: .rect(cornerRadius: 20),   // 玻璃形状
    displayMode: .always            // .always, .automatic, .never
)
```

`displayMode: .automatic` 让系统决定何时显示玻璃（如无内容滚动到下方时隐藏）。

### `.liquidGlass` 材质

新的 `ShapeStyle` 常量，可用于任何接受 ShapeStyle 的地方：

```swift
.background(.liquidGlass)
```

与旧版 `.ultraThinMaterial` / `.regularMaterial` 的区别：包含折射和高光渲染管线，不仅仅是模糊。

### 控件级适配

```swift
Button("Action") { }
    .buttonStyle(.glass)       // 新按钮样式

TabView {
    // Tab 自动获得 liquid glass 处理
}
```

### 自定义参数

```swift
.glassEffectTint(.blue)              // 给玻璃着色
.glassEffectIntensity(0.8)           // 折射强度 0...1
.glassEffectUnselectedStyle(.dimmed) // Tab bar 未选中项样式
```

### `GlassEffect` 容器

```swift
GlassEffect {
    Label("Wi-Fi", systemImage: "wifi")
}
```

### 自动适配的控件

- `Toggle` — 玻璃背景开关轨道
- `Slider` — 玻璃轨道
- `Picker(.menu)` — 玻璃下拉
- `ProgressView` — 玻璃轨道

## 3. HIG 设计指南

### 应该用玻璃的场景
- **系统 chrome 和导航**：Tab bar、Navigation bar、Toolbar、Sidebar（链接 iOS 26 SDK 后默认自动适配）
- **浮动面板**：底部 sheet、popover、浮动操作面板
- **控件组**：逻辑上成组的按钮或开关

### 不应该用玻璃的场景
- **内容区域**：文章、图片、视频等主内容不要用玻璃背景
- **过度叠层**：避免超过 2 层玻璃堆叠
- **小密集元素**：图标角标、微型指示器不适合玻璃效果

### 排版规则
- 玻璃表面上使用 **semibold 或 bold** 字重，regular 在动态背景上可读性差
- 系统字体已针对玻璃材质渲染调整了默认字重
- 文字自动获得 vibrancy 效果

### 无障碍
- **增强对比度**模式下，玻璃变得更不透明
- **减少透明度**模式下，玻璃回退为纯色微着色背景
- 开发者必须在两种设置下测试

### 间距
- 玻璃容器内部最少 12pt padding
- 相邻玻璃元素之间至少 8pt 间距

## 4. 关键 UI 组件变化

| 组件 | 变化 |
|------|------|
| **Tab Bar** | 变为底部浮动玻璃胶囊，选中项有不透明填充。iPad 上可变为顶部侧边栏玻璃元素 |
| **Navigation Bar** | 大标题导航栏有玻璃表面，随内容滚动淡入。顶部无内容时可隐藏 |
| **Toolbar** | 底部工具栏自动获得玻璃背景 |
| **Sheet** | `.sheet` 使用玻璃背景容器，圆角约 38pt |
| **Popover** | 玻璃背景 |
| **Sidebar (iPad)** | 玻璃面板，折射主内容区域 |
| **Widget** | 支持 `.glassEffect()` 融入动态壁纸 |

## 5. 向后兼容性

### 完整 Liquid Glass API 要求
- **iOS 26** (Xcode 26 SDK) 才可用
- iOS 18 及更早版本**不可用**

### 自动适配 vs 手动
- 链接 iOS 26 SDK 后，系统 chrome（tab bar, nav bar）在 iOS 26 设备上**自动**获得 Liquid Glass
- 旧版 iOS 上同一二进制回退到原有材质样式

### 旧版本近似方案

```swift
@ViewBuilder
func glassBackground() -> some View {
    if #available(iOS 26, *) {
        self.glassEffect()
    } else {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .white.opacity(0.2), radius: 0.5, y: -0.5)
    }
}
```

局限性：无实时折射、无陀螺仪高光、无边缘发光、无液态过渡动画。

### 平台可用性
- iOS 26, iPadOS 26, macOS 26 (Tahoe), watchOS 26, tvOS 26, visionOS 3
- Mac Catalyst 链接 macOS 26 SDK 自动获得
