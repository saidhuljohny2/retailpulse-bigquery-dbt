#!/usr/bin/env python3
"""Validate RetailPulse environment configuration."""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

REQUIRED_ENV_VARS = [
    "GCP_PROJECT_ID",
    "GCP_REGION",
    "GCS_BUCKET_NAME",
    "DBT_DATASET_PREFIX",
]

OPTIONAL_ENV_VARS = [
    "GOOGLE_APPLICATION_CREDENTIALS",
    "DBT_TARGET",
    "BATCH_ID",
]


def validate_env_vars() -> list[str]:
    """Check required environment variables are set."""
    missing = [var for var in REQUIRED_ENV_VARS if not os.getenv(var)]
    return missing


def validate_credentials() -> bool:
    """Validate service account credentials file exists if configured."""
    creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not creds_path:
        logger.warning(
            "GOOGLE_APPLICATION_CREDENTIALS not set. "
            "Using Application Default Credentials (gcloud auth)."
        )
        return True

    path = Path(creds_path)
    if not path.exists():
        logger.error("Credentials file not found: %s", creds_path)
        return False

    logger.info("Credentials file found: %s", creds_path)
    return True


def validate_directories() -> bool:
    """Validate required project directories exist."""
    project_root = Path(__file__).resolve().parent.parent
    required_dirs = [
        project_root / "data" / "sample_data",
        project_root / "dbt_project",
        project_root / "scripts",
    ]
    all_exist = all(d.exists() for d in required_dirs)
    if not all_exist:
        logger.error("One or more required directories are missing.")
        return False
    logger.info("All required directories exist.")
    return True


def main() -> int:
    """Run all environment validations."""
    project_root = Path(__file__).resolve().parent.parent
    load_dotenv(project_root / ".env")

    logger.info("Validating RetailPulse environment...")
    logger.info("Project ID: %s", os.getenv("GCP_PROJECT_ID", "NOT SET"))
    logger.info("Region: %s", os.getenv("GCP_REGION", "NOT SET"))
    logger.info("GCS Bucket: %s", os.getenv("GCS_BUCKET_NAME", "NOT SET"))
    logger.info("Dataset Prefix: %s", os.getenv("DBT_DATASET_PREFIX", "NOT SET"))
    logger.info("dbt Target: %s", os.getenv("DBT_TARGET", "dev"))

    missing = validate_env_vars()
    if missing:
        logger.error("Missing required environment variables: %s", ", ".join(missing))
        logger.info("Copy .env.example to .env and configure values.")
        return 1

    checks = [
        validate_credentials(),
        validate_directories(),
    ]

    if all(checks):
        logger.info("Environment validation passed.")
        return 0

    logger.error("Environment validation failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
