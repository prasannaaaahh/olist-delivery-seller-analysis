-- Business question: How do customers pay, and how do installments relate to order value?
USE olist;

-- Part A: payment type mix
SELECT payment_type,
       COUNT(DISTINCT order_id)                       AS orders,
       COUNT(*)                                       AS payment_rows,
       ROUND(SUM(payment_value), 2)                   AS total_value,
       ROUND(100 * SUM(payment_value) / SUM(SUM(payment_value)) OVER (), 2) AS pct_of_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_value DESC;

-- Part B: credit-card installments vs order value
WITH cc AS (
    SELECT order_id,
           MAX(payment_installments) AS installments,
           SUM(payment_value)        AS cc_value
    FROM order_payments
    WHERE payment_type = 'credit_card'
    GROUP BY order_id
)
SELECT CASE WHEN installments <= 1  THEN '1. Single payment'
            WHEN installments <= 3  THEN '2. 2-3 installments'
            WHEN installments <= 6  THEN '3. 4-6 installments'
            WHEN installments <= 10 THEN '4. 7-10 installments'
            ELSE                         '5. 11+ installments' END AS installment_bucket,
       COUNT(*)                                          AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_of_cc_orders,
       ROUND(AVG(cc_value), 2)                           AS avg_order_value
FROM cc
GROUP BY installment_bucket
ORDER BY installment_bucket;