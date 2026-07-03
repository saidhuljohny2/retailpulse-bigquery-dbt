with source as (

    select * from {{ source('raw', 'orders') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by order_id
            order by updated_at desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(order_id as int64) as order_id,
        cast(customer_id as int64) as customer_id,
        cast(order_date as date) as order_date,
        lower(trim(order_status)) as order_status,
        lower(trim(payment_status)) as payment_status,
        trim(shipping_city) as shipping_city,
        upper(trim(shipping_state)) as shipping_state,
        upper(trim(shipping_country)) as shipping_country,
        cast(campaign_id as int64) as campaign_id,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
