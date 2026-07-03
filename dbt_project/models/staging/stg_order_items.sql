with source as (

    select * from {{ source('raw', 'order_items') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by order_item_id
            order by created_at desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(order_item_id as int64) as order_item_id,
        cast(order_id as int64) as order_id,
        cast(product_id as int64) as product_id,
        cast(quantity as int64) as quantity,
        cast(unit_price as float64) as unit_price,
        coalesce(cast(discount_amount as float64), 0.0) as discount_amount,
        coalesce(cast(tax_amount as float64), 0.0) as tax_amount,
        cast(created_at as timestamp) as created_at,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
