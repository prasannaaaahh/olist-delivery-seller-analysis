-- Business question: How concentrated is revenue among a few sellers (Pareto / 80-20 check)?
USE olist;

WITH seller_rev AS (
    SELECT oi.seller_id, SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
),
ranked AS (
    SELECT seller_id, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC, seller_id) AS seller_rank,
           SUM(revenue) OVER (ORDER BY revenue DESC, seller_id
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_revenue,
           SUM(revenue) OVER () AS total_revenue,
           COUNT(*)     OVER () AS n_sellers
    FROM seller_rev
)
SELECT seller_rank, seller_id,
       ROUND(revenue, 2)                          AS revenue,
       ROUND(100 * cum_revenue / total_revenue, 2) AS cum_revenue_pct,
       ROUND(100 * seller_rank / n_sellers, 2)     AS cum_sellers_pct
FROM ranked
ORDER BY seller_rank;

-- How many sellers make 80% of revenue?

WITH seller_rev AS (
    SELECT oi.seller_id, SUM(oi.price) AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.seller_id
),
ranked AS (
    SELECT seller_id, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC, seller_id) AS seller_rank,
           SUM(revenue) OVER (ORDER BY revenue DESC, seller_id
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_revenue,
           SUM(revenue) OVER () AS total_revenue,
           COUNT(*)     OVER () AS n_sellers
    FROM seller_rev
)
SELECT MIN(seller_rank) AS sellers_needed_for_80pct_revenue,
       MAX(n_sellers)   AS total_sellers,
       ROUND(100 * MIN(seller_rank) / MAX(n_sellers), 1) AS pct_of_sellers
FROM ranked
WHERE 100 * cum_revenue / total_revenue >= 80;