from pathlib import Path

import fitz
from fastapi import HTTPException, status

from app.core.config import THUMBNAIL_DIR


MIN_THUMBNAIL_WIDTH = 80
MAX_THUMBNAIL_WIDTH = 1200
DEFAULT_THUMBNAIL_WIDTH = 240


def render_thumbnail(pdf_path: Path, file_id: str, page_number: int, width: int) -> Path:
    width = _validate_width(width)
    THUMBNAIL_DIR.mkdir(parents=True, exist_ok=True)
    thumbnail_path = THUMBNAIL_DIR / f"{file_id}-p{page_number}-w{width}.png"

    if thumbnail_path.exists():
        return thumbnail_path

    try:
        with fitz.open(pdf_path) as doc:
            if page_number < 1 or page_number > doc.page_count:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Page {page_number} does not exist. This PDF has {doc.page_count} page(s).",
                )

            page = doc[page_number - 1]
            scale = width / page.rect.width
            matrix = fitz.Matrix(scale, scale)
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            pixmap.save(thumbnail_path)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to render thumbnail: {exc}",
        ) from exc

    return thumbnail_path


def _validate_width(width: int) -> int:
    if width < MIN_THUMBNAIL_WIDTH or width > MAX_THUMBNAIL_WIDTH:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Thumbnail width must be between {MIN_THUMBNAIL_WIDTH} and {MAX_THUMBNAIL_WIDTH}.",
        )

    return width
