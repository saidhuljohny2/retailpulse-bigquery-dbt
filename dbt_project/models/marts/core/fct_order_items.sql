{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_item_id',
        partition_by={
            'field': 'order_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['product_id', 'category_id', 'customer_id']
    )
}}

with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

orders as (

    select
        order_id,
        customer_id,
        order_date
    from {{ ref('int_orders_enriched') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['oi.order_item_id']) }} as order_item_key,
        oi.order_item_id,
        oi.order_id,
        o.customer_id,
        o.order_date,
        oi.product_id,
        oi.category_id,
        oi.product_name,
        oi.category_name,
        oi.department,
        oi.brand,
        oi.quantity,
        oi.unit_price,
        oi.discount_amount,
        oi.tax_amount,
        oi.gross_sales,
        oi.total_discount,
        oi.total_tax,
        oi.net_sales,
        oi.profit,
        oi.created_at,
        {{ audit_columns() }}
    from order_items as oi
    inner join orders as o
        on oi.order_id = o.order_id

    {% if is_incremental() %}
        where o.order_date >= date_sub(
            current_date(),
            interval {{ var('incremental_lookback_days', 7) }} day
        )
    {% endif %}

)

select * from final
