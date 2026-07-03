-- Create RetailPulse BigQuery datasets
-- Replace ${PROJECT_ID} and ${DATASET_PREFIX} before running

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_raw`
OPTIONS (
    description = 'Raw ingested retail data from GCS',
    location = '${REGION}'
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_staging`
OPTIONS (
    description = 'dbt staging layer views',
    location = '${REGION}'
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_intermediate`
OPTIONS (
    description = 'dbt intermediate transformation layer',
    location = '${REGION}'
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_analytics`
OPTIONS (
    description = 'dbt core analytics star schema',
    location = '${REGION}'
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_reporting`
OPTIONS (
    description = 'Looker Studio-ready reporting marts',
    location = '${REGION}'
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_PREFIX}_snapshots`
OPTIONS (
    description = 'dbt SCD Type 2 snapshots',
    location = '${REGION}'
);
