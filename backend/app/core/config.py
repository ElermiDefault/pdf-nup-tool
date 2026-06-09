from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[3]
TMP_DIR = BASE_DIR / "tmp"
UPLOAD_DIR = TMP_DIR / "uploads"
THUMBNAIL_DIR = TMP_DIR / "thumbnails"
OUTPUT_DIR = BASE_DIR / "output"
EXPORT_DIR = OUTPUT_DIR / "exports"
FRONTEND_DIST_DIR = BASE_DIR / "frontend" / "dist"

ALLOWED_PDF_CONTENT_TYPES = {
    "application/pdf",
    "application/x-pdf",
}
