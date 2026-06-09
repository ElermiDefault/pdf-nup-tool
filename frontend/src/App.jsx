import { useEffect, useMemo, useState } from 'react';

import { API_BASE_URL, exportPdf, uploadPdf } from './api/client.js';
import PdfUploader from './components/PdfUploader.jsx';
import SelectionSummary from './components/SelectionSummary.jsx';
import ThumbnailGrid from './components/ThumbnailGrid.jsx';

const RANGE_COLORS = ['#2364aa', '#c8553d', '#2a7f62', '#8a5aab', '#b37a00', '#00788a'];
const DEFAULT_LAYOUT = 4;
const LAUNCHER_URL =
  import.meta.env.VITE_LAUNCHER_URL ?? `${window.location.protocol}//${window.location.hostname}:8123`;

function buildContinuousRanges(pages) {
  const sortedPages = [...pages].sort((a, b) => a - b);
  const ranges = [];

  for (const page of sortedPages) {
    const previous = ranges[ranges.length - 1];
    if (previous && page === previous.end + 1) {
      previous.end = page;
    } else {
      ranges.push({ start: page, end: page });
    }
  }

  return ranges;
}

function createTaskId() {
  return `task-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function App() {
  const [pdf, setPdf] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [error, setError] = useState('');
  const [mergeTasks, setMergeTasks] = useState([]);
  const [activeTaskId, setActiveTaskId] = useState(null);
  const tasksWithColors = useMemo(
    () =>
      mergeTasks.map((task, index) => ({
        ...task,
        color: RANGE_COLORS[index % RANGE_COLORS.length],
      })),
    [mergeTasks],
  );
  const pageTaskMap = useMemo(() => {
    const assignments = new Map();
    for (const task of tasksWithColors) {
      for (const page of task.pages) {
        assignments.set(page, task);
      }
    }
    return assignments;
  }, [tasksWithColors]);
  const taskRanges = useMemo(
    () =>
      tasksWithColors.flatMap((task) =>
        buildContinuousRanges(task.pages).map((range) => ({
          ...range,
          taskId: task.id,
          layout: task.layout,
          color: task.color,
        })),
      ),
    [tasksWithColors],
  );
  const exportRules = useMemo(
    () =>
      taskRanges.map((range) => ({
        start_page: range.start,
        end_page: range.end,
        layout: range.layout,
      })),
    [taskRanges],
  );

  useEffect(() => {
    if (!LAUNCHER_URL) {
      return undefined;
    }

    let stopped = false;

    async function sendHeartbeat() {
      try {
        await fetch(`${LAUNCHER_URL}/heartbeat`, { method: 'POST' });
      } catch {
        // The launcher heartbeat is optional outside the one-command startup flow.
      }
    }

    sendHeartbeat();
    const intervalId = window.setInterval(() => {
      if (!stopped) {
        sendHeartbeat();
      }
    }, 2000);

    return () => {
      stopped = true;
      window.clearInterval(intervalId);
    };
  }, []);

  async function handleUpload(file) {
    setIsUploading(true);
    setError('');

    try {
      const uploadedPdf = await uploadPdf(file);
      setPdf(uploadedPdf);
      setMergeTasks([]);
      setActiveTaskId(null);
    } catch (uploadError) {
      const detail = uploadError.response?.data?.detail;
      setError(typeof detail === 'string' ? detail : 'Failed to upload PDF.');
      setPdf(null);
      setMergeTasks([]);
      setActiveTaskId(null);
    } finally {
      setIsUploading(false);
    }
  }

  function handleTogglePage(pageNumber) {
    if (!activeTaskId) {
      setError('Create or activate a merge task before selecting pages.');
      return;
    }

    setError('');
    setMergeTasks((currentTasks) => {
      const assignedTaskId = currentTasks.find((task) => task.pages.includes(pageNumber))?.id;
      return currentTasks.map((task) => {
        const withoutPage = task.pages.filter((page) => page !== pageNumber);
        if (task.id !== activeTaskId) {
          return { ...task, pages: withoutPage };
        }
        if (assignedTaskId === activeTaskId) {
          return { ...task, pages: withoutPage };
        }
        return {
          ...task,
          pages: [...withoutPage, pageNumber].sort((a, b) => a - b),
        };
      });
    });
  }

  function handleCreateTask(layout) {
    const task = {
      id: createTaskId(),
      layout,
      pages: [],
    };
    setMergeTasks((currentTasks) => [...currentTasks, task]);
    setActiveTaskId(task.id);
    setError('');
  }

  function handleClearTasks() {
    setMergeTasks([]);
    setActiveTaskId(null);
  }

  function handleLayoutChange(taskId, layout) {
    setMergeTasks((currentTasks) =>
      currentTasks.map((task) => (task.id === taskId ? { ...task, layout } : task)),
    );
  }

  function handleDeleteTask(taskId) {
    setMergeTasks((currentTasks) => currentTasks.filter((task) => task.id !== taskId));
    setActiveTaskId((currentTaskId) => (currentTaskId === taskId ? null : currentTaskId));
  }

  async function handleExport() {
    if (!pdf || exportRules.length === 0) {
      return;
    }

    setIsExporting(true);
    setError('');

    try {
      const payload = {
        rules: exportRules,
        page_size: 'a4',
        margin: 24,
        gap: 12,
        cell_padding: 6,
      };
      const { blob, filename } = await exportPdf(pdf.file_id, payload);
      downloadBlob(blob, filename);
    } catch (exportError) {
      const detail = await errorDetail(exportError);
      setError(detail ?? 'Failed to export PDF.');
    } finally {
      setIsExporting(false);
    }
  }

  return (
    <main className="app-shell">
      <section className="workspace">
        <header className="topbar">
          <div>
            <h1>PDF N-up Tool</h1>
            <p>Backend: {API_BASE_URL}</p>
          </div>
          <button
            type="button"
            className="primary-button"
            disabled={!pdf || exportRules.length === 0 || isExporting}
            onClick={handleExport}
          >
            {isExporting ? 'Exporting...' : 'Export PDF'}
          </button>
        </header>

        <PdfUploader isUploading={isUploading} onUpload={handleUpload} />

        {error ? <div className="error-banner">{error}</div> : null}

        {pdf ? (
          <SelectionSummary
            activeTaskId={activeTaskId}
            exportRules={exportRules}
            onActivateTask={setActiveTaskId}
            onClear={handleClearTasks}
            onCreateTask={handleCreateTask}
            onDeleteTask={handleDeleteTask}
            onLayoutChange={handleLayoutChange}
            tasks={tasksWithColors}
          />
        ) : null}

        <ThumbnailGrid
          activeTaskId={activeTaskId}
          pdf={pdf}
          pageTaskMap={pageTaskMap}
          selectionRanges={taskRanges}
          onTogglePage={handleTogglePage}
        />
      </section>
    </main>
  );
}

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

async function errorDetail(error) {
  const data = error.response?.data;
  if (!data) {
    return null;
  }
  if (data instanceof Blob) {
    const text = await data.text();
    try {
      const parsed = JSON.parse(text);
      return typeof parsed.detail === 'string' ? parsed.detail : text;
    } catch {
      return text;
    }
  }
  return typeof data.detail === 'string' ? data.detail : null;
}

export default App;
