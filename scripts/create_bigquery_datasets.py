#!/usr/bin/env python3
"""Create BigQuery datasets for RetailPulse."""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

DATASET_SUFFIXES = [
    "raw",
    "staging",
    "intermediate",
    "analytics",
    "reporting",
    "snapshots",
]


def get_dataset_ids(prefix: str) -> list[str]:
    """Build full dataset IDs from prefix and suffixes."""
    return [f"{prefix}_{suffix}" for suffix in DATASET_SUFFIXES]


def create_dataset(
    client: bigquery.Client,
    project_id: str,
    dataset_id: str,
    location: str,
) -> None:
    """Create a BigQuery dataset if it does not exist."""
    full_id = f"{project_id}.{dataset_id}"
    try:
        client.get_dataset(full_id)
        logger.info("Dataset already exists: %s", full_id)
    except Exception:
        dataset = bigquery.Dataset(full_id)
        dataset.location = location
        dataset.description = f"RetailPulse {dataset_id} dataset"
        client.create_dataset(dataset, exists_ok=True)
        logger.info("Created dataset: %s", full_id)


def main() -> int:
    """Create all RetailPulse BigQuery datasets."""
    project_root = Path(__file__).resolve().parent.parent
    load_dotenv(project_root / ".env")

    project_id = os.getenv("GCP_PROJECT_ID")
    region = os.getenv("GCP_REGION", "us-central1")
    prefix = os.getenv("DBT_DATASET_PREFIX", "retailpulse")

    if not project_id:
        logger.error("GCP_PROJECT_ID is required.")
        return 1

    client = bigquery.Client(project=project_id)
    datasets = get_dataset_ids(prefix)

    for dataset_id in datasets:
        create_dataset(client, project_id, dataset_id, region)

    logger.info("All datasets ready in project %s.", project_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
