---
title: "Phase 4: 内容编辑"
description: PDF 文本直接编辑、图片编辑 — 类 Word 的 PDF 编辑体验
status: draft
date: 2026-04-05
depends-on: [phase1-core-reader]
---

# Phase 4: 内容编辑

直接编辑 PDF 内容（文本 + 图片），让用户无需转换即可修改 PDF。

## 技术难点

PDFKit 没有原生的文本编辑 API。需要：
1. 解析 PDF content stream 定位文本对象
2. 覆盖一层可编辑的 SwiftUI/AppKit 文本框
3. 修改后写回 PDF content stream

备选方案：使用 Core Graphics 直接操作 PDF content stream (CGPDFDocument → 解析 → 修改 → 重写)。

## 功能清单

### 文本编辑
- [ ] 进入编辑模式 (点击文本区域 → 可编辑)
- [ ] 修改文本内容
- [ ] 修改字体 / 字号 / 颜色
- [ ] 加粗 / 斜体 / 下划线
- [ ] 文本对齐 (左/中/右)
- [ ] 查找和替换
- [ ] 拼写检查 (NSSpellChecker)

### 图片编辑
- [ ] 插入图片 (从文件 / 从剪贴板)
- [ ] 替换图片
- [ ] 删除图片
- [ ] 调整大小 (拖拽手柄)
- [ ] 旋转图片
- [ ] 移动图片 (拖放)
- [ ] 裁剪图片

## 实施步骤

### Step 1: PDF 内容解析
- PDFContentParser (解析 content stream, 定位文本/图片对象)
- 文本区域检测 + 边界框计算
- 图片对象检测 + 提取

### Step 2: 文本编辑
- EditableTextOverlay (覆盖在 PDFView 上的可编辑层)
- 字体/颜色/样式工具栏
- PDFContentWriter (修改后写回 content stream)
- 查找和替换 UI

### Step 3: 图片编辑
- 图片选中 + 手柄显示
- 插入/替换/删除操作
- 拖拽调整大小/位置/旋转
