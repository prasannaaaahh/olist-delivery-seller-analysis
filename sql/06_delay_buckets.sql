-- Business question: How much do reviews suffer as orders arrive later?
USE olist;

WITH bucketed AS (
    SELECT review_score, delay_days,
           CASE WHEN delay_days <= 0  THEN '1. On time or early'
                WHEN delay_days <= 3  THEN '2. Late 1-3 days'
                WHEN delay_days <= 7  THEN '3. Late 4-7 days'
                WHEN delay_days <= 14 THEN '4. Late 8-14 days'
                ELSE                       '5. Late 15+ days' END AS delay_bucket
    FROM vw_order_base
    WHERE is_valid_delivery = 1
)
SELECT delay_bucket,
       COUNT(*)                                          AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_of_orders,
       ROUND(AVG(review_score), 2)                       AS avg_review,
       ROUND(100 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
                 / COUNT(review_score), 1)               AS pct_1_2_star
FROM bucketed
GROUP BY delay_bucket
ORDER BY delay_bucket;