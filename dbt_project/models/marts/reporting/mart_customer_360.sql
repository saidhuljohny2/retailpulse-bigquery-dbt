with customers as (

    select * from {{ ref('dim_customers') }}

),

returns as (

    select
        customer_id,
        sum(refund_amount) as total_returns
    from {{ ref('fct_returns') }}
    where return_status = 'approved'
    group by 1

),

final as (

    select
        c.customer_id,
        c.customer_name,
        c.location,
        c.first_order_date,
        c.last_order_date,
        c.total_orders,
        c.total_spend,
        coalesce(r.total_returns, 0.0) as total_returns,
        c.average_order_value,
        c.total_spend as customer_lifetime_value,
        c.customer_segment,
        c.churn_risk_flag,
        {{ audit_columns() }}
    from customers as c
    left join returns as r
        on c.customer_id = r.customer_id

)

select * from final
