import { thumbnailUrl } from '../api/client.js';

function pageRangeFor(position, ranges) {
  return ranges.find((range) => position >= range.start && position <= range.end);
}

function ThumbnailGrid({
  activeTaskId,
  draggingPageIds,
  dropPreview,
  pageItems,
  pageTaskMap,
  pdfs,
  onPointerDragStart,
  onTogglePage,
  selectionRanges,
}) {
  if (pageItems.length === 0) {
    return (
      <section className="empty-state">
        <h2>No PDFs loaded</h2>
        <p>Upload one or more PDFs to preview and reorder their pages.</p>
      </section>
    );
  }

  const totalPages = pageItems.length;

  return (
    <section className="thumbnail-section">
      <div className="section-heading">
        <div>
          <h2>Page order</h2>
          <p>
            {pdfs.length} PDF{pdfs.length > 1 ? 's' : ''}, {totalPages} pages
            {activeTaskId ? '' : ' - create or activate a task before selecting pages'}
          </p>
        </div>
      </div>

      <div className="thumbnail-grid">
        {pageItems.map((page, index) => {
          const position = index + 1;
          return (
            <PageTile
              isDragging={draggingPageIds.includes(page.id)}
              isDropAfter={dropPreview?.pageId === page.id && dropPreview.insertAfter}
              isDropBefore={dropPreview?.pageId === page.id && !dropPreview.insertAfter}
              isSelected={pageTaskMap.has(page.id)}
              key={page.id}
              onPointerDragStart={onPointerDragStart}
              onTogglePage={onTogglePage}
              page={page}
              position={position}
              range={pageRangeFor(position, selectionRanges)}
            />
          );
        })}
      </div>
    </section>
  );
}

function PageTile({
  isDragging,
  isDropAfter,
  isDropBefore,
  isSelected,
  onPointerDragStart,
  onTogglePage,
  page,
  position,
  range,
}) {
  const rangeColor = range?.color ?? 'transparent';

  return (
    <article
      className={`page-tile${isSelected ? ' is-selected' : ''}${
        isDragging ? ' is-dragging' : ''
      }${isDropBefore ? ' is-drop-before' : ''}${isDropAfter ? ' is-drop-after' : ''
      }`}
      data-page-id={page.id}
      style={{ '--range-color': rangeColor }}
    >
      <div className="page-tile-toolbar">
        <span className="output-position">Output {position}</span>
        <span className="drag-handle-wrap">
          <button
            type="button"
            className="drag-handle"
            title="Move page"
            aria-label={`Move output page ${position}`}
            onPointerDown={(event) => onPointerDragStart(event, page.id)}
          >
            Move
          </button>
        </span>
      </div>
      <button
        type="button"
        className="page-select-button"
        aria-pressed={isSelected}
        onClick={() => onTogglePage(page.id)}
      >
        <div className="thumbnail-frame">
          <img
            src={thumbnailUrl(page.fileId, page.pageNumber)}
            alt={`${page.filename} page ${page.pageNumber}`}
            loading="lazy"
          />
        </div>
        <div className="page-number">
          <span>
            {page.filename} · p.{page.pageNumber}
          </span>
        </div>
      </button>
    </article>
  );
}

export default ThumbnailGrid;
