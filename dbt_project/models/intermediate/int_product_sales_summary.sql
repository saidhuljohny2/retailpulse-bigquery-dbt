with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

returns as (

    select
        r.order_item_id,
        sum(r.refund_amount) as total_refund_amount,
        count(*) as return_count
    from {{ ref('stg_returns') }} as r
    where r.return_status = 'approved'
    group by 1

),

product_sales as (

    select
        oi.product_id,
        oi.product_name,
        oi.category_id,
        oi.category_name,
        oi.department,
        oi.brand,
        sum(oi.quantity) as total_units_sold,
        sum(oi.gross_sales) as gross_sales,
        sum(oi.total_discount) as total_discount,
        sum(oi.net_sales) as net_sales,
        sum(oi.profit) as total_profit,
        count(distinct oi.order_id) as total_orders,
        coalesce(sum(r.return_count), 0) as total_returns,
        coalesce(sum(r.total_refund_amount), 0.0) as total_refund_amount
    from order_items as oi
    left join returns as r
        on oi.order_item_id = r.order_item_id
    group by 1, 2, 3, 4, 5, 6

)

select
    *,
    safe_divide(total_returns, total_units_sold) as return_rate,
    safe_divide(total_profit, nullif(net_sales, 0)) as profit_margin,
    {{ audit_columns() }}
from product_sales
