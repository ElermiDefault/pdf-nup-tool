# Backend

FastAPI 后端负责：

- 接收 PDF 上传
- 读取 PDF 页数和基础信息
- 根据前端提交的合并规则生成输出 PDF
- 返回生成后的 PDF 文件
- 在 `frontend/dist` 存在时托管前端静态页面

## 启动方式

```bash
source .venv/bin/activate
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8010 --reload
```

默认服务地址：

```text
http://127.0.0.1:8010
```

## 当前接口

- `GET /health`：健康检查
- `POST /api/pdfs`：上传 PDF，字段名为 `file`
- `GET /api/pdfs/{file_id}`：读取 PDF 基础信息
- `GET /api/pdfs/{file_id}/pages/{page_number}/thumbnail`：返回单页 PNG 缩略图
- `POST /api/pdfs/{file_id}/export`：根据规则生成并下载 PDF

导出请求示例：

```json
{
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
}
```

合并时会保留源页面的可视方向。对于通过 PDF 旋转标记显示为横向的页面，后端会补偿旋转后再嵌入合并页。

## 自动测试依赖

如果需要使用 FastAPI / Starlette 的测试客户端，可额外安装：

```bash
python -m pip install httpx
```

## 端到端测试

运行完整后端链路测试。如果本地存在 `samples/sample.pdf`，测试会优先使用它；否则会自动生成一份包含混合尺寸和旋转页面的合成 PDF：

```bash
source .venv/bin/activate
cd backend
python tests/e2e_backend.py
```

测试覆盖：

- PDF 上传保存
- PDF 信息读取
- 多页缩略图渲染
- 第 26-33 页 `4合1` 导出
- 第 26-33 页 `8合1` 导出
- A4 合并页尺寸校验
- 输出 PDF 基础渲染校验
