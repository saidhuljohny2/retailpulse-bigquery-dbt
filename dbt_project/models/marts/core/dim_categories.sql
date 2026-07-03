with categories as (

    select * from {{ ref('stg_categories') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['category_id']) }} as category_key,
        category_id,
        category_name,
        department,
        created_at,
        {{ audit_columns() }}
    from categories

)

select * from final
