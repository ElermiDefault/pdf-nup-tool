import os
from pathlib import Path


SOURCE_BASE_DIR = Path(__file__).resolve().parents[3]
BASE_DIR = Path(os.environ.get("PDFNUPTOOL_BASE_DIR", SOURCE_BASE_DIR)).expanduser()
DATA_DIR = Path(os.environ.get("PDFNUPTOOL_DATA_DIR", BASE_DIR)).expanduser()
TMP_DIR = DATA_DIR / "tmp"
UPLOAD_DIR = TMP_DIR / "uploads"
THUMBNAIL_DIR = TMP_DIR / "thumbnails"
OUTPUT_DIR = DATA_DIR / "output"
EXPORT_DIR = OUTPUT_DIR / "exports"
FRONTEND_DIST_DIR = Path(
    os.environ.get("PDFNUPTOOL_FRONTEND_DIST_DIR", BASE_DIR / "frontend" / "dist")
).expanduser()

ALLOWED_PDF_CONTENT_TYPES = {
    "application/pdf",
    "application/x-pdf",
}
