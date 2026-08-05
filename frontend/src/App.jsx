import { useEffect, useMemo, useState } from 'react';

import { API_BASE_URL, exportPdfBatch, uploadPdf } from './api/client.js';
import PdfUploader from './components/PdfUploader.jsx';
import SelectionSummary from './components/SelectionSummary.jsx';
import ThumbnailGrid from './components/ThumbnailGrid.jsx';

const RANGE_COLORS = ['#2364aa', '#c8553d', '#2a7f62', '#8a5aab', '#b37a00', '#00788a'];
const LAUNCHER_URL =
  import.meta.env.VITE_LAUNCHER_URL ?? `${window.location.protocol}//${window.location.hostname}:8123`;

function buildContinuousRanges(numbers) {
  const sortedNumbers = [...numbers].sort((a, b) => a - b);
  const ranges = [];

  for (const number of sortedNumbers) {
    const previous = ranges[ranges.length - 1];
    if (previous && number === previous.end + 1) {
      previous.end = number;
    } else {
      ranges.push({ start: number, end: number });
    }
  }

  return ranges;
}

function createTaskId() {
  return `task-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function createPageItems(pdf) {
  return Array.from({ length: pdf.page_count }, (_, index) => {
    const pageNumber = index + 1;
    return {
      id: `${pdf.file_id}:${pageNumber}`,
      fileId: pdf.file_id,
      filename: pdf.filename,
      pageNumber,
    };
  });
}

function App() {
  const [pdfs, setPdfs] = useState([]);
  const [pageItems, setPageItems] = useState([]);
  const [isUploading, setIsUploading] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [error, setError] = useState('');
  const [mergeTasks, setMergeTasks] = useState([]);
  const [activeTaskId, setActiveTaskId] = useState(null);
  const [draggingPageIds, setDraggingPageIds] = useState([]);
  const [dropPreview, setDropPreview] = useState(null);

  const tasksWithColors = useMemo(
    () =>
      mergeTasks.map((task, index) => ({
        ...task,
        color: RANGE_COLORS[index % RANGE_COLORS.length],
      })),
    [mergeTasks],
  );

  const pageIndexMap = useMemo(() => {
    const indexes = new Map();
    pageItems.forEach((page, index) => {
      indexes.set(page.id, index + 1);
    });
    return indexes;
  }, [pageItems]);

  const pageTaskMap = useMemo(() => {
    const assignments = new Map();
    for (const task of tasksWithColors) {
      for (const pageId of task.pageIds) {
        assignments.set(pageId, task);
      }
    }
    return assignments;
  }, [tasksWithColors]);

  const taskRanges = useMemo(
    () =>
      tasksWithColors.flatMap((task) => {
        const selectedIndexes = task.pageIds
          .map((pageId) => pageIndexMap.get(pageId))
          .filter((index) => Number.isInteger(index));

        return buildContinuousRanges(selectedIndexes).map((range) => ({
          ...range,
          taskId: task.id,
          layout: task.layout,
          color: task.color,
        }));
      }),
    [pageIndexMap, tasksWithColors],
  );

  const exportRules = useMemo(
    () =>
      taskRanges.map((range) => ({
        start_index: range.start,
        end_index: range.end,
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

  async function handleUpload(files) {
    const selectedFiles = Array.from(files);
    if (selectedFiles.length === 0) {
      return;
    }

    setIsUploading(true);
    setError('');

    try {
      const uploadedPdfs = [];
      for (const file of selectedFiles) {
        uploadedPdfs.push(await uploadPdf(file));
      }
      setPdfs((currentPdfs) => [...currentPdfs, ...uploadedPdfs]);
      setPageItems((currentPages) => [
        ...currentPages,
        ...uploadedPdfs.flatMap((uploadedPdf) => createPageItems(uploadedPdf)),
      ]);
    } catch (uploadError) {
      const detail = uploadError.response?.data?.detail;
      setError(typeof detail === 'string' ? detail : 'Failed to upload PDF.');
    } finally {
      setIsUploading(false);
    }
  }

  function handleTogglePage(pageId) {
    if (!activeTaskId) {
      setError('Create or activate a merge task before selecting pages.');
      return;
    }

    setError('');
    setMergeTasks((currentTasks) => {
      const assignedTaskId = currentTasks.find((task) => task.pageIds.includes(pageId))?.id;
      return currentTasks.map((task) => {
        const withoutPage = task.pageIds.filter((currentPageId) => currentPageId !== pageId);
        if (task.id !== activeTaskId) {
          return { ...task, pageIds: withoutPage };
        }
        if (assignedTaskId === activeTaskId) {
          return { ...task, pageIds: withoutPage };
        }
        return {
          ...task,
          pageIds: [...withoutPage, pageId],
        };
      });
    });
  }

  function handleCreateTask(layout) {
    const task = {
      id: createTaskId(),
      layout,
      pageIds: [],
    };
    setMergeTasks((currentTasks) => [...currentTasks, task]);
    setActiveTaskId(task.id);
    setError('');
  }

  function handleClearTasks() {
    setMergeTasks([]);
    setActiveTaskId(null);
  }

  function handleClearWorkspace() {
    setPdfs([]);
    setPageItems([]);
    setMergeTasks([]);
    setActiveTaskId(null);
    setDraggingPageIds([]);
    setDropPreview(null);
    setError('');
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

  function handlePagePointerDragStart(event, pageId) {
    if (event.button !== 0) {
      return;
    }

    event.preventDefault();
    const pageIds = pageDragGroup(pageId);
    const draggedPageIds = new Set(pageIds);
    setDraggingPageIds(pageIds);
    setDropPreview(null);

    const updatePreview = (pointerEvent) => {
      setDropPreview(dropTargetFromPoint(pointerEvent.clientX, pointerEvent.clientY, draggedPageIds));
    };
    const finishDrag = (pointerEvent) => {
      const target = dropTargetFromPoint(pointerEvent.clientX, pointerEvent.clientY, draggedPageIds);
      if (target) {
        reorderPages(pageIds, target.pageId, target.insertAfter);
      }
      cleanupDrag();
    };
    const cancelDrag = () => {
      cleanupDrag();
    };
    const cleanupDrag = () => {
      window.removeEventListener('pointermove', updatePreview);
      window.removeEventListener('pointerup', finishDrag);
      window.removeEventListener('pointercancel', cancelDrag);
      setDraggingPageIds([]);
      setDropPreview(null);
    };

    window.addEventListener('pointermove', updatePreview);
    window.addEventListener('pointerup', finishDrag, { once: true });
    window.addEventListener('pointercancel', cancelDrag, { once: true });
  }

  function pageDragGroup(pageId) {
    const task = mergeTasks.find((candidate) => candidate.pageIds.includes(pageId));
    if (!task || task.pageIds.length <= 1) {
      return [pageId];
    }

    const taskPageIds = new Set(task.pageIds);
    return pageItems.filter((page) => taskPageIds.has(page.id)).map((page) => page.id);
  }

  function reorderPages(pageIds, targetPageId, insertAfter) {
    setPageItems((currentPages) => {
      const draggedPageIds = new Set(pageIds);
      if (draggedPageIds.size === 0 || draggedPageIds.has(targetPageId)) {
        return currentPages;
      }

      const movingPages = currentPages.filter((page) => draggedPageIds.has(page.id));
      if (movingPages.length === 0) {
        return currentPages;
      }

      const remainingPages = currentPages.filter((page) => !draggedPageIds.has(page.id));
      const targetIndex = remainingPages.findIndex((page) => page.id === targetPageId);
      if (targetIndex === -1) {
        return currentPages;
      }

      const insertIndex = targetIndex + (insertAfter ? 1 : 0);
      return [
        ...remainingPages.slice(0, insertIndex),
        ...movingPages,
        ...remainingPages.slice(insertIndex),
      ];
    });
  }

  async function handleExport() {
    if (pageItems.length === 0) {
      return;
    }

    setIsExporting(true);
    setError('');

    try {
      const payload = {
        pages: pageItems.map((page) => ({
          file_id: page.fileId,
          page_number: page.pageNumber,
        })),
        rules: exportRules,
        page_size: 'a4',
        margin: 24,
        gap: 12,
        cell_padding: 6,
      };
      const { blob, filename } = await exportPdfBatch(payload);
      await downloadBlob(blob, filename);
    } catch (exportError) {
      const detail = await errorDetail(exportError);
      setError(detail ?? 'Failed to export PDF.');
    } finally {
      setIsExporting(false);
    }
  }

  const hasPages = pageItems.length > 0;

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
            disabled={!hasPages || isExporting}
            onClick={handleExport}
          >
            {isExporting ? 'Exporting...' : 'Export PDF'}
          </button>
        </header>

        <PdfUploader
          isUploading={isUploading}
          onClearWorkspace={handleClearWorkspace}
          onUpload={handleUpload}
          pdfs={pdfs}
        />

        {error ? <div className="error-banner">{error}</div> : null}

        {hasPages ? (
          <SelectionSummary
            activeTaskId={activeTaskId}
            exportRules={exportRules}
            onActivateTask={setActiveTaskId}
            onClear={handleClearTasks}
            onCreateTask={handleCreateTask}
            onDeleteTask={handleDeleteTask}
            onLayoutChange={handleLayoutChange}
            pageItems={pageItems}
            tasks={tasksWithColors}
          />
        ) : null}

        <ThumbnailGrid
          activeTaskId={activeTaskId}
          draggingPageIds={draggingPageIds}
          dropPreview={dropPreview}
          pageItems={pageItems}
          pageTaskMap={pageTaskMap}
          pdfs={pdfs}
          selectionRanges={taskRanges}
          onPointerDragStart={handlePagePointerDragStart}
          onTogglePage={handleTogglePage}
        />
      </section>
    </main>
  );
}

function dropTargetFromPoint(clientX, clientY, draggedPageIds) {
  const element = document.elementFromPoint(clientX, clientY);
  const tile = element?.closest?.('[data-page-id]');
  const pageId = tile?.dataset?.pageId;
  if (!tile || !pageId || draggedPageIds.has(pageId)) {
    return null;
  }

  const rect = tile.getBoundingClientRect();
  const midpointY = rect.top + rect.height / 2;
  const insertAfter =
    clientY > midpointY ||
    (Math.abs(clientY - midpointY) < rect.height * 0.18 && clientX > rect.left + rect.width / 2);

  return { pageId, insertAfter };
}

async function downloadBlob(blob, filename) {
  if (window.webkit?.messageHandlers?.pdfNupSaveFile) {
    const base64 = await blobToBase64(blob);
    window.webkit.messageHandlers.pdfNupSaveFile.postMessage({ filename, base64 });
    return;
  }

  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = String(reader.result ?? '');
      resolve(result.includes(',') ? result.split(',')[1] : result);
    };
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
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
