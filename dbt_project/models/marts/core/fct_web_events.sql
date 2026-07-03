{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='event_id',
        partition_by={
            'field': 'event_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['customer_id', 'event_type', 'product_id']
    )
}}

with web_events as (

    select * from {{ ref('stg_web_events') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['event_id']) }} as event_key,
        event_id,
        customer_id,
        session_id,
        event_timestamp,
        cast(event_timestamp as date) as event_date,
        event_type,
        page_name,
        product_id,
        device_type,
        traffic_source,
        campaign_id,
        {{ audit_columns() }}
    from web_events

    {% if is_incremental() %}
        where cast(event_timestamp as date) >= date_sub(
            current_date(),
            interval {{ var('incremental_lookback_days', 7) }} day
        )
    {% endif %}

)

select * from final
