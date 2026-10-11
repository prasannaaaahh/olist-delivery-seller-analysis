-- Business question: Of customers who first bought in a given month, what share buys again in later months?
USE olist;

WITH order_cohorts AS (
    SELECT customer_unique_id, purchase_month,
           MIN(purchase_month) OVER (PARTITION BY customer_unique_id) AS cohort_month
    FROM vw_order_base
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
activity AS (
    SELECT cohort_month,
           TIMESTAMPDIFF(MONTH, cohort_month, purchase_month) AS month_number,
           COUNT(DISTINCT customer_unique_id)                 AS active_customers
    FROM order_cohorts
    WHERE cohort_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY cohort_month, month_number
)
SELECT cohort_month, month_number, active_customers,
       ROUND(100 * active_customers /
             FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM activity
ORDER BY cohort_month, month_number;