function PdfUploader({ isUploading, onClearWorkspace, onUpload, pdfs }) {
  function handleFileChange(event) {
    const files = Array.from(event.target.files ?? []);
    if (files.length > 0) {
      onUpload(files);
    }
    event.target.value = '';
  }

  const loadedPdfCount = pdfs.length;

  return (
    <section className="upload-panel">
      <div className="upload-copy">
        <h2>PDF inputs</h2>
        <p>
          {loadedPdfCount > 0
            ? `${loadedPdfCount} PDF${loadedPdfCount > 1 ? 's' : ''} loaded`
            : 'No PDFs loaded'}
        </p>
        {loadedPdfCount > 0 ? (
          <ul className="loaded-pdf-list" aria-label="Loaded PDFs">
            {pdfs.map((pdf) => (
              <li key={pdf.file_id}>
                <span>{pdf.filename}</span>
                <strong>{pdf.page_count} pages</strong>
              </li>
            ))}
          </ul>
        ) : null}
      </div>
      <div className="upload-actions">
        {loadedPdfCount > 0 ? (
          <button
            type="button"
            className="secondary-button"
            disabled={isUploading}
            onClick={onClearWorkspace}
          >
            Clear
          </button>
        ) : null}
        <label className="file-button">
          <input
            type="file"
            accept="application/pdf,.pdf"
            disabled={isUploading}
            multiple
            onChange={handleFileChange}
          />
          <span>{isUploading ? 'Uploading...' : 'Add PDFs'}</span>
        </label>
      </div>
    </section>
  );
}

export default PdfUploader;
