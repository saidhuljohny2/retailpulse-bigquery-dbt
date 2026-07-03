with source as (

    select * from {{ source('raw', 'payments') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by payment_id
            order by payment_date desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(payment_id as int64) as payment_id,
        cast(order_id as int64) as order_id,
        lower(trim(payment_method)) as payment_method,
        cast(payment_amount as float64) as payment_amount,
        lower(trim(payment_status)) as payment_status,
        cast(payment_date as date) as payment_date,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
