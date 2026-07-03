with orders as (

    select * from {{ ref('fct_orders') }}
    where order_status in ('completed', 'shipped')

),

returns as (

    select
        cast(r.return_date as date) as return_date,
        sum(r.refund_amount) as return_amount
    from {{ ref('fct_returns') }} as r
    where r.return_status = 'approved'
    group by 1

),

daily_sales as (

    select
        o.order_date as sales_date,
        count(distinct o.order_id) as total_orders,
        count(distinct o.customer_id) as total_customers,
        sum(o.gross_sales) as gross_sales,
        sum(o.discount_amount) as discount_amount,
        sum(o.net_sales) as net_sales,
        sum(o.profit) as total_profit,
        safe_divide(sum(o.net_sales), count(distinct o.order_id)) as average_order_value
    from orders as o
    group by 1

)

select
    ds.sales_date,
    ds.total_orders,
    ds.total_customers,
    ds.gross_sales,
    ds.discount_amount,
    ds.net_sales,
    ds.total_profit,
    ds.average_order_value,
    coalesce(r.return_amount, 0.0) as return_amount,
    safe_divide(coalesce(r.return_amount, 0.0), nullif(ds.net_sales, 0)) as return_rate,
    {{ audit_columns() }}
from daily_sales as ds
left join returns as r
    on ds.sales_date = r.return_date
