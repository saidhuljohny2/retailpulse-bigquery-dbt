with source as (

    select * from {{ source('raw', 'marketing_campaigns') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by campaign_id
            order by campaign_end_date desc, _ingested_at desc
        ) as row_num
    from source

),

renamed as (

    select
        cast(campaign_id as int64) as campaign_id,
        trim(campaign_name) as campaign_name,
        lower(trim(channel)) as channel,
        cast(campaign_start_date as date) as campaign_start_date,
        cast(campaign_end_date as date) as campaign_end_date,
        cast(budget_amount as float64) as budget_amount,
        lower(trim(campaign_status)) as campaign_status,
        cast(_ingested_at as timestamp) as ingested_at,
        _source_file as source_file,
        _batch_id as batch_id,
        {{ audit_columns() }}
    from deduplicated
    where row_num = 1

)

select * from renamed
