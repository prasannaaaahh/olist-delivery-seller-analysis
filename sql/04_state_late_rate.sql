-- Business question: Which customer states have the worst late rate, and which states contribute the most late orders overall?
USE olist;

WITH state_stats AS (
    SELECT customer_state,
           COUNT(*)                     AS delivered_orders,
           SUM(is_late)                 AS late_orders,
           ROUND(100 * AVG(is_late), 2) AS late_rate_pct
    FROM vw_order_base
    WHERE is_valid_delivery = 1
    GROUP BY customer_state
)
SELECT customer_state, delivered_orders, late_orders, late_rate_pct,
       RANK() OVER (ORDER BY late_rate_pct DESC)                 AS late_rate_rank,
       ROUND(100 * late_orders / SUM(late_orders) OVER (), 2)    AS share_of_all_late_orders_pct,
       ROUND(100 * delivered_orders / SUM(delivered_orders) OVER (), 2) AS share_of_all_orders_pct
FROM state_stats
ORDER BY late_rate_rank;