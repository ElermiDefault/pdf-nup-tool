from pydantic import BaseModel, Field


class PdfUploadResponse(BaseModel):
    file_id: str
    filename: str
    page_count: int


class PdfInfoResponse(BaseModel):
    file_id: str
    filename: str
    page_count: int


class MergeRule(BaseModel):
    start_page: int = Field(..., ge=1)
    end_page: int = Field(..., ge=1)
    layout: int = Field(..., description="N-up layout, for example 2, 3, 4, 5, or 8")


class PageSequenceItem(BaseModel):
    file_id: str = Field(..., min_length=1)
    page_number: int = Field(..., ge=1)


class OrderedMergeRule(BaseModel):
    start_index: int = Field(..., ge=1)
    end_index: int = Field(..., ge=1)
    layout: int = Field(..., description="N-up layout, for example 2, 3, 4, 5, or 8")


class ExportRequest(BaseModel):
    rules: list[MergeRule] = Field(default_factory=list)
    page_size: str = Field(default="a4", description="a4, a4-landscape, or source")
    margin: float = Field(default=24, ge=0)
    gap: float = Field(default=12, ge=0)
    cell_padding: float = Field(default=6, ge=0)


class BatchExportRequest(BaseModel):
    pages: list[PageSequenceItem] = Field(default_factory=list)
    rules: list[OrderedMergeRule] = Field(default_factory=list)
    page_size: str = Field(default="a4", description="a4, a4-landscape, or source")
    margin: float = Field(default=24, ge=0)
    gap: float = Field(default=12, ge=0)
    cell_padding: float = Field(default=6, ge=0)


class ExportResponse(BaseModel):
    file_id: str
    status: str
    message: str
