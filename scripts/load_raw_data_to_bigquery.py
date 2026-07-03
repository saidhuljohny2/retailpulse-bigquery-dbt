#!/usr/bin/env python3
"""Load raw CSV data from GCS into BigQuery with explicit schemas."""

from __future__ import annotations

import logging
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Explicit BigQuery schemas for each source table
TABLE_SCHEMAS: dict[str, list[bigquery.SchemaField]] = {
    "customers": [
        bigquery.SchemaField("customer_id", "INT64"),
        bigquery.SchemaField("first_name", "STRING"),
        bigquery.SchemaField("last_name", "STRING"),
        bigquery.SchemaField("email", "STRING"),
        bigquery.SchemaField("phone", "STRING"),
        bigquery.SchemaField("city", "STRING"),
        bigquery.SchemaField("state", "STRING"),
        bigquery.SchemaField("country", "STRING"),
        bigquery.SchemaField("postal_code", "STRING"),
        bigquery.SchemaField("signup_date", "DATE"),
        bigquery.SchemaField("customer_status", "STRING"),
        bigquery.SchemaField("created_at", "TIMESTAMP"),
        bigquery.SchemaField("updated_at", "TIMESTAMP"),
    ],
    "categories": [
        bigquery.SchemaField("category_id", "INT64"),
        bigquery.SchemaField("category_name", "STRING"),
        bigquery.SchemaField("department", "STRING"),
        bigquery.SchemaField("created_at", "TIMESTAMP"),
    ],
    "products": [
        bigquery.SchemaField("product_id", "INT64"),
        bigquery.SchemaField("product_name", "STRING"),
        bigquery.SchemaField("category_id", "INT64"),
        bigquery.SchemaField("brand", "STRING"),
        bigquery.SchemaField("unit_price", "FLOAT64"),
        bigquery.SchemaField("cost_price", "FLOAT64"),
        bigquery.SchemaField("product_status", "STRING"),
        bigquery.SchemaField("created_at", "TIMESTAMP"),
        bigquery.SchemaField("updated_at", "TIMESTAMP"),
    ],
    "orders": [
        bigquery.SchemaField("order_id", "INT64"),
        bigquery.SchemaField("customer_id", "INT64"),
        bigquery.SchemaField("order_date", "DATE"),
        bigquery.SchemaField("order_status", "STRING"),
        bigquery.SchemaField("payment_status", "STRING"),
        bigquery.SchemaField("shipping_city", "STRING"),
        bigquery.SchemaField("shipping_state", "STRING"),
        bigquery.SchemaField("shipping_country", "STRING"),
        bigquery.SchemaField("campaign_id", "INT64"),
        bigquery.SchemaField("created_at", "TIMESTAMP"),
        bigquery.SchemaField("updated_at", "TIMESTAMP"),
    ],
    "order_items": [
        bigquery.SchemaField("order_item_id", "INT64"),
        bigquery.SchemaField("order_id", "INT64"),
        bigquery.SchemaField("product_id", "INT64"),
        bigquery.SchemaField("quantity", "INT64"),
        bigquery.SchemaField("unit_price", "FLOAT64"),
        bigquery.SchemaField("discount_amount", "FLOAT64"),
        bigquery.SchemaField("tax_amount", "FLOAT64"),
        bigquery.SchemaField("created_at", "TIMESTAMP"),
    ],
    "payments": [
        bigquery.SchemaField("payment_id", "INT64"),
        bigquery.SchemaField("order_id", "INT64"),
        bigquery.SchemaField("payment_method", "STRING"),
        bigquery.SchemaField("payment_amount", "FLOAT64"),
        bigquery.SchemaField("payment_status", "STRING"),
        bigquery.SchemaField("payment_date", "DATE"),
    ],
    "returns": [
        bigquery.SchemaField("return_id", "INT64"),
        bigquery.SchemaField("order_item_id", "INT64"),
        bigquery.SchemaField("return_date", "DATE"),
        bigquery.SchemaField("return_reason", "STRING"),
        bigquery.SchemaField("refund_amount", "FLOAT64"),
        bigquery.SchemaField("return_status", "STRING"),
    ],
    "web_events": [
        bigquery.SchemaField("event_id", "STRING"),
        bigquery.SchemaField("customer_id", "INT64"),
        bigquery.SchemaField("session_id", "STRING"),
        bigquery.SchemaField("event_timestamp", "TIMESTAMP"),
        bigquery.SchemaField("event_type", "STRING"),
        bigquery.SchemaField("page_name", "STRING"),
        bigquery.SchemaField("product_id", "INT64"),
        bigquery.SchemaField("device_type", "STRING"),
        bigquery.SchemaField("traffic_source", "STRING"),
        bigquery.SchemaField("campaign_id", "INT64"),
    ],
    "marketing_campaigns": [
        bigquery.SchemaField("campaign_id", "INT64"),
        bigquery.SchemaField("campaign_name", "STRING"),
        bigquery.SchemaField("channel", "STRING"),
        bigquery.SchemaField("campaign_start_date", "DATE"),
        bigquery.SchemaField("campaign_end_date", "DATE"),
        bigquery.SchemaField("budget_amount", "FLOAT64"),
        bigquery.SchemaField("campaign_status", "STRING"),
    ],
}

METADATA_FIELDS = [
    bigquery.SchemaField("_ingested_at", "TIMESTAMP"),
    bigquery.SchemaField("_source_file", "STRING"),
    bigquery.SchemaField("_batch_id", "STRING"),
]


