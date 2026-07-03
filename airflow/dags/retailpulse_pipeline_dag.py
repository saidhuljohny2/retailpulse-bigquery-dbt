"""
RetailPulse end-to-end data pipeline DAG.

Compatible with Google Cloud Composer / Apache Airflow 2.x.
"""

from __future__ import annotations

import logging
import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

logger = logging.getLogger(__name__)

# Environment-based configuration
ENV = os.getenv("AIRFLOW_ENV", "dev")
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID", "")
GCS_BUCKET_NAME = os.getenv("GCS_BUCKET_NAME", "")
DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "/opt/airflow/dbt_project")
SCRIPTS_DIR = os.getenv("SCRIPTS_DIR", "/opt/airflow/scripts")
DBT_TARGET = os.getenv("DBT_TARGET", ENV)

DEFAULT_ARGS = {
    "owner": "retailpulse",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}


def on_failure_callback(context: dict) -> None:
    """Log pipeline failure details."""
    task_instance = context.get("task_instance")
    logger.error(
        "Task %s failed in DAG %s. Execution date: %s",
        task_instance.task_id,
        task_instance.dag_id,
        context.get("execution_date"),
    )


def on_success_callback(context: dict) -> None:
    """Log pipeline completion."""
    logger.info(
        "RetailPulse pipeline completed successfully. DAG run: %s",
        context.get("run_id"),
    )


with DAG(
    dag_id="retailpulse_pipeline",
    description="RetailPulse e-commerce analytics pipeline",
    default_args=DEFAULT_ARGS,
    schedule_interval="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["retailpulse", "dbt", "bigquery"],
    on_failure_callback=on_failure_callback,
) as dag:

    generate_data = BashOperator(
        task_id="generate_source_data",
        bash_command=f"python {SCRIPTS_DIR}/generate_sample_data.py",
        env={
            "GCP_PROJECT_ID": GCP_PROJECT_ID,
            "GCS_BUCKET_NAME": GCS_BUCKET_NAME,
        },
    )

    upload_to_gcs = BashOperator(
        task_id="upload_to_gcs",
        bash_command=f"python {SCRIPTS_DIR}/upload_to_gcs.py",
        env={
            "GCP_PROJECT_ID": GCP_PROJECT_ID,
            "GCS_BUCKET_NAME": GCS_BUCKET_NAME,
        },
    )

    create_datasets = BashOperator(
        task_id="create_bigquery_datasets",
        bash_command=f"python {SCRIPTS_DIR}/create_bigquery_datasets.py",
        env={
            "GCP_PROJECT_ID": GCP_PROJECT_ID,
            "DBT_DATASET_PREFIX": os.getenv("DBT_DATASET_PREFIX", "retailpulse"),
        },
    )

    load_raw_data = BashOperator(
        task_id="load_raw_data_to_bigquery",
        bash_command=f"python {SCRIPTS_DIR}/load_raw_data_to_bigquery.py",
        env={
            "GCP_PROJECT_ID": GCP_PROJECT_ID,
            "GCS_BUCKET_NAME": GCS_BUCKET_NAME,
            "DBT_DATASET_PREFIX": os.getenv("DBT_DATASET_PREFIX", "retailpulse"),
            "BATCH_ID": "{{ run_id }}",
        },
    )

    dbt_source_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt source freshness --profiles-dir . --target {DBT_TARGET}"
        ),
    )

    dbt_snapshots = BashOperator(
        task_id="dbt_snapshots",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt snapshot --profiles-dir . --target {DBT_TARGET}"
        ),
    )

    dbt_run = BashOperator(
        task_id="dbt_run_models",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --profiles-dir . --target {DBT_TARGET}"
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt test --profiles-dir . --target {DBT_TARGET}"
        ),
    )

    dbt_docs = BashOperator(
        task_id="dbt_generate_docs",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt docs generate --profiles-dir . --target {DBT_TARGET}"
        ),
    )

    pipeline_complete = PythonOperator(
        task_id="pipeline_completion_log",
        python_callable=on_success_callback,
        provide_context=True,
    )

    # Task dependencies
    generate_data >> upload_to_gcs >> create_datasets >> load_raw_data
    load_raw_data >> dbt_source_freshness >> dbt_snapshots >> dbt_run
    dbt_run >> dbt_test >> dbt_docs >> pipeline_complete
