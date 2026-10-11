-- Business question: Do customers whose first order arrived late come back less often?
USE olist;

-- Part A: overall repeat rate (real people, not customer_id)
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN n_orders >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(100 * AVG(CASE WHEN n_orders >= 2 THEN 1 ELSE 0 END), 2) AS repeat_rate_pct
FROM (
    SELECT customer_unique_id, COUNT(*) AS n_orders
    FROM vw_order_base
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY customer_unique_id
) t;

-- Part B: repeat rate by how the FIRST order went
WITH cust_orders AS (
    SELECT customer_unique_id, purchase_ts, is_valid_delivery, is_late, delay_days,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_ts, order_id) AS order_seq,
           COUNT(*)     OVER (PARTITION BY customer_unique_id)                                AS total_orders
    FROM vw_order_base
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
first_orders AS (
    SELECT *
    FROM cust_orders
    WHERE order_seq = 1
      AND is_valid_delivery = 1
      AND purchase_ts < '2018-03-01'     -- gives every customer at least ~6 months to come back
)
SELECT CASE WHEN is_late = 0      THEN '1. First order on time'
            WHEN delay_days <= 7  THEN '2. First order 1-7 days late'
            ELSE                       '3. First order 8+ days late' END AS first_order_outcome,
       COUNT(*)                                                       AS customers,
       SUM(CASE WHEN total_orders >= 2 THEN 1 ELSE 0 END)             AS repeat_customers,
       ROUND(100 * AVG(CASE WHEN total_orders >= 2 THEN 1 ELSE 0 END), 2) AS repeat_rate_pct
FROM first_orders
GROUP BY first_order_outcome
ORDER BY first_order_outcome;