-- Business question: Build reusable "one row per order" and "one row per seller" tables
-- so every metric is calculated the same way in SQL, Python and Power BI.
USE olist;

CREATE OR REPLACE VIEW vw_order_base AS
WITH items AS (          -- collapse many items per order into ONE row per order
    SELECT order_id,
           COUNT(*)                  AS n_items,
           COUNT(DISTINCT seller_id) AS n_sellers,
           SUM(price)                AS items_revenue,
           SUM(freight_value)        AS freight_total
    FROM order_items
    GROUP BY order_id
),
pay AS (                 -- collapse many payments per order into ONE row per order
    SELECT order_id,
           SUM(payment_value)        AS payment_total,
           MAX(payment_installments) AS max_installments
    FROM order_payments
    GROUP BY order_id
),
rev AS (                 -- keep only the LATEST review per order
    SELECT order_id, review_score, has_comment
    FROM (
        SELECT order_id,
               review_score,
               CASE WHEN review_comment_message IS NOT NULL THEN 1 ELSE 0 END AS has_comment,
               ROW_NUMBER() OVER (PARTITION BY order_id
                                  ORDER BY review_answer_timestamp DESC, review_id) AS rn
        FROM order_reviews
    ) r
    WHERE rn = 1
),
x AS (                   -- orders + customers + the "valid delivery" flag
    SELECT o.order_id, o.customer_id, c.customer_unique_id,
           c.customer_state, c.customer_city, c.customer_zip_code_prefix,
           o.order_status,
           o.order_purchase_timestamp      AS purchase_ts,
           o.order_delivered_carrier_date  AS carrier_ts,
           o.order_delivered_customer_date AS delivered_ts,
           o.order_estimated_delivery_date AS estimated_ts,
           CASE WHEN o.order_status = 'delivered'
                 AND o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_carrier_date  IS NOT NULL
                 AND o.order_delivered_carrier_date  >= o.order_purchase_timestamp
                 AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
                THEN 1 ELSE 0 END AS is_valid_delivery
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
)
SELECT x.order_id, x.customer_id, x.customer_unique_id,
       x.customer_state, x.customer_city, x.customer_zip_code_prefix,
       x.order_status, x.purchase_ts,
       DATE(x.purchase_ts) AS purchase_date,
       DATE_SUB(DATE(x.purchase_ts), INTERVAL (DAYOFMONTH(x.purchase_ts) - 1) DAY) AS purchase_month,
       x.is_valid_delivery,
       CASE WHEN x.is_valid_delivery = 1
            THEN TIMESTAMPDIFF(SECOND, x.purchase_ts, x.delivered_ts) / 86400 END AS delivery_days,
       CASE WHEN x.is_valid_delivery = 1
            THEN DATEDIFF(x.delivered_ts, x.estimated_ts) END AS delay_days,
       CASE WHEN x.is_valid_delivery = 1
            THEN CASE WHEN DATEDIFF(x.delivered_ts, x.estimated_ts) > 0 THEN 1 ELSE 0 END END AS is_late,
       CASE WHEN x.is_valid_delivery = 1
            THEN TIMESTAMPDIFF(SECOND, x.purchase_ts, x.carrier_ts) / 86400 END AS seller_handling_days,
       CASE WHEN x.is_valid_delivery = 1
            THEN TIMESTAMPDIFF(SECOND, x.carrier_ts, x.delivered_ts) / 86400 END AS carrier_transit_days,
       TIMESTAMPDIFF(SECOND, x.purchase_ts, x.estimated_ts) / 86400 AS estimate_days,
       i.n_items, i.n_sellers, i.items_revenue, i.freight_total,
       p.payment_total, p.max_installments,
       r.review_score, r.has_comment
FROM x
LEFT JOIN items i ON i.order_id = x.order_id
LEFT JOIN pay   p ON p.order_id = x.order_id
LEFT JOIN rev   r ON r.order_id = x.order_id;


CREATE OR REPLACE VIEW vw_seller_scorecard AS
WITH seller_orders AS (  -- one row per seller per order
    SELECT seller_id, order_id,
           SUM(price) AS seller_revenue
    FROM order_items
    GROUP BY seller_id, order_id
)
SELECT s.seller_id, s.seller_state, s.seller_city,
       COUNT(*)                                   AS orders,
       ROUND(SUM(so.seller_revenue), 2)           AS revenue,
       ROUND(100 * AVG(b.is_late), 2)             AS late_rate_pct,
       ROUND(AVG(b.seller_handling_days), 2)      AS avg_handling_days,
       ROUND(AVG(b.review_score), 2)              AS avg_review,
       ROUND(100 * AVG(CASE WHEN b.review_score IS NULL THEN NULL
                            WHEN b.review_score <= 2 THEN 1 ELSE 0 END), 2) AS pct_1_2_star,
       CASE WHEN COUNT(*) >= 30 THEN 1 ELSE 0 END AS meets_min_orders
FROM seller_orders so
JOIN vw_order_base b ON b.order_id = so.order_id AND b.is_valid_delivery = 1
JOIN sellers s       ON s.seller_id = so.seller_id
GROUP BY s.seller_id, s.seller_state, s.seller_city;


SELECT COUNT(*) AS rows_in_view, COUNT(DISTINCT order_id) AS distinct_orders,
       SUM(is_valid_delivery) AS valid_deliveries
FROM vw_order_base;

SELECT (SELECT SUM(items_revenue) FROM vw_order_base) AS revenue_from_view,
       (SELECT SUM(price) FROM order_items)           AS revenue_from_raw;

SELECT COUNT(*) AS sellers_in_scorecard, SUM(meets_min_orders) AS sellers_with_30_plus_orders
FROM vw_seller_scorecard;