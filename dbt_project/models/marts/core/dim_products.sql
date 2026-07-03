with products as (

    select * from {{ ref('stg_products') }}

),

categories as (

    select * from {{ ref('stg_categories') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        p.product_id,
        p.product_name,
        p.category_id,
        c.category_name,
        c.department,
        p.brand,
        p.unit_price,
        p.cost_price,
        p.unit_price - p.cost_price as unit_margin,
        safe_divide(p.unit_price - p.cost_price, nullif(p.unit_price, 0)) as margin_percentage,
        p.product_status,
        p.created_at,
        p.updated_at,
        {{ audit_columns() }}
    from products as p
    left join categories as c
        on p.category_id = c.category_id

)

select * from final
