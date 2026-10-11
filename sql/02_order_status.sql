-- Business question: What happens to orders after they are placed, and what share is canceled or unavailable?
USE olist;

SELECT order_status,
       COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

SELECT COUNT(*) AS total_orders,
       SUM(order_status = 'canceled')                          AS canceled,
       ROUND(100 * SUM(order_status = 'canceled') / COUNT(*), 2) AS cancel_rate_pct,
       SUM(order_status IN ('canceled', 'unavailable'))        AS canceled_or_unavailable,
       ROUND(100 * SUM(order_status IN ('canceled', 'unavailable')) / COUNT(*), 2) AS failed_rate_pct
FROM orders;