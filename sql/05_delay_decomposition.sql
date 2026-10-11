-- Business question: Is the delay coming from seller handling, carrier transit, or over-optimistic estimates?
USE olist;

-- Part A: by customer state
SELECT customer_state,
       COUNT(*)                              AS delivered_orders,
       ROUND(AVG(seller_handling_days), 1)   AS avg_handling_days,
       ROUND(AVG(carrier_transit_days), 1)   AS avg_transit_days,
       ROUND(AVG(delivery_days), 1)          AS avg_total_days,
       ROUND(AVG(estimate_days), 1)          AS avg_estimated_days,
       ROUND(AVG(estimate_days) - AVG(delivery_days), 1) AS avg_buffer_days
FROM vw_order_base
WHERE is_valid_delivery = 1
GROUP BY customer_state
ORDER BY avg_total_days DESC;

-- Part B: late orders vs on-time orders
SELECT CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time' END AS delivery_outcome,
       COUNT(*)                            AS orders,
       ROUND(AVG(estimate_days), 1)        AS avg_estimated_days,
       ROUND(AVG(seller_handling_days), 1) AS avg_handling_days,
       ROUND(AVG(carrier_transit_days), 1) AS avg_transit_days,
       ROUND(AVG(delivery_days), 1)        AS avg_total_days
FROM vw_order_base
WHERE is_valid_delivery = 1
GROUP BY delivery_outcome;