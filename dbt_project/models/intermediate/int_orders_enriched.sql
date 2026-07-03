with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

campaigns as (

    select * from {{ ref('stg_marketing_campaigns') }}

),

enriched as (

    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.payment_status,
        o.shipping_city,
        o.shipping_state,
        o.shipping_country,
        o.campaign_id,
        o.created_at,
        o.updated_at,
        c.first_name,
        c.last_name,
        c.email,
        c.city as customer_city,
        c.state as customer_state,
        c.country as customer_country,
        c.customer_status,
        mc.campaign_name,
        mc.channel as campaign_channel,
        mc.budget_amount as campaign_budget,
        {{ audit_columns() }}
    from orders as o
    left join customers as c
        on o.customer_id = c.customer_id
    left join campaigns as mc
        on o.campaign_id = mc.campaign_id

)

select * from enriched
