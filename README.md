# PDF N-up Tool

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
- Conda environment named `bio`
- Node.js 20+ or 22+
- npm

The current project defaults to the conda environment `bio`.

## Install

Backend dependencies:

```bash
conda activate bio
cd pdf-nup-tool
python -m pip install -r backend/requirements.txt
```

Frontend dependencies:

```bash
cd pdf-nup-tool/frontend
npm install
```

## Run

From the project root:

```bash
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
conda activate bio
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
conda activate bio
cd pdf-nup-tool/backend
python tests/e2e_backend.py
```

Frontend build check:

```bash
cd pdf-nup-tool/frontend
npm run build
```

## Runtime Files

The following are generated locally and ignored by Git:

- `tmp/uploads/`
- `tmp/thumbnails/`
- `tmp/launcher-*.log`
- `output/exports/`
- `frontend/dist/`
- `frontend/node_modules/`
- `samples/*.pdf`

PDF samples are ignored by default to avoid publishing private documents.

## License

MIT
