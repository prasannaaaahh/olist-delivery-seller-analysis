-- Business question: Is delivery performance improving or worsening over time?
USE olist;

WITH base AS (
    SELECT purchase_month, is_late, delay_days
    FROM vw_order_base
    WHERE is_valid_delivery = 1
      AND purchase_month BETWEEN '2017-01-01' AND '2018-08-01'
)
SELECT purchase_month,
       COUNT(*)                                            AS delivered_orders,
       ROUND(100 * AVG(is_late), 1)                        AS late_pct,
       ROUND(100 * AVG(1 - is_late), 1)                    AS on_time_pct,
       ROUND(AVG(delay_days), 2)                           AS avg_delay_all_orders,
       ROUND(AVG(CASE WHEN is_late = 1 THEN delay_days END), 2) AS avg_delay_when_late
FROM base
GROUP BY purchase_month
ORDER BY purchase_month;