with orders as (

    select * from {{ ref('fct_orders') }}
    where order_status in ('completed', 'shipped')

),

final as (

    select
        shipping_country as country,
        shipping_state as state,
        shipping_city as city,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as total_customers,
        sum(net_sales) as net_sales,
        safe_divide(sum(net_sales), count(distinct order_id)) as average_order_value,
        {{ audit_columns() }}
    from orders
    group by 1, 2, 3

)

select * from final
