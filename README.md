# PDF N-up Tool

[English](#pdf-n-up-tool) | [中文](#中文说明)

PDF N-up Tool is a local web app for selectively merging PDF pages into N-up output pages. You can upload a PDF, create one or more merge tasks, assign pages from the thumbnail grid, choose `2-up`, `3-up`, `4-up`, `5-up`, or `8-up` per task, and export a new PDF.

The app runs locally. Uploaded PDFs, thumbnails, and exported files stay on your machine.

## Features

- Upload a PDF and preview every page as a thumbnail.
- Create multiple merge tasks before selecting pages.
- Assign pages to tasks by clicking thumbnails.
- Use different colors for different tasks.
- Choose `2 in 1`, `3 in 1`, `4 in 1`, `5 in 1`, or `8 in 1` per task.
- Use non-uniform layouts: `3 in 1` places two pages on top and one below; `5 in 1` places three pages on top and two below.
- Automatically split non-contiguous pages in a task into multiple continuous export rules.
- Preserve unselected pages as-is.
- Export merged pages on A4 output pages.
- Handle PDFs with mixed page sizes and rotation metadata.

## Tech Stack

- Frontend: React + Vite
- Backend: Python + FastAPI + PyMuPDF + pypdf + uvicorn
- Launcher: Python script that starts the local app service

## Project Structure

```text
pdf-nup-tool/
  backend/          FastAPI API and PDF processing services
  frontend/         React + Vite frontend
  assets/           App icon and static packaging assets
  docs/             API and architecture notes
  output/           Runtime PDF export directory
  samples/          Local-only test PDFs
  tmp/              Runtime uploads, thumbnails, logs, and scratch files
  pdfnuptool        One-command launcher
```

## Release App Requirements

- macOS 11+

The v0.6.0 macOS app preview is self-contained. It does not require users to install Python, Node.js, npm, or a virtual environment.

## Source Development Requirements

- macOS, Linux, or another Unix-like environment
- Python 3.10+
- A Python environment with the backend dependencies installed
- Node.js 20+ or 22+
- npm

## Install From Source

Recommended setup:

```bash
cd pdf-nup-tool
./install.command
```

The installer creates a local `.venv`, installs backend dependencies, builds the frontend static files, and can install a `pdfnuptool` command into `~/.local/bin`.

You can also install dependencies manually with venv, conda, or another environment manager.

## Run Release App

Download and unzip the macOS self-contained package, then double-click:

```text
PDF N-up Tool.app
```

The app opens:

```text
http://127.0.0.1:8010
```

Uploaded PDFs, thumbnails, logs, and exported files are stored locally under:

```text
~/Library/Application Support/PDF N-up Tool
```

This preview build is unsigned. If macOS blocks it, right-click the app and choose Open.

## Run From Source

After running `install.command`, double-click:

```text
PDF N-up Tool.app
```

You can also run from Terminal:

```bash
pdfnuptool
```

The launcher starts:

- App: `http://127.0.0.1:8010`
- Launcher heartbeat server: `http://127.0.0.1:8123`

It opens the app page automatically. Closing the app page stops the local service after a short delay.

This source-built `.app` is a wrapper around the local project. Keep `PDF N-up Tool.app` in the project folder next to `pdfnuptool`, `backend/`, and `frontend/`.

If the command is not available, run the local script directly:

```bash
./pdfnuptool
```

After running `install.command`, `./pdfnuptool` uses the local `.venv` automatically.

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

In development, Vite proxies `/api` and `/health` to the backend on port `8010`.

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

Create a self-contained macOS app preview zip:

```bash
python -m pip install pyinstaller
./scripts/build_pyinstaller_app.sh v0.6.0
```

The archive is written to `dist/` and contains a self-contained `PDF N-up Tool.app`.

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

PDF N-up Tool 是一个本地运行的 PDF 页面合并工具。你可以上传一份 PDF，在缩略图网格中创建多个合并任务，为每个任务选择 `2合1`、`3合1`、`4合1`、`5合1` 或 `8合1`，然后导出新的 PDF。

整个应用在本机运行。上传的 PDF、缩略图和导出的文件都保留在你的电脑上，不会上传到公网服务器。

## 功能

- 上传 PDF，并以缩略图形式预览每一页。
- 先创建多个合并任务，再为任务选择页面。
- 点击缩略图即可把页面分配到当前任务。
- 不同合并任务使用不同颜色标注。
- 每个任务可以独立选择 `2合1`、`3合1`、`4合1`、`5合1` 或 `8合1`。
- 支持非均匀布局：`3合1` 为上方两页、下方一页；`5合1` 为上方三页、下方两页。
- 如果同一个任务里的页面不连续，会自动拆成多个连续导出规则。
- 未选中的页面会按原样保留。
- 合并后的页面默认使用 A4 输出。
- 支持混合页面尺寸、横竖方向和 PDF 旋转标记。

## 技术栈

- 前端：React + Vite
- 后端：Python + FastAPI + PyMuPDF + pypdf + uvicorn
- 启动器：Python 脚本，启动本地应用服务

## 项目结构

```text
pdf-nup-tool/
  backend/          FastAPI 后端和 PDF 处理逻辑
  frontend/         React + Vite 前端
  assets/           App 图标和打包静态资源
  docs/             API 和架构说明
  output/           运行时 PDF 导出目录
  samples/          本地测试 PDF 目录
  tmp/              上传文件、缩略图、日志和临时文件
  pdfnuptool        一键启动脚本
```

## Release App 环境要求

- macOS 11+

v0.6.0 macOS App 预览版是自包含应用。普通用户不需要安装 Python、Node.js、npm 或虚拟环境。

## 源码开发环境要求

- macOS、Linux 或其他类 Unix 环境
- Python 3.10+
- 已安装后端依赖的 Python 环境
- Node.js 20+ 或 22+
- npm

## 从源码安装

推荐安装方式：

```bash
cd pdf-nup-tool
./install.command
```

安装脚本会创建本地 `.venv`，安装后端依赖，构建前端静态文件，并可选择把 `pdfnuptool` 命令安装到 `~/.local/bin`。

你也可以使用 venv、conda 或其他环境管理工具手动安装依赖。

## 启动 Release App

下载并解压 macOS 自包含包后，双击：

```text
PDF N-up Tool.app
```

应用会打开：

```text
http://127.0.0.1:8010
```

上传 PDF、缩略图、日志和导出文件会保存在本机：

```text
~/Library/Application Support/PDF N-up Tool
```

当前预览版未签名。如果 macOS 阻止打开，请右键点击 App 并选择“打开”。

## 从源码启动

运行过 `install.command` 后，双击：

```text
PDF N-up Tool.app
```

也可以在终端运行：

```bash
pdfnuptool
```

启动器会启动：

- 应用：`http://127.0.0.1:8010`
- 启动器心跳服务：`http://127.0.0.1:8123`

启动后会自动打开应用页面。关闭应用页面后，本地服务会在短暂延迟后自动停止。

源码构建出的 `.app` 是本地项目的 wrapper，需要和 `pdfnuptool`、`backend/`、`frontend/` 放在同一个项目目录中。

如果系统找不到 `pdfnuptool` 命令，可以在项目根目录直接运行：

```bash
./pdfnuptool
```

运行过 `install.command` 后，`./pdfnuptool` 会自动使用本地 `.venv`。

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

开发模式下，Vite 会把 `/api` 和 `/health` 代理到 `8010` 端口的后端服务。

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

创建 macOS 自包含 App 预览版 zip 包：

```bash
python -m pip install pyinstaller
./scripts/build_pyinstaller_app.sh v0.6.0
```

压缩包会生成到 `dist/`，并包含自包含的 `PDF N-up Tool.app`。

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
