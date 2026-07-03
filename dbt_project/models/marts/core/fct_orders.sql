{{
    config(
        materialized='table',
        partition_by={
            'field': 'order_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['customer_id', 'order_status']
    )
}}

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_totals as (

    select
        order_id,
        sum(net_sales) as order_net_sales,
        sum(gross_sales) as order_gross_sales,
        sum(total_discount) as order_discount,
        sum(profit) as order_profit
    from {{ ref('int_order_items_enriched') }}
    group by 1

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_key,
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.payment_status,
        o.shipping_city,
        o.shipping_state,
        o.shipping_country,
        o.campaign_id,
        o.campaign_name,
        o.campaign_channel,
        coalesce(ot.order_gross_sales, 0.0) as gross_sales,
        coalesce(ot.order_discount, 0.0) as discount_amount,
        coalesce(ot.order_net_sales, 0.0) as net_sales,
        coalesce(ot.order_profit, 0.0) as profit,
        o.created_at,
        o.updated_at,
        {{ audit_columns() }}
    from orders as o
    left join order_totals as ot
        on o.order_id = ot.order_id

)

select * from final
