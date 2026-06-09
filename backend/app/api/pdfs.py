from pathlib import Path

from fastapi import APIRouter, File, Query, UploadFile
from fastapi.responses import FileResponse

from app.models.pdf import ExportRequest, PdfInfoResponse, PdfUploadResponse
from app.services.pdf_exporter import export_pdf_with_rules
from app.services.pdf_store import get_pdf_info, get_pdf_path, save_uploaded_pdf
from app.services.pdf_thumbnailer import DEFAULT_THUMBNAIL_WIDTH, render_thumbnail


router = APIRouter(prefix="/api/pdfs", tags=["pdfs"])


@router.post("", response_model=PdfUploadResponse)
async def upload_pdf(file: UploadFile = File(...)) -> PdfUploadResponse:
    return await save_uploaded_pdf(file)


@router.get("/{file_id}", response_model=PdfInfoResponse)
def read_pdf_info(file_id: str) -> PdfInfoResponse:
    return get_pdf_info(file_id)


@router.get("/{file_id}/pages/{page_number}/thumbnail", response_class=FileResponse)
def read_page_thumbnail(
    file_id: str,
    page_number: int,
    width: int = Query(default=DEFAULT_THUMBNAIL_WIDTH),
) -> FileResponse:
    get_pdf_info(file_id)
    thumbnail_path = render_thumbnail(get_pdf_path(file_id), file_id, page_number, width)

    return FileResponse(
        thumbnail_path,
        media_type="image/png",
        filename=f"{file_id}-p{page_number}.png",
    )


@router.post("/{file_id}/export", response_class=FileResponse)
def export_pdf(file_id: str, request: ExportRequest) -> FileResponse:
    pdf_info = get_pdf_info(file_id)
    output_path = export_pdf_with_rules(get_pdf_path(file_id), request)
    download_name = f"{Path(pdf_info.filename).stem}-nup.pdf"

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename=download_name,
    )
