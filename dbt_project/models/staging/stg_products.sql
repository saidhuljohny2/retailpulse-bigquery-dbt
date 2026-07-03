with source as (

    select * from {{ source('raw', 'products') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by product_id
            order by updated_at desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(product_id as int64) as product_id,
        trim(product_name) as product_name,
        cast(category_id as int64) as category_id,
        trim(brand) as brand,
        cast(unit_price as float64) as unit_price,
        cast(cost_price as float64) as cost_price,
        lower(trim(product_status)) as product_status,
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
