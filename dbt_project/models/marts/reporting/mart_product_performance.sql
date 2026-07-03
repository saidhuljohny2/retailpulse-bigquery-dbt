with product_sales as (

    select * from {{ ref('int_product_sales_summary') }}

),

final as (

    select
        ps.product_id,
        ps.product_name,
        ps.category_name,
        ps.total_units_sold,
        ps.gross_sales,
        ps.net_sales,
        ps.total_profit,
        ps.return_rate,
        round(ps.profit_margin * 100, 2) as profit_margin_percentage,
        case
            when ps.net_sales >= 100000 and ps.profit_margin >= 0.3 then 'star'
            when ps.net_sales >= 50000 then 'growth'
            when ps.return_rate > 0.1 then 'at_risk'
            when ps.net_sales < 1000 then 'low_performer'
            else 'standard'
        end as product_performance_segment,
        {{ audit_columns() }}
    from product_sales as ps

)

select * from final
