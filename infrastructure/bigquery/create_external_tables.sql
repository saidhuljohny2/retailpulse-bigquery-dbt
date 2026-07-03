-- External table definitions for GCS-backed raw data
-- Replace placeholders before running

CREATE OR REPLACE EXTERNAL TABLE `${PROJECT_ID}.${DATASET_PREFIX}_raw.customers`
(
    customer_id INT64,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    city STRING,
    state STRING,
    country STRING,
    postal_code STRING,
    signup_date DATE,
    customer_status STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://${BUCKET_NAME}/raw/customers.csv'],
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `${PROJECT_ID}.${DATASET_PREFIX}_raw.products`
(
    product_id INT64,
    product_name STRING,
    category_id INT64,
    brand STRING,
    unit_price FLOAT64,
    cost_price FLOAT64,
    product_status STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://${BUCKET_NAME}/raw/products.csv'],
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `${PROJECT_ID}.${DATASET_PREFIX}_raw.orders`
(
    order_id INT64,
    customer_id INT64,
    order_date DATE,
    order_status STRING,
    payment_status STRING,
    shipping_city STRING,
    shipping_state STRING,
    shipping_country STRING,
    campaign_id INT64,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://${BUCKET_NAME}/raw/orders.csv'],
    skip_leading_rows = 1
);

-- Additional external tables follow the same pattern for:
-- categories, order_items, payments, returns, web_events, marketing_campaigns
