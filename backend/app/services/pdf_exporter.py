from pathlib import Path
from uuid import uuid4

import fitz
from fastapi import HTTPException, status

from app.core.config import EXPORT_DIR
from app.models.pdf import ExportRequest, MergeRule


ALLOWED_LAYOUTS = {2, 4, 8}
ALLOWED_PAGE_SIZES = {"a4", "a4-landscape", "source"}
A4_PORTRAIT = (595.0, 842.0)


def export_pdf_with_rules(source_path: Path, request: ExportRequest) -> Path:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = EXPORT_DIR / f"{uuid4().hex}.pdf"

    try:
        with fitz.open(source_path) as source_doc:
            rules = _validate_rules(request.rules, source_doc.page_count)

            if request.page_size not in ALLOWED_PAGE_SIZES:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="page_size must be 'a4', 'a4-landscape', or 'source'.",
                )

            output_doc = fitz.open()
            try:
                _build_output_pdf(source_path, source_doc, output_doc, rules, request)
                output_doc.save(output_path, garbage=4, deflate=True)
            finally:
                output_doc.close()

    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to export PDF: {exc}",
        ) from exc

    return output_path


def _validate_rules(rules: list[MergeRule], page_count: int) -> list[MergeRule]:
    sorted_rules = sorted(rules, key=lambda item: item.start_page)
    previous_end = 0

    for rule in sorted_rules:
        if rule.layout not in ALLOWED_LAYOUTS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported layout {rule.layout}. Use 2, 4, or 8.",
            )
        if rule.start_page > rule.end_page:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="start_page must be less than or equal to end_page.",
            )
        if rule.end_page > page_count:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Page range exceeds PDF page count {page_count}.",
            )
        if rule.start_page <= previous_end:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Merge rules must not overlap.",
            )
        previous_end = rule.end_page

    return sorted_rules


def _build_output_pdf(
    source_path: Path,
    source_doc: fitz.Document,
    output_doc: fitz.Document,
    rules: list[MergeRule],
    request: ExportRequest,
) -> None:
    page_count = source_doc.page_count
    page_index = 0
    rule_index = 0

    while page_index < page_count:
        current_rule = rules[rule_index] if rule_index < len(rules) else None
        current_start = current_rule.start_page - 1 if current_rule else None

        if current_rule and page_index == current_start:
            _append_nup_pages(source_path, source_doc, output_doc, current_rule, request)
            page_index = current_rule.end_page
            rule_index += 1
            continue

        output_doc.insert_pdf(source_doc, from_page=page_index, to_page=page_index)
        page_index += 1


def _append_nup_pages(
    source_path: Path,
    source_doc: fitz.Document,
    output_doc: fitz.Document,
    rule: MergeRule,
    request: ExportRequest,
) -> None:
    output_width, output_height = _output_page_size(source_doc, request)
    rows, cols = _grid_for_layout(rule.layout, output_width, output_height)
    page_numbers = list(range(rule.start_page - 1, rule.end_page))

    for chunk_start in range(0, len(page_numbers), rule.layout):
        chunk = page_numbers[chunk_start : chunk_start + rule.layout]
        output_page = output_doc.new_page(width=output_width, height=output_height)
        output_page.draw_rect(output_page.rect, color=None, fill=(1, 1, 1), overlay=False)

        for slot_index, source_page_index in enumerate(chunk):
            row = slot_index // cols
            col = slot_index % cols
            cell = _cell_rect(
                row=row,
                col=col,
                rows=rows,
                cols=cols,
                page_width=output_width,
                page_height=output_height,
                margin=request.margin,
                gap=request.gap,
            )
            content_rect = _content_rect(cell, request.cell_padding)
            embed_doc, embed_page_index, source_rect = _embedding_page(
                source_path,
                source_doc,
                source_page_index,
            )
            target_rect = _fit_rect(source_rect, content_rect)
            output_page.draw_rect(cell, color=(0.86, 0.86, 0.86), width=0.25)
            try:
                output_page.show_pdf_page(
                    target_rect,
                    embed_doc,
                    embed_page_index,
                    keep_proportion=True,
                )
            finally:
                if embed_doc is not source_doc:
                    embed_doc.close()


def _embedding_page(
    source_path: Path,
    source_doc: fitz.Document,
    source_page_index: int,
) -> tuple[fitz.Document, int, fitz.Rect]:
    source_page = source_doc[source_page_index]
    if source_page.rotation == 0:
        return source_doc, source_page_index, source_page.rect

    normalized_doc = fitz.open(source_path)
    normalized_doc.select([source_page_index])
    normalized_doc[0].remove_rotation()

    return normalized_doc, 0, normalized_doc[0].rect


def _output_page_size(source_doc: fitz.Document, request: ExportRequest) -> tuple[float, float]:
    if request.page_size == "source":
        first_page_rect = source_doc[0].rect
        return first_page_rect.width, first_page_rect.height
    if request.page_size == "a4-landscape":
        return A4_PORTRAIT[1], A4_PORTRAIT[0]

    return A4_PORTRAIT


def _grid_for_layout(layout: int, page_width: float, page_height: float) -> tuple[int, int]:
    is_landscape = page_width >= page_height

    if layout == 2:
        return (1, 2) if is_landscape else (2, 1)
    if layout == 4:
        return 2, 2
    if layout == 8:
        return (2, 4) if is_landscape else (4, 2)

    raise ValueError(f"Unsupported layout: {layout}")


def _cell_rect(
    row: int,
    col: int,
    rows: int,
    cols: int,
    page_width: float,
    page_height: float,
    margin: float,
    gap: float,
) -> fitz.Rect:
    usable_width = page_width - (margin * 2) - (gap * (cols - 1))
    usable_height = page_height - (margin * 2) - (gap * (rows - 1))

    if usable_width <= 0 or usable_height <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Margin and gap are too large for the output page size.",
        )

    cell_width = usable_width / cols
    cell_height = usable_height / rows
    x0 = margin + col * (cell_width + gap)
    y0 = margin + row * (cell_height + gap)

    return fitz.Rect(x0, y0, x0 + cell_width, y0 + cell_height)


def _fit_rect(source_rect: fitz.Rect, target_rect: fitz.Rect) -> fitz.Rect:
    source_width = source_rect.width
    source_height = source_rect.height
    scale = min(target_rect.width / source_width, target_rect.height / source_height)
    fitted_width = source_width * scale
    fitted_height = source_height * scale
    x0 = target_rect.x0 + (target_rect.width - fitted_width) / 2
    y0 = target_rect.y0 + (target_rect.height - fitted_height) / 2

    return fitz.Rect(x0, y0, x0 + fitted_width, y0 + fitted_height)


def _content_rect(cell_rect: fitz.Rect, padding: float) -> fitz.Rect:
    max_padding = min(cell_rect.width, cell_rect.height) / 2
    safe_padding = min(padding, max_padding)
    rect = fitz.Rect(cell_rect)
    rect.x0 += safe_padding
    rect.y0 += safe_padding
    rect.x1 -= safe_padding
    rect.y1 -= safe_padding

    if rect.width <= 0 or rect.height <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="cell_padding is too large for the grid cell.",
        )

    return rect
