-- Business question: Who are the worst sellers inside each state, and how do all sellers split into performance tiers?
USE olist;

SELECT seller_id, seller_state, orders, late_rate_pct, avg_review,
       DENSE_RANK() OVER (PARTITION BY seller_state ORDER BY late_rate_pct DESC) AS late_rank_in_state,
       NTILE(10)    OVER (ORDER BY late_rate_pct DESC)                          AS late_decile
FROM vw_seller_scorecard
WHERE meets_min_orders = 1
ORDER BY seller_state, late_rank_in_state;