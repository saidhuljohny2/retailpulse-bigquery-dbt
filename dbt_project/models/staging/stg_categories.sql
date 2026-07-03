with source as (

    select * from {{ source('raw', 'categories') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by category_id
            order by created_at desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(category_id as int64) as category_id,
        trim(category_name) as category_name,
        trim(department) as department,
        cast(created_at as timestamp) as created_at,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
