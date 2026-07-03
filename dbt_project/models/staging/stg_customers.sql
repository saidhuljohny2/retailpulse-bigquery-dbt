with source as (

    select * from {{ source('raw', 'customers') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by customer_id
            order by updated_at desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(customer_id as int64) as customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        coalesce(trim(phone), '') as phone,
        trim(city) as city,
        upper(trim(state)) as state,
        upper(trim(country)) as country,
        trim(postal_code) as postal_code,
        cast(signup_date as date) as signup_date,
        lower(trim(customer_status)) as customer_status,
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
