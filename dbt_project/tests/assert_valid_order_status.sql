-- Custom test: Order status must be valid
select
    order_id,
    order_status
from {{ ref('fct_orders') }}
where order_status not in ('completed', 'cancelled', 'pending', 'shipped', 'returned')
