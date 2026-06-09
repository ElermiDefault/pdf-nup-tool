# PDF N-up Tool

[English](#pdf-n-up-tool) | [中文](#中文说明)

PDF N-up Tool is a local web app for selectively merging PDF pages into N-up output pages. You can upload a PDF, create one or more merge tasks, assign pages from the thumbnail grid, choose `2-up`, `4-up`, or `8-up` per task, and export a new PDF.

The app runs locally. Uploaded PDFs, thumbnails, and exported files stay on your machine.

## Features

- Upload a PDF and preview every page as a thumbnail.
- Create multiple merge tasks before selecting pages.
- Assign pages to tasks by clicking thumbnails.
- Use different colors for different tasks.
- Choose `2 in 1`, `4 in 1`, or `8 in 1` per task.
- Automatically split non-contiguous pages in a task into multiple continuous export rules.
- Preserve unselected pages as-is.
- Export merged pages on A4 output pages.
- Handle PDFs with mixed page sizes and rotation metadata.

## Tech Stack

- Frontend: React + Vite
- Backend: Python + FastAPI + PyMuPDF + pypdf + uvicorn
- Launcher: Python script that starts backend and frontend together

## Project Structure

```text
pdf-nup-tool/
  backend/          FastAPI API and PDF processing services
  frontend/         React + Vite frontend
  docs/             API and architecture notes
  output/           Runtime PDF export directory
  samples/          Local-only test PDFs
  tmp/              Runtime uploads, thumbnails, logs, and scratch files
  pdfnuptool        One-command launcher
```

## Requirements

- macOS, Linux, or another Unix-like environment
- Python 3.10+
- A Python environment with the backend dependencies installed
- Node.js 20+ or 22+
- npm

## Install

Backend dependencies:

```bash
cd pdf-nup-tool
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt
```

You can also use conda or another environment manager. The launcher uses the currently active Python interpreter.

Frontend dependencies:

```bash
cd pdf-nup-tool/frontend
npm install
```

## Run

From the project root:

```bash
source .venv/bin/activate
pdfnuptool
```

The launcher starts:

- Backend: `http://127.0.0.1:8010`
- Frontend: `http://127.0.0.1:5173`
- Launcher heartbeat server: `http://127.0.0.1:8123`

It opens the frontend page automatically. Closing the frontend page stops the backend and frontend services after a short delay.

If the command is not available, run the local script directly:

```bash
./pdfnuptool
```

## Manual Development

Start the backend:

```bash
source .venv/bin/activate
cd pdf-nup-tool/backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8010 --reload
```

Start the frontend in another terminal:

```bash
cd pdf-nup-tool/frontend
npm run dev -- --host 127.0.0.1 --port 5173
```

## Tests

Backend end-to-end test:

```bash
source .venv/bin/activate
cd pdf-nup-tool/backend
python tests/e2e_backend.py
```

Frontend build check:

```bash
cd pdf-nup-tool/frontend
npm run build
```

## Packaging

Create a macOS source preview zip:

```bash
./scripts/package_macos.sh v0.2.0
```

The archive is written to `dist/` and excludes dependency folders, build output, runtime cache, generated PDFs, and local sample PDFs.

## Runtime Files

The following are generated locally and ignored by Git:

- `tmp/uploads/`
- `tmp/thumbnails/`
- `tmp/launcher-*.log`
- `output/exports/`
- `frontend/dist/`
- `frontend/node_modules/`
- `dist/`
- `samples/*.pdf`

PDF samples are ignored by default to avoid publishing private documents.

## License

MIT

---

# 中文说明

PDF N-up Tool 是一个本地运行的 PDF 页面合并工具。你可以上传一份 PDF，在缩略图网格中创建多个合并任务，为每个任务选择 `2合1`、`4合1` 或 `8合1`，然后导出新的 PDF。

整个应用在本机运行。上传的 PDF、缩略图和导出的文件都保留在你的电脑上，不会上传到公网服务器。

## 功能

- 上传 PDF，并以缩略图形式预览每一页。
- 先创建多个合并任务，再为任务选择页面。
- 点击缩略图即可把页面分配到当前任务。
- 不同合并任务使用不同颜色标注。
- 每个任务可以独立选择 `2合1`、`4合1` 或 `8合1`。
- 如果同一个任务里的页面不连续，会自动拆成多个连续导出规则。
- 未选中的页面会按原样保留。
- 合并后的页面默认使用 A4 输出。
- 支持混合页面尺寸、横竖方向和 PDF 旋转标记。

## 技术栈

- 前端：React + Vite
- 后端：Python + FastAPI + PyMuPDF + pypdf + uvicorn
- 启动器：Python 脚本，同时启动前端和后端

## 项目结构

```text
pdf-nup-tool/
  backend/          FastAPI 后端和 PDF 处理逻辑
  frontend/         React + Vite 前端
  docs/             API 和架构说明
  output/           运行时 PDF 导出目录
  samples/          本地测试 PDF 目录
  tmp/              上传文件、缩略图、日志和临时文件
  pdfnuptool        一键启动脚本
```

## 环境要求

- macOS、Linux 或其他类 Unix 环境
- Python 3.10+
- 已安装后端依赖的 Python 环境
- Node.js 20+ 或 22+
- npm

## 安装

安装后端依赖：

```bash
cd pdf-nup-tool
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt
```

你也可以使用 conda 或其他环境管理工具。启动器会使用当前已激活环境里的 Python 解释器。

安装前端依赖：

```bash
cd pdf-nup-tool/frontend
npm install
```

## 启动

在项目根目录运行：

```bash
source .venv/bin/activate
pdfnuptool
```

启动器会启动：

- 后端：`http://127.0.0.1:8010`
- 前端：`http://127.0.0.1:5173`
- 启动器心跳服务：`http://127.0.0.1:8123`

启动后会自动打开前端页面。关闭前端页面后，后端和前端服务会在短暂延迟后自动停止。

如果系统找不到 `pdfnuptool` 命令，可以在项目根目录直接运行：

```bash
./pdfnuptool
```

## 手动开发

启动后端：

```bash
source .venv/bin/activate
cd pdf-nup-tool/backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8010 --reload
```

另开一个终端启动前端：

```bash
cd pdf-nup-tool/frontend
npm run dev -- --host 127.0.0.1 --port 5173
```

## 测试

后端端到端测试：

```bash
source .venv/bin/activate
cd pdf-nup-tool/backend
python tests/e2e_backend.py
```

前端构建检查：

```bash
cd pdf-nup-tool/frontend
npm run build
```

## 打包

创建 macOS 源码预览 zip 包：

```bash
./scripts/package_macos.sh v0.2.0
```

压缩包会生成到 `dist/`，并排除依赖目录、构建产物、运行缓存、导出 PDF 和本地样例 PDF。

## 运行时文件

以下文件和目录会在本地运行时生成，并已被 Git 忽略：

- `tmp/uploads/`
- `tmp/thumbnails/`
- `tmp/launcher-*.log`
- `output/exports/`
- `frontend/dist/`
- `frontend/node_modules/`
- `dist/`
- `samples/*.pdf`

PDF 样例文件默认被忽略，避免误把私人文档发布到仓库。

## 许可证

MIT
