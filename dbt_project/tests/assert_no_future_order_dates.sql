-- Custom test: Order dates must not be in the future
select
    order_id,
    order_date
from {{ ref('fct_orders') }}
where order_date > current_date()
