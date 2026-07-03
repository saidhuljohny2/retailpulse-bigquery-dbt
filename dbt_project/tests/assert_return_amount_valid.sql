-- Custom test: Return amount cannot exceed item net sales
select
    r.return_id,
    r.refund_amount,
    r.item_net_sales
from {{ ref('fct_returns') }} as r
where r.refund_amount > r.item_net_sales
