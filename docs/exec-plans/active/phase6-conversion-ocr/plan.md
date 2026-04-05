---
title: "Phase 6: 格式转换与 OCR"
description: PDF 双向格式转换 + 批量处理 + OCR 文字识别
status: draft
date: 2026-04-05
depends-on: [phase1-core-reader]
---

# Phase 6: 格式转换与 OCR

格式转换和 OCR 放在一起：OCR 是「扫描件 → 可编辑」的前置步骤，两者技术栈重叠。

## 技术方案

### OCR
- **Vision framework** (VNRecognizeTextRequest) — 系统自带，零依赖，支持多语言

### 转换
- **PDF → 图片**: PDFKit 原生渲染
- **PDF → TXT**: PDFPage.string
- **PDF → Word/RTF**: 自研布局解析 (文本块 + 样式 → docx XML)
- **PDF → Excel**: 表格检测 (Vision + 启发式规则) → xlsx
- **PDF → PPT**: 按页渲染为幻灯片 + 文本层
- **PDF → HTML**: 文本块 + 样式 → HTML + CSS
- **文档 → PDF**: NSWorkspace 调用系统打印 → PDF

## 功能清单

### OCR 文字识别
- [ ] 扫描 PDF → 可搜索 PDF (全文档 OCR)
- [ ] 区域 OCR (框选区域 → 提取文字)
- [ ] 多语言支持 (Vision 内置: 中/英/日/韩/法/德/西 等)
- [ ] OCR 后可编辑 (文本层叠加)
- [ ] OCR 准确率预览 + 手动校正

### PDF 导出
- [ ] PDF → Word (.docx)
- [ ] PDF → Excel (.xlsx)
- [ ] PDF → PowerPoint (.pptx)
- [ ] PDF → 图片 (JPG / PNG / TIFF, 可选 DPI)
- [ ] PDF → TXT (纯文本)
- [ ] PDF → RTF
- [ ] PDF → HTML

### 导入为 PDF
- [ ] Word → PDF
- [ ] Excel → PDF
- [ ] PPT → PDF
- [ ] 图片 → PDF (JPG/PNG/HEIC/WebP/SVG/BMP)
- [ ] TXT → PDF
- [ ] Markdown → PDF
- [ ] 网页 → PDF (WebKit 渲染)

### 批量处理
- [ ] 批量导出 (多文件 + 统一格式)
- [ ] 批量导入转 PDF
- [ ] 批量 OCR
- [ ] 进度指示 + 后台处理

## 实施步骤

### Step 1: OCR
- VisionOCRService (Vision framework 封装)
- 全文档 OCR → 可搜索 PDF (添加不可见文本层)
- 区域 OCR (框选 → 文字提取 → 剪贴板)
- OCR 结果预览

### Step 2: 基础导出
- PDF → 图片 (PDFKit 渲染)
- PDF → TXT (PDFPage.string)
- PDF → RTF
- 导出设置面板 (页面范围/DPI/质量)

### Step 3: Office 格式导出
- PDFLayoutAnalyzer (文本块/图片/表格检测)
- DocxWriter (文本 + 样式 → .docx)
- XlsxWriter (表格数据 → .xlsx)
- PptxWriter (页面 → 幻灯片)
- HtmlWriter (文本 + CSS)

### Step 4: 导入 + 批量
- 文档 → PDF (系统打印子系统)
- 图片 → PDF (CGImage → PDFPage)
- Markdown → PDF (AttributedString → PDFPage)
- BatchConversionView (批量处理 UI + 并发队列)
