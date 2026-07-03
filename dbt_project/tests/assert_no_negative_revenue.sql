-- Custom test: Revenue must not be negative
select
    order_id,
    net_sales
from {{ ref('fct_orders') }}
where net_sales < 0