def get_config() -> tuple[str, str, str, str]:
    """Load configuration from environment variables."""
    return (
        os.environ["GCP_PROJECT_ID"],
        os.environ["GCS_BUCKET_NAME"],
        os.environ.get("DBT_DATASET_PREFIX", "retailpulse"),
        os.environ.get("BATCH_ID", str(uuid.uuid4())),
    )


def load_table_from_gcs(
    client: bigquery.Client,
    project_id: str,
    dataset_id: str,
    table_name: str,
    bucket_name: str,
    batch_id: str,
    write_disposition: str = "WRITE_TRUNCATE",
) -> None:
    """Load a CSV file from GCS into BigQuery with explicit schema."""
    table_id = f"{project_id}.{dataset_id}.{table_name}"
    gcs_uri = f"gs://{bucket_name}/raw/{table_name}.csv"
    source_file = f"raw/{table_name}.csv"

    schema = TABLE_SCHEMAS[table_name] + METADATA_FIELDS

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        skip_leading_rows=1,
        source_format=bigquery.SourceFormat.CSV,
        write_disposition=write_disposition,
        allow_quoted_newlines=True,
        null_marker="",
    )

    # Use a query to add metadata columns after load via temp table approach
    # Load to temp table first, then insert with metadata
    temp_table_id = f"{table_id}_temp_{batch_id.replace('-', '_')[:8]}"

    temp_config = bigquery.LoadJobConfig(
        schema=TABLE_SCHEMAS[table_name],
        skip_leading_rows=1,
        source_format=bigquery.SourceFormat.CSV,
        write_disposition="WRITE_TRUNCATE",
        allow_quoted_newlines=True,
        null_marker="",
    )

    logger.info("Loading %s from %s", table_name, gcs_uri)
    load_job = client.load_table_from_uri(
        gcs_uri, temp_table_id, job_config=temp_config
    )
    load_job.result()

    ingested_at = datetime.now(timezone.utc).isoformat()

    # Create final table with metadata columns
    insert_sql = f"""
    CREATE OR REPLACE TABLE `{table_id}` AS
    SELECT
        *,
        TIMESTAMP('{ingested_at}') AS _ingested_at,
        '{source_file}' AS _source_file,
        '{batch_id}' AS _batch_id
    FROM `{temp_table_id}`
    """

    query_job = client.query(insert_sql)
    query_job.result()

    # Clean up temp table
    client.delete_table(temp_table_id, not_found_ok=True)
    logger.info("Loaded %d rows into %s", query_job.num_dml_affected_rows or 0, table_id)


def load_from_local(
    client: bigquery.Client,
    project_id: str,
    dataset_id: str,
    table_name: str,
    local_path: Path,
    batch_id: str,
) -> None:
    """Load a local CSV file into BigQuery (fallback when GCS unavailable)."""
    table_id = f"{project_id}.{dataset_id}.{table_name}"
    source_file = local_path.name
    temp_table_id = f"{table_id}_temp_{batch_id.replace('-', '_')[:8]}"

    temp_config = bigquery.LoadJobConfig(
        schema=TABLE_SCHEMAS[table_name],
        skip_leading_rows=1,
        source_format=bigquery.SourceFormat.CSV,
        write_disposition="WRITE_TRUNCATE",
        allow_quoted_newlines=True,
        null_marker="",
    )

    logger.info("Loading %s from local file %s", table_name, local_path)
    with open(local_path, "rb") as f:
        load_job = client.load_table_from_file(f, temp_table_id, job_config=temp_config)
    load_job.result()

    ingested_at = datetime.now(timezone.utc).isoformat()
    insert_sql = f"""
    CREATE OR REPLACE TABLE `{table_id}` AS
    SELECT
        *,
        TIMESTAMP('{ingested_at}') AS _ingested_at,
        '{source_file}' AS _source_file,
        '{batch_id}' AS _batch_id
    FROM `{temp_table_id}`
    """
    query_job = client.query(insert_sql)
    query_job.result()
    client.delete_table(temp_table_id, not_found_ok=True)
    logger.info("Loaded table %s from local file.", table_id)


def main() -> int:
    """Load all source tables into retailpulse_raw dataset."""
    project_root = Path(__file__).resolve().parent.parent
    load_dotenv(project_root / ".env")

    try:
        project_id, bucket_name, prefix, batch_id = get_config()
    except KeyError as exc:
        logger.error("Missing required environment variable: %s", exc)
        return 1

    dataset_id = f"{prefix}_raw"
    client = bigquery.Client(project=project_id)
    data_dir = project_root / "data" / "sample_data"
    use_local = os.getenv("LOAD_FROM_LOCAL", "false").lower() == "true"

    for table_name in TABLE_SCHEMAS:
        try:
            if use_local:
                local_path = data_dir / f"{table_name}.csv"
                if not local_path.exists():
                    logger.warning("Local file not found: %s", local_path)
                    continue
                load_from_local(
                    client, project_id, dataset_id, table_name, local_path, batch_id
                )
            else:
                load_table_from_gcs(
                    client, project_id, dataset_id, table_name,
                    bucket_name, batch_id,
                )
        except Exception as exc:
            logger.error("Failed to load %s: %s", table_name, exc)
            if not use_local:
                logger.info(
                    "Tip: Set LOAD_FROM_LOCAL=true to load from data/sample_data/"
                )
            return 1

    logger.info("All tables loaded into %s.%s", project_id, dataset_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
