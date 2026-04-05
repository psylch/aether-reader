---
title: Apple Web Design System Reference
description: 从 apple.com 逆向提取的设计系统（色彩、排版、组件、布局），作为 Aether Reader 设计语言的基础参考
status: active
date: 2026-04-05
source: https://github.com/VoltAgent/awesome-design-md/tree/main/design-md/apple
---

# Apple Web 设计系统参考

> 来源：VoltAgent/awesome-design-md 从 apple.com 逆向提取的设计 token。
> 这不是 iOS 26 Liquid Glass 的原生 API 文档，而是 Apple 整体设计语言的 Web 端体现。
> 对 Aether Reader 的价值：色彩体系、排版规则、间距哲学、深度层级 — 这些跨平台通用。

## 1. 色彩体系

### 主色

| 名称 | 色值 | 用途 |
|------|------|------|
| Pure Black | `#000000` | 沉浸式背景 |
| Light Gray | `#f5f5f7` | 信息区背景（带微蓝灰调，避免苍白） |
| Near Black | `#1d1d1f` | 浅色背景上的主文本 |

### 交互色

| 名称 | 色值 | 用途 |
|------|------|------|
| Apple Blue | `#0071e3` | **唯一**强调色 — CTA、焦点环 |
| Link Blue | `#0066cc` | 浅色背景上的文字链接 |
| Bright Blue | `#2997ff` | 暗色背景上的链接 |

### 文本

| 色值 | 用途 |
|------|------|
| `#ffffff` | 暗色背景上的文本 |
| `#1d1d1f` | 浅色背景上的主文本 |
| `rgba(0,0,0,0.8)` | 次要文本 |
| `rgba(0,0,0,0.48)` | 第三级文本、禁用态 |

### 暗色表面

| 色值 | 层级 |
|------|------|
| `#272729` | Surface 1 |
| `#262628` | Surface 2 |
| `#28282a` | Surface 3 |
| `#2a2a2d` | Surface 4 |
| `#242426` | Surface 5 |

### 关键原则
- **单一强调色**：整个色彩预算只给蓝色
- **二元明暗节奏**：黑色沉浸区 ↔ 浅灰信息区交替，形成电影式节奏
- **阴影极度克制**：唯一阴影 `rgba(0,0,0,0.22) 3px 5px 30px` — 柔和、扩散、偏移

## 2. 排版规则

### 字体
- **Display (≥20px)**：SF Pro Display
- **Body (<20px)**：SF Pro Text
- 光学尺寸自动切换 — 大尺寸笔画更细、字距更宽，小尺寸更紧凑坚实

### 层级

| 角色 | 字号 | 字重 | 行高 | 字距 |
|------|------|------|------|------|
| Display Hero | 56px | 600 | 1.07 | -0.28px |
| Section Heading | 40px | 600 | 1.10 | normal |
| Tile Heading | 28px | 400 | 1.14 | 0.196px |
| Card Title | 21px | 700 | 1.19 | 0.231px |
| Body | 17px | 400 | 1.47 | -0.374px |
| Body Emphasis | 17px | 600 | 1.24 | -0.374px |
| Caption | 14px | 400 | 1.29 | -0.224px |
| Micro | 12px | 400 | 1.33 | -0.12px |

### 关键原则
- **所有尺寸都负字距** — Apple 的文本全局偏紧
- **极端行高范围** — 标题压到 1.07，正文放到 1.47，仅靠节奏就建立层级
- **字重克制** — 主要用 400 和 600，700 罕见，从不用 800/900

## 3. 组件样式

### 按钮

| 类型 | 背景 | 文本 | 圆角 | Padding |
|------|------|------|------|---------|
| Primary CTA | `#0071e3` | 白 | 8px | 8px 15px |
| Dark CTA | `#1d1d1f` | 白 | 8px | 8px 15px |
| Pill Link | 透明 | `#0066cc` | 980px | — |
| Filter | `#fafafc` | `rgba(0,0,0,0.8)` | 11px | 0 14px |
| Media Control | `rgba(210,210,215,0.64)` | `rgba(0,0,0,0.48)` | 50% | — |

### 导航
- 半透明暗色毛玻璃：`rgba(0,0,0,0.8)` + `backdrop-filter: saturate(180%) blur(20px)`
- 高度 48px，文本 12px 白色
- 悬浮于内容之上 — **玻璃效果是 Apple UI 的标志**

### 卡片
- 无边框（Apple 几乎不用可见边框）
- 圆角 5-8px
- 阴影仅用于提升卡片，且极度柔和

## 4. 间距与布局

### 间距系统
- 基础单位 8px
- 小尺寸密集 (2-11px 逐像素递增)，大尺寸跳跃
- 内部压缩（紧字距、紧行高）+ 外部留白（大段间距）

### 圆角系统

| 级别 | 圆角 | 用途 |
|------|------|------|
| Micro | 5px | 小容器、标签 |
| Standard | 8px | 按钮、卡片 |
| Comfortable | 11px | 搜索框、筛选按钮 |
| Large | 12px | 特色面板 |
| Pill | 980px | CTA 链接 |
| Circle | 50% | 媒体控件 |

## 5. 深度与高度

| 层级 | 效果 | 用途 |
|------|------|------|
| Flat (L0) | 无阴影 | 标准内容 |
| Nav Glass | `blur(20px)` + `saturate(180%)` | 导航栏 |
| Subtle Lift (L1) | `3px 5px 30px rgba(0,0,0,0.22)` | 产品卡片 |
| Focus | `2px solid #0071e3` | 键盘焦点 |

**阴影哲学**：模拟漫射影棚灯光下的自然阴影 — 偏移、宽模糊、低不透明度。大多数元素**不用**阴影，靠背景色对比暗示深度。

## 6. 对 Aether Reader 的适用性

### 直接适用
- **色彩体系**：Apple Blue 作唯一强调色、明暗交替节奏 → 阅读器的日间/暗色主题
- **排版规则**：SF Pro 的光学尺寸和紧字距 → SwiftUI 的 `.font(.system())` 天然继承
- **阴影克制**：PDF 阅读器不需要花哨阴影，Liquid Glass 本身提供深度
- **无边框卡片**：书库网格项、缩略图面板

### 需要适配
- **Web 圆角值** → iOS 原生组件有自己的圆角（如 Sheet 38pt），以系统为准
- **Web 导航毛玻璃** → iOS 26 的 Liquid Glass 取代，折射效果更强
- **980px pill** → iOS 上用 `.capsule` shape
- **响应式断点** → iOS 用 `horizontalSizeClass` / `verticalSizeClass`

### 不适用
- 产品展示模块（hero/grid/comparison）— 这是营销网站模式
- 按钮 padding 的精确像素值 — iOS 有自己的 Hit Target 规范 (44pt)
