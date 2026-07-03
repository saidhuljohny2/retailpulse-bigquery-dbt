with campaigns as (

    select * from {{ ref('stg_marketing_campaigns') }}

),

attribution as (

    select * from {{ ref('int_campaign_attribution') }}

),

final as (

    select
        c.campaign_id,
        c.campaign_name,
        c.channel,
        c.budget_amount,
        coalesce(a.attributed_orders, 0) as attributed_orders,
        coalesce(a.attributed_revenue, 0.0) as attributed_revenue,
        safe_divide(c.budget_amount, nullif(a.attributed_orders, 0)) as cost_per_order,
        round(
            safe_divide(
                coalesce(a.attributed_revenue, 0.0) - c.budget_amount,
                nullif(c.budget_amount, 0)
            ) * 100,
            2
        ) as roi_percentage,
        {{ audit_columns() }}
    from campaigns as c
    left join attribution as a
        on c.campaign_id = a.campaign_id

)

select * from final
