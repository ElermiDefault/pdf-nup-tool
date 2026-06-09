# Architecture

## 核心流程

1. 前端加载 PDF，并用 PDF.js 渲染缩略图。
2. 用户选择一个或多个连续页段。
3. 用户为页段设置合并规则，例如 4 合 1。
4. 前端将规则提交给后端。
5. 后端用 PyMuPDF 重新排版生成输出 PDF。
6. 用户下载生成后的 PDF。

## 合并规则示例

```json
[
  {
    "start_page": 3,
    "end_page": 10,
    "layout": 4
  }
]
```

页码建议在前端显示为 1-based，后端内部处理时转换为 0-based。

