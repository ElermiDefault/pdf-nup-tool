# API Draft

## POST /api/pdfs

上传 PDF，返回文件 ID 和页数。

## GET /api/pdfs/{file_id}/pages/{page_number}/thumbnail

返回指定页面缩略图。

查询参数：

- `width`: 缩略图目标宽度，默认 `240`，范围 `80-1200`

示例：

```bash
curl "http://127.0.0.1:8000/api/pdfs/{file_id}/pages/1/thumbnail?width=240" \
  -o page-1.png
```

## POST /api/pdfs/{file_id}/export

根据合并规则生成输出 PDF，响应体为 PDF 文件二进制内容。

请求示例：

```json
{
  "rules": [
    {
      "start_page": 3,
      "end_page": 10,
      "layout": 4
    }
  ],
  "page_size": "a4",
  "margin": 24,
  "gap": 12,
  "cell_padding": 6
}
```

当前支持：

- `layout`: `2`、`4`、`8`
- `page_size`: `"a4"`、`"a4-landscape"`、`"source"`，默认推荐 `"a4"`
- 合并页默认使用 A4；未合并页面保持原 PDF 页面尺寸和方向
- 合并时会保留源页面的可视方向；对带 PDF 旋转标记的页面，会按用户打开原 PDF 时看到的方向嵌入
- 页码使用前端显示页码，即从 `1` 开始
- 规则区间不能重叠

示例：

```bash
curl -X POST "http://127.0.0.1:8000/api/pdfs/{file_id}/export" \
  -H "Content-Type: application/json" \
  -o output.pdf \
  -d '{
    "rules": [
      {
        "start_page": 2,
        "end_page": 5,
        "layout": 4
      }
    ],
    "page_size": "a4",
    "margin": 24,
    "gap": 12,
    "cell_padding": 6
  }'
```
