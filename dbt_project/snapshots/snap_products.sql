{% snapshot snap_products %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

select
    product_id,
    product_name,
    category_id,
    unit_price,
    cost_price,
    product_status,
    updated_at
from {{ ref('stg_products') }}

{% endsnapshot %}
