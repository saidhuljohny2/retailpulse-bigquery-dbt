.PHONY: help setup venv install validate generate upload create-datasets load dbt-deps dbt-run dbt-test dbt-docs dbt-build pipeline clean

PYTHON := python3
VENV := .venv
PIP := $(VENV)/bin/pip
PYTHON_VENV := $(VENV)/bin/python
DBT := $(VENV)/bin/dbt
DBT_DIR := dbt_project

help:
	@echo "RetailPulse - Analytics Engineering Platform"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          Create venv and install dependencies"
	@echo "  make validate       Validate environment configuration"
	@echo ""
	@echo "Data Pipeline:"
	@echo "  make generate       Generate synthetic CSV data"
	@echo "  make upload         Upload CSV files to GCS"
	@echo "  make create-datasets Create BigQuery datasets"
	@echo "  make load           Load raw data into BigQuery"
	@echo "  make pipeline       Run full data pipeline (generate -> load)"
	@echo ""
	@echo "dbt:"
	@echo "  make dbt-deps       Install dbt packages"
	@echo "  make dbt-run        Run dbt models"
	@echo "  make dbt-test       Run dbt tests"
	@echo "  make dbt-docs       Generate dbt documentation"
	@echo "  make dbt-build      Run dbt build (models + tests + snapshots)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          Remove generated data and dbt artifacts"

setup: venv install

venv:
	$(PYTHON) -m venv $(VENV)

install: venv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

validate:
	$(PYTHON_VENV) scripts/validate_environment.py

generate:
	$(PYTHON_VENV) scripts/generate_sample_data.py

upload:
	$(PYTHON_VENV) scripts/upload_to_gcs.py

create-datasets:
	$(PYTHON_VENV) scripts/create_bigquery_datasets.py

load:
	$(PYTHON_VENV) scripts/load_raw_data_to_bigquery.py

pipeline: generate upload create-datasets load

dbt-deps:
	cd $(DBT_DIR) && ../$(DBT) deps --profiles-dir .

dbt-run:
	cd $(DBT_DIR) && ../$(DBT) run --profiles-dir .

dbt-test:
	cd $(DBT_DIR) && ../$(DBT) test --profiles-dir .

dbt-docs:
	cd $(DBT_DIR) && ../$(DBT) docs generate --profiles-dir .

dbt-build:
	cd $(DBT_DIR) && ../$(DBT) build --profiles-dir .

clean:
	rm -rf data/sample_data/*.csv
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/dbt_packages $(DBT_DIR)/logs
	rm -rf $(VENV)
