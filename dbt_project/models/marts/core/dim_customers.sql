with customers as (

    select * from {{ ref('stg_customers') }}

),

order_summary as (

    select * from {{ ref('int_customer_order_summary') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_key,
        c.customer_id,
        c.first_name,
        c.last_name,
        concat(c.first_name, ' ', c.last_name) as customer_name,
        c.email,
        c.phone,
        c.city,
        c.state,
        c.country,
        c.postal_code,
        concat(c.city, ', ', c.state, ', ', c.country) as location,
        c.signup_date,
        c.customer_status,
        coalesce(os.first_order_date, cast(null as date)) as first_order_date,
        coalesce(os.last_order_date, cast(null as date)) as last_order_date,
        coalesce(os.total_orders, 0) as total_orders,
        coalesce(os.total_net_sales, 0.0) as total_spend,
        coalesce(os.average_order_value, 0.0) as average_order_value,
        coalesce(os.days_since_last_order, 9999) as days_since_last_order,
        case
            when coalesce(os.total_net_sales, 0) >= 5000 then 'high_value'
            when coalesce(os.total_net_sales, 0) >= 1000 then 'medium_value'
            when coalesce(os.total_orders, 0) > 0 then 'low_value'
            else 'prospect'
        end as customer_segment,
        case
            when coalesce(os.days_since_last_order, 9999) > 180
                and coalesce(os.total_orders, 0) > 0 then true
            else false
        end as churn_risk_flag,
        c.created_at,
        c.updated_at,
        {{ audit_columns() }}
    from customers as c
    left join order_summary as os
        on c.customer_id = os.customer_id

)

select * from final
