with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

order_totals as (

    select
        order_id,
        sum(gross_sales) as order_gross_sales,
        sum(total_discount) as order_discount,
        sum(total_tax) as order_tax,
        sum(net_sales) as order_net_sales,
        sum(profit) as order_profit,
        count(*) as item_count
    from order_items
    group by 1

),

customer_summary as (

    select
        o.customer_id,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        count(distinct o.order_id) as total_orders,
        sum(ot.order_gross_sales) as total_gross_sales,
        sum(ot.order_discount) as total_discount,
        sum(ot.order_net_sales) as total_net_sales,
        sum(ot.order_profit) as total_profit,
        avg(ot.order_net_sales) as average_order_value,
        date_diff(current_date(), max(o.order_date), day) as days_since_last_order
    from orders as o
    inner join order_totals as ot
        on o.order_id = ot.order_id
    where o.order_status in ('completed', 'shipped')
    group by 1

)

select
    *,
    {{ audit_columns() }}
from customer_summary
