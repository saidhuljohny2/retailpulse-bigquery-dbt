{{
    config(
        materialized='table',
        partition_by={
            'field': 'return_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['order_item_id', 'return_reason']
    )
}}

with returns as (

    select * from {{ ref('stg_returns') }}

),

order_items as (

    select
        order_item_id,
        order_id,
        product_id,
        net_sales
    from {{ ref('int_order_items_enriched') }}

),

orders as (

    select
        order_id,
        customer_id
    from {{ ref('int_orders_enriched') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['r.return_id']) }} as return_key,
        r.return_id,
        r.order_item_id,
        oi.order_id,
        oi.product_id,
        o.customer_id,
        r.return_date,
        r.return_reason,
        r.refund_amount,
        r.return_status,
        oi.net_sales as item_net_sales,
        {{ audit_columns() }}
    from returns as r
    inner join order_items as oi
        on r.order_item_id = oi.order_item_id
    inner join orders as o
        on oi.order_id = o.order_id

)

select * from final
