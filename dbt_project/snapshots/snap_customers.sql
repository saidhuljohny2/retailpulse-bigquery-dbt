{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    country,
    customer_status,
    updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}
