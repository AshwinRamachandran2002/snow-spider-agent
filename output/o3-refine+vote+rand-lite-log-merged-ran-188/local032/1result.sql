WITH
-- 1) Seller that reached the largest number of DISTINCT customer *unique* IDs
distinct_customers AS (
    SELECT oi.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS metric
    FROM   olist_order_items  AS oi
    JOIN   olist_orders       AS o  ON o.order_id   = oi.order_id
    JOIN   olist_customers    AS c  ON c.customer_id = o.customer_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY oi.seller_id
    ORDER  BY metric DESC
    LIMIT 1
),

-- 2) Seller with the HIGHEST PROFIT  (= Σ(price − freight_value))
profit AS (
    SELECT oi.seller_id,
           SUM(oi.price - oi.freight_value) AS metric
    FROM   olist_order_items AS oi
    JOIN   olist_orders      AS o ON o.order_id = oi.order_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY oi.seller_id
    ORDER  BY metric DESC
    LIMIT 1
),

-- 3) Seller that fulfilled the most DISTINCT delivered orders
distinct_orders AS (
    SELECT oi.seller_id,
           COUNT(DISTINCT oi.order_id) AS metric
    FROM   olist_order_items AS oi
    JOIN   olist_orders      AS o ON o.order_id = oi.order_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY oi.seller_id
    ORDER  BY metric DESC
    LIMIT 1
),

-- 4) Seller with the greatest number of 5-star REVIEWED delivered orders
five_star AS (
    SELECT oi.seller_id,
           COUNT(DISTINCT oi.order_id) AS metric
    FROM   olist_order_items   AS oi
    JOIN   olist_order_reviews AS r  ON r.order_id = oi.order_id
    JOIN   olist_orders        AS o  ON o.order_id = oi.order_id
    WHERE  o.order_status = 'delivered'
      AND  r.review_score = 5
    GROUP  BY oi.seller_id
    ORDER  BY metric DESC
    LIMIT 1
)

SELECT 'Most distinct customers' AS description,
       seller_id,
       metric AS value
FROM   distinct_customers

UNION ALL
SELECT 'Highest profit',
       seller_id,
       ROUND(metric, 4)           -- keep decimals to 4 places
FROM   profit

UNION ALL
SELECT 'Most distinct orders',
       seller_id,
       metric
FROM   distinct_orders

UNION ALL
SELECT 'Most 5-star ratings',
       seller_id,
       metric
FROM   five_star;