WITH delivered_orders AS (
    SELECT order_id,
           customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),
items AS (
    /* every order‑item that belongs to a delivered order,
       already carrying the customer_id */
    SELECT oi.seller_id,
           oi.order_id,
           oi.price,
           oi.freight_value,
           do.customer_id
    FROM olist_order_items  AS oi
    JOIN delivered_orders   AS do  ON do.order_id = oi.order_id
),
distinct_customers AS (
    SELECT i.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS customer_cnt
    FROM items              AS i
    JOIN olist_customers    AS c  ON c.customer_id = i.customer_id
    GROUP BY i.seller_id
),
profits AS (
    SELECT seller_id,
           SUM(price - freight_value) AS profit
    FROM items
    GROUP BY seller_id
),
distinct_orders AS (
    SELECT seller_id,
           COUNT(DISTINCT order_id)   AS order_cnt
    FROM items
    GROUP BY seller_id
),
five_star_reviews AS (
    SELECT i.seller_id,
           COUNT(*) AS five_star_cnt
    FROM items                AS i
    JOIN olist_order_reviews  AS r
         ON r.order_id = i.order_id
        AND r.review_score = 5
    GROUP BY i.seller_id
),
top_customer AS (
    SELECT seller_id,
           customer_cnt
    FROM distinct_customers
    ORDER BY customer_cnt DESC, seller_id
    LIMIT 1
),
top_profit AS (
    SELECT seller_id,
           profit
    FROM profits
    ORDER BY profit DESC, seller_id
    LIMIT 1
),
top_orders AS (
    SELECT seller_id,
           order_cnt
    FROM distinct_orders
    ORDER BY order_cnt DESC, seller_id
    LIMIT 1
),
top_reviews AS (
    SELECT seller_id,
           five_star_cnt
    FROM five_star_reviews
    ORDER BY five_star_cnt DESC, seller_id
    LIMIT 1
)

SELECT 'Most distinct customers' AS description,
       seller_id,
       customer_cnt             AS value
FROM top_customer

UNION ALL
SELECT 'Highest profit',
       seller_id,
       ROUND(profit, 4)         AS value
FROM top_profit

UNION ALL
SELECT 'Most distinct orders',
       seller_id,
       order_cnt                AS value
FROM top_orders

UNION ALL
SELECT 'Most 5-star reviews',
       seller_id,
       five_star_cnt            AS value
FROM top_reviews;