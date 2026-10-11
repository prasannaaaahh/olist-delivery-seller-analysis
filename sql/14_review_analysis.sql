-- Business question: How often do customers leave a written comment, and which categories earn the weakest reviews?
USE olist;

-- Part A: overall, and by score
SELECT COUNT(*)                         AS reviewed_orders,
       ROUND(AVG(review_score), 2)      AS avg_score,
       ROUND(100 * AVG(has_comment), 1) AS pct_with_comment
FROM vw_order_base
WHERE review_score IS NOT NULL;

SELECT review_score,
       COUNT(*)                         AS orders,
       ROUND(100 * AVG(has_comment), 1) AS pct_with_comment
FROM vw_order_base
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;

-- Part B: average score by category (each order counted once per category)
WITH order_cat AS (
    SELECT DISTINCT oi.order_id,
           COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
)
SELECT oc.category,
       COUNT(*)                          AS orders,
       ROUND(AVG(b.review_score), 2)     AS avg_review,
       ROUND(100 * AVG(CASE WHEN b.review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_2_star
FROM order_cat oc
JOIN vw_order_base b ON b.order_id = oc.order_id
WHERE b.review_score IS NOT NULL
GROUP BY oc.category
HAVING COUNT(*) >= 100
ORDER BY avg_review ASC;