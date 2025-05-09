WITH delivered_base AS (
    SELECT  o.order_id,
            c.customer_unique_id,
            oi.seller_id,
            (oi.price - oi.freight_value) AS profit
    FROM   olist_orders        AS o
    JOIN   olist_customers     AS c  ON o.customer_id = c.customer_id
    JOIN   olist_order_items   AS oi ON o.order_id     = oi.order_id
    WHERE  o.order_status = 'delivered'
),
five_star_orders AS (
    SELECT DISTINCT order_id
    FROM   olist_order_reviews
    WHERE  review_score = 5
),
most_distinct_customers AS (
    SELECT seller_id,
           COUNT(DISTINCT customer_unique_id) AS val
    FROM   delivered_base
    GROUP  BY seller_id
    ORDER  BY val DESC
    LIMIT  1
),
highest_profit AS (
    SELECT seller_id,
           ROUND(SUM(profit), 4) AS val
    FROM   delivered_base
    GROUP  BY seller_id
    ORDER  BY val DESC
    LIMIT  1
),
most_distinct_orders AS (
    SELECT seller_id,
           COUNT(DISTINCT order_id) AS val
    FROM   delivered_base
    GROUP  BY seller_id
    ORDER  BY val DESC
    LIMIT  1
),
most_5_star AS (
    SELECT db.seller_id,
           COUNT(DISTINCT db.order_id) AS val
    FROM   delivered_base AS db
    WHERE  db.order_id IN (SELECT order_id FROM five_star_orders)
    GROUP  BY db.seller_id
    ORDER  BY val DESC
    LIMIT  1
)
SELECT 'most_distinct_customers' AS achievement,
       seller_id,
       val AS value
FROM   most_distinct_customers

UNION ALL
SELECT 'highest_profit',
       seller_id,
       val
FROM   highest_profit

UNION ALL
SELECT 'most_distinct_orders',
       seller_id,
       val
FROM   most_distinct_orders

UNION ALL
SELECT 'most_5_star_ratings',
       seller_id,
       val
FROM   most_5_star;