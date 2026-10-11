-- Business question: Provide clean, ready-to-use tables for the Power BI dashboard.
USE olist;

-- 1) State lookup (names are unaccented on purpose, to avoid encoding problems)
DROP TABLE IF EXISTS dim_state;
CREATE TABLE dim_state (
    state_code   CHAR(2) PRIMARY KEY,
    state_name   VARCHAR(40),
    region       VARCHAR(20),
    map_location VARCHAR(60)
);
INSERT INTO dim_state (state_code, state_name, region) VALUES
('AC','Acre','North'),('AP','Amapa','North'),('AM','Amazonas','North'),('PA','Para','North'),
('RO','Rondonia','North'),('RR','Roraima','North'),('TO','Tocantins','North'),
('AL','Alagoas','Northeast'),('BA','Bahia','Northeast'),('CE','Ceara','Northeast'),
('MA','Maranhao','Northeast'),('PB','Paraiba','Northeast'),('PE','Pernambuco','Northeast'),
('PI','Piaui','Northeast'),('RN','Rio Grande do Norte','Northeast'),('SE','Sergipe','Northeast'),
('DF','Distrito Federal','Central-West'),('GO','Goias','Central-West'),
('MT','Mato Grosso','Central-West'),('MS','Mato Grosso do Sul','Central-West'),
('ES','Espirito Santo','Southeast'),('MG','Minas Gerais','Southeast'),
('RJ','Rio de Janeiro','Southeast'),('SP','Sao Paulo','Southeast'),
('PR','Parana','South'),('RS','Rio Grande do Sul','South'),('SC','Santa Catarina','South');
UPDATE dim_state SET map_location = CONCAT(state_name, ', Brazil');

-- 2) One row per order (this becomes fact_orders)
CREATE OR REPLACE VIEW vw_pbi_orders AS
WITH seq AS (
    SELECT order_id,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_ts, order_id) AS order_seq,
           COUNT(*)     OVER (PARTITION BY customer_unique_id)                                AS customer_orders
    FROM vw_order_base
    WHERE order_status NOT IN ('canceled', 'unavailable')
)
SELECT b.order_id, b.customer_unique_id, b.customer_state, b.order_status,
       b.purchase_date, b.purchase_month,
       CASE WHEN b.purchase_month BETWEEN '2017-01-01' AND '2018-08-01' THEN 1 ELSE 0 END AS in_trend_window,
       b.is_valid_delivery, b.is_late, b.delay_days, b.delivery_days,
       b.seller_handling_days, b.carrier_transit_days, b.estimate_days,
       CASE WHEN b.order_status NOT IN ('canceled', 'unavailable')
             AND b.items_revenue IS NOT NULL THEN 1 ELSE 0 END AS is_active_order,
       b.items_revenue, b.freight_total, b.review_score,
       CASE WHEN b.review_score IS NULL THEN NULL
            WHEN b.review_score <= 2 THEN 1 ELSE 0 END AS is_low_review,
       CASE WHEN b.is_valid_delivery = 0 THEN NULL
            WHEN b.delay_days <= 0  THEN '1. On time or early'
            WHEN b.delay_days <= 3  THEN '2. Late 1-3 days'
            WHEN b.delay_days <= 7  THEN '3. Late 4-7 days'
            WHEN b.delay_days <= 14 THEN '4. Late 8-14 days'
            ELSE                         '5. Late 15+ days' END AS delay_bucket,
       CASE WHEN q.order_seq = 1 AND b.is_valid_delivery = 1
             AND b.purchase_ts < '2018-03-01' THEN 1 ELSE 0 END AS first_order_eligible,
       CASE WHEN q.order_seq = 1 AND b.is_valid_delivery = 1 AND b.purchase_ts < '2018-03-01' THEN
                 CASE WHEN b.is_late = 0     THEN '1. First order on time'
                      WHEN b.delay_days <= 7 THEN '2. First order 1-7 days late'
                      ELSE                        '3. First order 8+ days late' END
            END AS first_order_group,
       q.customer_orders
FROM vw_order_base b
LEFT JOIN seq q ON q.order_id = b.order_id;

-- 3) One row per order per category (for the category chart)
CREATE OR REPLACE VIEW vw_pbi_order_category AS
SELECT oi.order_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       MAX(b.is_late)       AS is_late,
       MAX(b.review_score)  AS review_score,
       SUM(oi.price)        AS price,
       SUM(oi.freight_value) AS freight_value
FROM order_items oi
JOIN vw_order_base b ON b.order_id = oi.order_id AND b.is_valid_delivery = 1
JOIN products p      ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
GROUP BY oi.order_id, COALESCE(t.product_category_name_english, p.product_category_name, 'unknown');

-- 4) One row per seller, with the score and tier from notebook 04 (this becomes dim_seller)
CREATE OR REPLACE VIEW vw_pbi_seller AS
SELECT s.seller_id, s.seller_state, s.seller_city,
       sc.orders, sc.revenue, sc.late_rate_pct, sc.avg_handling_days, sc.avg_review, sc.pct_1_2_star,
       COALESCE(sc.meets_min_orders, 0)    AS meets_min_orders,
       ss.score,
       COALESCE(ss.tier, 'Not scored')     AS tier
FROM sellers s
LEFT JOIN vw_seller_scorecard sc ON sc.seller_id = s.seller_id
LEFT JOIN seller_scores ss       ON ss.seller_id = s.seller_id;

SELECT COUNT(*)                                   AS orders,
       SUM(is_active_order)                       AS active_orders,
       ROUND(SUM(CASE WHEN is_active_order = 1 THEN items_revenue END), 2) AS revenue,
       ROUND(SUM(CASE WHEN is_active_order = 1 THEN items_revenue END) / SUM(is_active_order), 2) AS aov,
       ROUND(100 * AVG(is_late), 2)               AS late_pct,
       ROUND(AVG(CASE WHEN is_late = 1 THEN delay_days END), 2) AS avg_delay_late_only,
       ROUND(AVG(review_score), 3)                AS avg_review
FROM vw_pbi_orders;