-- Business question: Which product categories are late most often, and where does freight take a large share of the price?
USE olist;

SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(*)                                   AS items,
       COUNT(DISTINCT oi.order_id)                AS orders,
       ROUND(100 * AVG(b.is_late), 2)             AS late_rate_pct,
       ROUND(AVG(b.review_score), 2)              AS avg_review,
       ROUND(100 * SUM(oi.freight_value) / SUM(oi.price), 1) AS freight_pct_of_price
FROM order_items oi
JOIN vw_order_base b ON b.order_id = oi.order_id AND b.is_valid_delivery = 1
JOIN products p      ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name, 'unknown')
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY late_rate_pct DESC;