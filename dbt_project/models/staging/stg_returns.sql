with source as (

    select * from {{ source('raw', 'returns') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by return_id
            order by return_date desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(return_id as int64) as return_id,
        cast(order_item_id as int64) as order_item_id,
        cast(return_date as date) as return_date,
        lower(trim(return_reason)) as return_reason,
        coalesce(cast(refund_amount as float64), 0.0) as refund_amount,
        lower(trim(return_status)) as return_status,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
