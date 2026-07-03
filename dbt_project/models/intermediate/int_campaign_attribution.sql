with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

order_totals as (

    select
        order_id,
        sum(net_sales) as order_net_sales
    from order_items
    group by 1

),

campaign_attribution as (

    select
        o.campaign_id,
        o.campaign_name,
        o.campaign_channel,
        o.campaign_budget,
        count(distinct o.order_id) as attributed_orders,
        count(distinct o.customer_id) as attributed_customers,
        sum(ot.order_net_sales) as attributed_revenue,
        safe_divide(
            sum(ot.order_net_sales) - o.campaign_budget,
            nullif(o.campaign_budget, 0)
        ) as roi_ratio
    from orders as o
    inner join order_totals as ot
        on o.order_id = ot.order_id
    where o.campaign_id is not null
        and o.order_status in ('completed', 'shipped')
    group by
        o.campaign_id,
        o.campaign_name,
        o.campaign_channel,
        o.campaign_budget

)

select
    *,
    {{ audit_columns() }}
from campaign_attribution
