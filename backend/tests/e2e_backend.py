from __future__ import annotations

import asyncio
import sys
from pathlib import Path

import fitz


BACKEND_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = BACKEND_DIR.parent
sys.path.insert(0, str(BACKEND_DIR))

from app.models.pdf import ExportRequest, MergeRule  # noqa: E402
from app.services.pdf_exporter import export_pdf_with_rules  # noqa: E402
from app.services.pdf_store import get_pdf_info, get_pdf_path, save_uploaded_pdf  # noqa: E402
from app.services.pdf_thumbnailer import render_thumbnail  # noqa: E402


class FakeUploadFile:
    def __init__(self, path: Path) -> None:
        self.filename = path.name
        self.content_type = "application/pdf"
        self._path = path

    async def read(self) -> bytes:
        return self._path.read_bytes()


def main() -> None:
    sample_pdf = _sample_pdf()

    upload = asyncio.run(save_uploaded_pdf(FakeUploadFile(sample_pdf)))
    assert upload.page_count == 38

    info = get_pdf_info(upload.file_id)
    assert info.file_id == upload.file_id
    assert info.page_count == 38

    uploaded_pdf = get_pdf_path(upload.file_id)
    _assert_pdf(uploaded_pdf, expected_pages=38)

    thumbnails = _render_required_thumbnails(upload.file_id, uploaded_pdf)
    export_3up = _export_and_verify_3up(uploaded_pdf)
    export_4up = _export_and_verify_4up(uploaded_pdf)
    export_5up = _export_and_verify_5up(uploaded_pdf)
    export_8up = _export_and_verify_8up(uploaded_pdf)

    print("backend e2e ok")
    print(f"file_id={upload.file_id}")
    print(f"uploaded_pdf={uploaded_pdf}")
    print("thumbnails:")
    for path in thumbnails:
        print(f"  {path}")
    for label, path in [
        ("export_3up", export_3up),
        ("export_4up", export_4up),
        ("export_5up", export_5up),
        ("export_8up", export_8up),
    ]:
        print(f"{label}={path}")


def _sample_pdf() -> Path:
    local_sample = PROJECT_DIR / "samples" / "sample.pdf"
    if local_sample.exists():
        return local_sample

    generated_sample = PROJECT_DIR / "tmp" / "generated-e2e-sample.pdf"
    generated_sample.parent.mkdir(parents=True, exist_ok=True)
    _create_generated_sample(generated_sample)

    return generated_sample


def _create_generated_sample(path: Path) -> None:
    doc = fitz.open()
    page_specs = [(612, 792, 0)] * 25
    page_specs.extend(
        [
            (4051, 2682, 270),
            (2018, 1581, 270),
            (2123, 1646, 270),
            (595, 842, 0),
            (842, 595, 270),
            (2062, 1459, 270),
            (842, 595, 90),
            (2037, 1430, 0),
            (842, 595, 90),
            (595, 842, 0),
            (595, 842, 0),
            (842, 595, 90),
            (842, 595, 90),
        ]
    )

    for index, (width, height, rotation) in enumerate(page_specs, start=1):
        page = doc.new_page(width=width, height=height)
        page.insert_text((72, min(height - 72, 160)), f"Generated test page {index}", fontsize=48)
        page.draw_rect(fitz.Rect(48, 48, width - 48, height - 48), color=(0.8, 0.1, 0.1), width=4)
        page.draw_line((48, 48), (width - 48, height - 48), color=(0.1, 0.3, 0.8), width=2)
        page.draw_line((width - 48, 48), (48, height - 48), color=(0.1, 0.3, 0.8), width=2)
        if rotation:
            page.set_rotation(rotation)

    doc.save(path)
    doc.close()


def _render_required_thumbnails(file_id: str, uploaded_pdf: Path) -> list[Path]:
    thumbnails = []
    for page_number in [1, 26, 30, 32, 38]:
        thumbnail = render_thumbnail(uploaded_pdf, file_id, page_number, width=240)
        assert thumbnail.exists()
        with fitz.open(thumbnail) as image_doc:
            assert image_doc.page_count == 1
            assert image_doc[0].rect.width > 0
            assert image_doc[0].rect.height > 0
        thumbnails.append(thumbnail)

    return thumbnails


def _export_and_verify_4up(uploaded_pdf: Path) -> Path:
    request = ExportRequest(
        rules=[MergeRule(start_page=26, end_page=33, layout=4)],
        page_size="a4",
        margin=24,
        gap=12,
        cell_padding=6,
    )
    output = export_pdf_with_rules(uploaded_pdf, request)
    _assert_pdf(output, expected_pages=32)

    preview = PROJECT_DIR / "tmp" / "e2e-4up-page27.png"
    _render_page(output, page_index=26, output_png=preview)
    _assert_a4_page(output, page_index=26)

    return output


def _export_and_verify_3up(uploaded_pdf: Path) -> Path:
    request = ExportRequest(
        rules=[MergeRule(start_page=26, end_page=33, layout=3)],
        page_size="a4",
        margin=24,
        gap=12,
        cell_padding=6,
    )
    output = export_pdf_with_rules(uploaded_pdf, request)
    _assert_pdf(output, expected_pages=33)

    preview = PROJECT_DIR / "tmp" / "e2e-3up-page26.png"
    _render_page(output, page_index=25, output_png=preview)
    _assert_a4_page(output, page_index=25)

    return output


def _export_and_verify_5up(uploaded_pdf: Path) -> Path:
    request = ExportRequest(
        rules=[MergeRule(start_page=26, end_page=33, layout=5)],
        page_size="a4",
        margin=24,
        gap=12,
        cell_padding=6,
    )
    output = export_pdf_with_rules(uploaded_pdf, request)
    _assert_pdf(output, expected_pages=32)

    preview = PROJECT_DIR / "tmp" / "e2e-5up-page26.png"
    _render_page(output, page_index=25, output_png=preview)
    _assert_a4_page(output, page_index=25)

    return output


def _export_and_verify_8up(uploaded_pdf: Path) -> Path:
    request = ExportRequest(
        rules=[MergeRule(start_page=26, end_page=33, layout=8)],
        page_size="a4",
        margin=24,
        gap=12,
        cell_padding=6,
    )
    output = export_pdf_with_rules(uploaded_pdf, request)
    _assert_pdf(output, expected_pages=31)

    preview = PROJECT_DIR / "tmp" / "e2e-8up-page26.png"
    _render_page(output, page_index=25, output_png=preview)
    _assert_a4_page(output, page_index=25)

    return output


def _assert_pdf(path: Path, expected_pages: int) -> None:
    assert path.exists(), path
    with fitz.open(path) as doc:
        assert doc.page_count == expected_pages, (path, doc.page_count, expected_pages)
        for page_index in [0, doc.page_count - 1]:
            pixmap = doc[page_index].get_pixmap(matrix=fitz.Matrix(0.1, 0.1), alpha=False)
            assert pixmap.width > 0
            assert pixmap.height > 0


def _assert_a4_page(path: Path, page_index: int) -> None:
    with fitz.open(path) as doc:
        page = doc[page_index]
        assert (round(page.rect.width, 2), round(page.rect.height, 2)) == (595.0, 842.0)


def _render_page(path: Path, page_index: int, output_png: Path) -> None:
    output_png.parent.mkdir(parents=True, exist_ok=True)
    with fitz.open(path) as doc:
        page = doc[page_index]
        pixmap = page.get_pixmap(matrix=fitz.Matrix(1.0, 1.0), alpha=False)
        pixmap.save(output_png)
        assert output_png.exists()


if __name__ == "__main__":
    main()
