import { thumbnailUrl } from '../api/client.js';

function pageRangeFor(pageNumber, ranges) {
  return ranges.find((range) => pageNumber >= range.start && pageNumber <= range.end);
}

function ThumbnailGrid({ activeTaskId, pageTaskMap, pdf, onTogglePage, selectionRanges }) {
  if (!pdf) {
    return (
      <section className="empty-state">
        <h2>No PDF loaded</h2>
        <p>Upload a PDF to preview its pages.</p>
      </section>
    );
  }

  const pages = Array.from({ length: pdf.page_count }, (_, index) => index + 1);

  return (
    <section className="thumbnail-section">
      <div className="section-heading">
        <div>
          <h2>{pdf.filename}</h2>
          <p>
            {pdf.page_count} pages
            {activeTaskId ? '' : ' - create or activate a task before selecting pages'}
          </p>
        </div>
      </div>

      <div className="thumbnail-grid">
        {pages.map((pageNumber) => (
          <PageTile
            isSelected={pageTaskMap.has(pageNumber)}
            key={pageNumber}
            onTogglePage={onTogglePage}
            pageNumber={pageNumber}
            range={pageRangeFor(pageNumber, selectionRanges)}
            pdf={pdf}
          />
        ))}
      </div>
    </section>
  );
}

function PageTile({ isSelected, onTogglePage, pageNumber, pdf, range }) {
  const rangeColor = range?.color ?? 'transparent';

  return (
    <article
      className={`page-tile${isSelected ? ' is-selected' : ''}`}
      style={{ '--range-color': rangeColor }}
    >
      <button
        type="button"
        className="page-select-button"
        aria-pressed={isSelected}
        onClick={() => onTogglePage(pageNumber)}
      >
            <div className="thumbnail-frame">
              <img
                src={thumbnailUrl(pdf.file_id, pageNumber)}
                alt={`Page ${pageNumber}`}
                loading="lazy"
              />
            </div>
        <div className="page-number">Page {pageNumber}</div>
      </button>
    </article>
  );
}

export default ThumbnailGrid;
