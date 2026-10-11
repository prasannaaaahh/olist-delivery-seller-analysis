-- Business question: How are orders, revenue and average order value trending month by month, and how fast are they growing?
USE olist;

WITH monthly AS (
    SELECT purchase_month,
           COUNT(*)                          AS orders,
           ROUND(SUM(items_revenue), 2)      AS revenue,
           ROUND(SUM(items_revenue) / COUNT(*), 2) AS aov
    FROM vw_order_base
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND items_revenue IS NOT NULL
      AND purchase_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY purchase_month
)
SELECT purchase_month, orders, revenue, aov,
       LAG(orders) OVER w AS prev_month_orders,
       ROUND(100 * (orders - LAG(orders) OVER w) / LAG(orders) OVER w, 1)    AS orders_mom_pct,
       ROUND(100 * (revenue - LAG(revenue) OVER w) / LAG(revenue) OVER w, 1) AS revenue_mom_pct
FROM monthly
WINDOW w AS (ORDER BY purchase_month)
ORDER BY purchase_month;