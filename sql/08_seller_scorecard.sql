-- Business question: How is each seller performing on lateness, handling speed and customer reviews?
USE olist;

WITH seller_orders AS (
    SELECT seller_id, order_id, SUM(price) AS seller_revenue
    FROM order_items
    GROUP BY seller_id, order_id
)
SELECT s.seller_id, s.seller_state,
       COUNT(*)                                AS orders,
       ROUND(SUM(so.seller_revenue), 2)        AS revenue,
       ROUND(100 * AVG(b.is_late), 2)          AS late_rate_pct,
       ROUND(AVG(b.seller_handling_days), 2)   AS avg_handling_days,
       ROUND(AVG(b.review_score), 2)           AS avg_review
FROM seller_orders so
JOIN vw_order_base b ON b.order_id = so.order_id AND b.is_valid_delivery = 1
JOIN sellers s       ON s.seller_id = so.seller_id
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(*) >= 30
ORDER BY late_rate_pct DESC, orders DESC;