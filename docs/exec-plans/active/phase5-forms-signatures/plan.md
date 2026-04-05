---
title: "Phase 5: 表单与签名"
description: PDF 表单填写/创建 + 电子签名/数字签名
status: draft
date: 2026-04-05
depends-on: [phase1-core-reader]
---

# Phase 5: 表单与签名

PDF 表单交互和签名功能，覆盖日常办公场景。

## 功能清单

### 表单填写
- [ ] 自动检测并渲染表单域
- [ ] 文本输入框
- [ ] 复选框 / 单选按钮
- [ ] 下拉选择
- [ ] 日期选择
- [ ] 列表框
- [ ] Tab 键在表单域间跳转

### 表单创建
- [ ] 插入文本输入框
- [ ] 插入复选框 / 单选按钮
- [ ] 插入下拉菜单
- [ ] 插入签名域
- [ ] 表单域属性编辑 (名称/默认值/必填/只读/格式验证)
- [ ] 表单域对齐 + 分布工具

### 表单数据
- [ ] 导入表单数据 (FDF / XFDF)
- [ ] 导出表单数据 (FDF / XFDF)
- [ ] 重置表单

### 电子签名
- [ ] 手写签名 (trackpad/鼠标绘制)
- [ ] 键入签名 (选择字体样式)
- [ ] 图片签名 (导入签名图片)
- [ ] 签名管理 (保存/删除常用签名)
- [ ] 放置签名到指定位置

### 数字签名
- [ ] PKCS#12 证书签名
- [ ] 签名验证 (显示签名状态)
- [ ] 签名时间戳

## 实施步骤

### Step 1: 表单填写
- PDFKit 表单域检测 (PDFAnnotation widget subtype)
- 表单域渲染 + 交互
- Tab 导航

### Step 2: 表单创建
- FormFieldCreator (拖拽放置表单域)
- 表单域属性面板
- 对齐 + 分布工具

### Step 3: 电子签名
- SignaturePadView (手写绘制)
- TypedSignatureView (键入 + 字体选择)
- SignatureManager (Keychain 存储)
- 签名放置 + 缩放

### Step 4: 数字签名 + 数据导入导出
- Security.framework 证书操作
- 签名验证 UI
- FDF/XFDF 解析 + 生成
