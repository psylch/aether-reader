---
title: "Phase 7: 安全、测量与 AI"
description: 密码保护/密文涂黑 + 测量工具 + Foundation Models AI 功能
status: draft
date: 2026-04-05
depends-on: [phase1-core-reader]
---

# Phase 7: 安全、测量与 AI

三个独立子模块，打包为一个 Phase 因为各自体量较小。内部无互相依赖，可按任意顺序实现。

---

## A. 安全

### 功能清单
- [ ] 设置打开密码 (User Password)
- [ ] 设置权限密码 (Owner Password — 限制打印/复制/编辑)
- [ ] 加密级别选择 (AES-128 / AES-256)
- [ ] 解锁/移除密码保护
- [ ] 密文涂黑 (Redaction — 标记 → 预览 → 永久应用)

### 技术方案
- PDFKit 密码 API: `PDFDocument.unlock(withPassword:)`, `PDFDocument.write(withOptions:)` 设置加密
- Redaction: 先标记区域 (红色矩形预览) → 确认后用白色矩形覆盖 + 删除底层文本内容

### 实施步骤
1. PasswordSettingsView (设置/修改/移除密码)
2. 加密写入 (PDFDocument write options)
3. RedactionTool (标记 → 预览 → 应用)

---

## B. 测量工具

### 功能清单
- [ ] 距离测量 (两点间)
- [ ] 面积测量 (多边形)
- [ ] 周长测量 (多边形)
- [ ] 角度测量 (三点定角)
- [ ] 比例校准 (设置已知距离 → 自动换算)
- [ ] 测量单位切换 (mm / cm / in / pt)

### 技术方案
- 覆盖层绘制测量图形 (Core Graphics)
- 坐标系: PDF 坐标 (72pt/inch) → 用户设定比例换算

### 实施步骤
1. MeasurementOverlay (绘制层 + 坐标捕获)
2. CalibrationView (比例校准: 画一段已知距离)
3. 距离/面积/周长/角度计算 + 标注显示
4. 测量结果面板 (列表 + 导出)

---

## C. AI 功能

### 功能清单
- [ ] 文档摘要 (选中内容 / 全文)
- [ ] 智能问答 (基于文档内容 RAG)
- [ ] 翻译 (选中文本 / 全文 — 侧边栏对照)
- [ ] 解释 (选中复杂段落 → 简化解释)
- [ ] 改写 (简化 / 正式化 / 扩展)

### 技术方案
- **本地优先**: macOS 26 Foundation Models 框架 (on-device LLM)
- **可选云端**: 用户配置 API key 后可调用 Claude / GPT 等
- **RAG**: PDF 文本分块 → 本地向量化 (NLEmbedding) → 相似度检索 → LLM 生成

### 实施步骤
1. AIService (Foundation Models 封装 + 可选云端 fallback)
2. 选中文本右键菜单 (摘要/翻译/解释/改写)
3. AI 侧边栏面板 (问答对话 + 结果展示)
4. 全文摘要 + 翻译 (后台处理 + 流式输出)
