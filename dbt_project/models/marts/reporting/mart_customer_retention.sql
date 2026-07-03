with orders as (

    select
        customer_id,
        order_date
    from {{ ref('fct_orders') }}
    where order_status in ('completed', 'shipped')

),

customer_cohorts as (

    select
        customer_id,
        date_trunc(min(order_date), month) as cohort_month
    from orders
    group by 1

),

customer_activity as (

    select
        customer_id,
        date_trunc(order_date, month) as activity_month
    from orders
    group by 1, 2

),

cohort_activity as (

    select
        cc.cohort_month,
        ca.activity_month,
        cc.customer_id
    from customer_cohorts as cc
    inner join customer_activity as ca
        on cc.customer_id = ca.customer_id

),

final as (

    select
        cohort_month,
        activity_month,
        count(distinct customer_id) as cohort_customers,
        count(distinct case
            when activity_month = cohort_month then customer_id
        end) as retained_customers,
        safe_divide(
            count(distinct case
                when activity_month >= cohort_month then customer_id
            end),
            count(distinct customer_id)
        ) as retention_rate,
        {{ audit_columns() }}
    from cohort_activity
    group by 1, 2

)

select * from final
