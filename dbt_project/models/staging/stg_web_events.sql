with source as (

    select * from {{ source('raw', 'web_events') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by event_id
            order by event_timestamp desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        trim(event_id) as event_id,
        cast(customer_id as int64) as customer_id,
        trim(session_id) as session_id,
        cast(event_timestamp as timestamp) as event_timestamp,
        lower(trim(event_type)) as event_type,
        lower(trim(page_name)) as page_name,
        cast(product_id as int64) as product_id,
        lower(trim(device_type)) as device_type,
        lower(trim(traffic_source)) as traffic_source,
        cast(campaign_id as int64) as campaign_id,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
