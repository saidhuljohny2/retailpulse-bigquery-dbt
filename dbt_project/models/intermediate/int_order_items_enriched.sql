with order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

categories as (

    select * from {{ ref('stg_categories') }}

),

enriched as (

    select
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        oi.discount_amount,
        oi.tax_amount,
        oi.created_at,
        p.product_name,
        p.brand,
        p.category_id,
        p.cost_price,
        p.product_status,
        c.category_name,
        c.department,
        -- Revenue calculations
        oi.quantity * oi.unit_price as gross_sales,
        oi.discount_amount as total_discount,
        oi.tax_amount as total_tax,
        (oi.quantity * oi.unit_price) - oi.discount_amount as net_sales,
        (oi.quantity * oi.unit_price) - oi.discount_amount - (oi.quantity * p.cost_price) as profit,
        {{ audit_columns() }}
    from order_items as oi
    left join products as p
        on oi.product_id = p.product_id
    left join categories as c
        on p.category_id = c.category_id

)

select * from enriched
