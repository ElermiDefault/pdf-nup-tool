from pathlib import Path
from uuid import uuid4

import fitz
from fastapi import HTTPException, UploadFile, status

from app.core.config import ALLOWED_PDF_CONTENT_TYPES, EXPORT_DIR, THUMBNAIL_DIR, UPLOAD_DIR
from app.models.pdf import PdfInfoResponse, PdfUploadResponse


def ensure_storage_dirs() -> None:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    THUMBNAIL_DIR.mkdir(parents=True, exist_ok=True)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)


def get_pdf_path(file_id: str) -> Path:
    return UPLOAD_DIR / f"{file_id}.pdf"


def get_meta_path(file_id: str) -> Path:
    return UPLOAD_DIR / f"{file_id}.txt"


def read_page_count(path: Path) -> int:
    try:
        with fitz.open(path) as doc:
            return doc.page_count
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot read PDF file: {exc}",
        ) from exc


async def save_uploaded_pdf(file: UploadFile) -> PdfUploadResponse:
    if file.content_type not in ALLOWED_PDF_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF files are supported.",
        )

    filename = file.filename or "uploaded.pdf"
    if not filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must use a .pdf extension.",
        )

    ensure_storage_dirs()
    file_id = uuid4().hex
    pdf_path = get_pdf_path(file_id)
    meta_path = get_meta_path(file_id)

    content = await file.read()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    pdf_path.write_bytes(content)
    page_count = read_page_count(pdf_path)
    meta_path.write_text(filename, encoding="utf-8")

    return PdfUploadResponse(
        file_id=file_id,
        filename=filename,
        page_count=page_count,
    )


def get_pdf_info(file_id: str) -> PdfInfoResponse:
    pdf_path = get_pdf_path(file_id)
    meta_path = get_meta_path(file_id)

    if not pdf_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="PDF file not found.",
        )

    filename = meta_path.read_text(encoding="utf-8") if meta_path.exists() else f"{file_id}.pdf"
    page_count = read_page_count(pdf_path)

    return PdfInfoResponse(
        file_id=file_id,
        filename=filename,
        page_count=page_count,
    )
