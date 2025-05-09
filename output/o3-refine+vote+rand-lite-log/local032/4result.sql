WITH
-- 1. distinct customer unique ids per seller
customer_counts AS (
    SELECT i.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS val
    FROM   olist_order_items  i
    JOIN   olist_orders       o ON o.order_id   = i.order_id
    JOIN   olist_customers    c ON c.customer_id = o.customer_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY i.seller_id
),
top_customer AS (
    SELECT seller_id, val
    FROM   customer_counts
    ORDER  BY val DESC, seller_id
    LIMIT  1
),

-- 2. total profit (price – freight) per seller
profit_counts AS (
    SELECT i.seller_id,
           SUM(i.price - i.freight_value) AS val
    FROM   olist_order_items i
    JOIN   olist_orders      o ON o.order_id = i.order_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY i.seller_id
),
top_profit AS (
    SELECT seller_id, val
    FROM   profit_counts
    ORDER  BY val DESC, seller_id
    LIMIT  1
),

-- 3. distinct orders per seller
order_counts AS (
    SELECT i.seller_id,
           COUNT(DISTINCT i.order_id) AS val
    FROM   olist_order_items i
    JOIN   olist_orders      o ON o.order_id = i.order_id
    WHERE  o.order_status = 'delivered'
    GROUP  BY i.seller_id
),
top_orders AS (
    SELECT seller_id, val
    FROM   order_counts
    ORDER  BY val DESC, seller_id
    LIMIT  1
),

-- 4. 5‑star ratings per seller
rating_counts AS (
    SELECT i.seller_id,
           COUNT(*) AS val
    FROM   olist_order_items   i
    JOIN   olist_orders        o ON o.order_id = i.order_id
    JOIN   olist_order_reviews r ON r.order_id = i.order_id
    WHERE  o.order_status = 'delivered'
      AND  r.review_score = 5
    GROUP  BY i.seller_id
),
top_ratings AS (
    SELECT seller_id, val
    FROM   rating_counts
    ORDER  BY val DESC, seller_id
    LIMIT  1
)

-- assemble the four “winners”
SELECT seller_id,
       val AS value,
       'Highest number of distinct customer unique IDs' AS achievement
FROM   top_customer

UNION ALL
SELECT seller_id,
       val,
       'Highest profit (price - freight value)'            AS achievement
FROM   top_profit

UNION ALL
SELECT seller_id,
       val,
       'Highest number of distinct orders'                 AS achievement
FROM   top_orders

UNION ALL
SELECT seller_id,
       val,
       'Most 5-star ratings'                               AS achievement
FROM   top_ratings;