#!/usr/bin/env python3
"""Upload sample CSV files to Google Cloud Storage."""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import storage

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

SOURCE_TABLES = [
    "customers",
    "categories",
    "products",
    "orders",
    "order_items",
    "payments",
    "returns",
    "web_events",
    "marketing_campaigns",
]


def get_config() -> tuple[str, str, Path]:
    """Load GCS configuration from environment."""
    project_id = os.environ["GCP_PROJECT_ID"]
    bucket_name = os.environ["GCS_BUCKET_NAME"]
    project_root = Path(__file__).resolve().parent.parent
    data_dir = project_root / "data" / "sample_data"
    return project_id, bucket_name, data_dir


def upload_file(
    client: storage.Client,
    bucket_name: str,
    local_path: Path,
    gcs_prefix: str = "raw",
) -> str:
    """Upload a single file to GCS and return the GCS URI."""
    bucket = client.bucket(bucket_name)
    blob_name = f"{gcs_prefix}/{local_path.name}"
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(local_path))
    gcs_uri = f"gs://{bucket_name}/{blob_name}"
    logger.info("Uploaded %s -> %s", local_path.name, gcs_uri)
    return gcs_uri


def main() -> int:
    """Upload all sample CSV files to GCS."""
    project_root = Path(__file__).resolve().parent.parent
    load_dotenv(project_root / ".env")

    try:
        project_id, bucket_name, data_dir = get_config()
    except KeyError as exc:
        logger.error("Missing required environment variable: %s", exc)
        return 1

    if not data_dir.exists():
        logger.error("Data directory not found: %s", data_dir)
        logger.info("Run: python scripts/generate_sample_data.py")
        return 1

    client = storage.Client(project=project_id)
    uploaded = 0

    for table in SOURCE_TABLES:
        csv_path = data_dir / f"{table}.csv"
        if not csv_path.exists():
            logger.warning("Skipping missing file: %s", csv_path)
            continue
        upload_file(client, bucket_name, csv_path)
        uploaded += 1

    logger.info("Uploaded %d files to gs://%s/raw/", uploaded, bucket_name)
    return 0 if uploaded > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
