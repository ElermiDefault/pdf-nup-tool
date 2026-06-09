function PdfUploader({ isUploading, onUpload }) {
  function handleFileChange(event) {
    const file = event.target.files?.[0];
    if (file) {
      onUpload(file);
    }
    event.target.value = '';
  }

  return (
    <section className="upload-panel">
      <div>
        <h2>Upload PDF</h2>
        <p>Choose a PDF to load page thumbnails from the backend.</p>
      </div>
      <label className="file-button">
        <input
          type="file"
          accept="application/pdf,.pdf"
          disabled={isUploading}
          onChange={handleFileChange}
        />
        <span>{isUploading ? 'Uploading...' : 'Choose PDF'}</span>
      </label>
    </section>
  );
}

export default PdfUploader;

