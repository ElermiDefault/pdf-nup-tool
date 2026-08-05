import os

from fastapi import APIRouter


router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict[str, str]:
    payload = {"status": "ok"}
    instance_id = os.environ.get("PDFNUPTOOL_INSTANCE_ID")
    if instance_id:
        payload["instance_id"] = instance_id

    return payload
