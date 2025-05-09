WITH delivered_orders AS (         -- only orders that were really delivered
    SELECT o.order_id,
           o.customer_id,
           c.customer_unique_id
    FROM   olist_orders   o
    JOIN   olist_customers c  ON c.customer_id = o.customer_id
    WHERE  o.order_status = 'delivered'
),
order_items_delivered AS (         -- each delivered item with customer & seller info
    SELECT d.order_id,
           d.customer_unique_id,
           oi.seller_id,
           oi.price,
           oi.freight_value
    FROM   delivered_orders d
    JOIN   olist_order_items oi ON oi.order_id = d.order_id
),

/* --- metrics per seller -------------------------------------------------- */
seller_customer_cnt AS (
    SELECT seller_id,
           COUNT(DISTINCT customer_unique_id) AS distinct_customers
    FROM   order_items_delivered
    GROUP  BY seller_id
),
seller_order_cnt AS (
    SELECT seller_id,
           COUNT(DISTINCT order_id) AS distinct_orders
    FROM   order_items_delivered
    GROUP  BY seller_id
),
seller_profit AS (
    SELECT seller_id,
           SUM(price - freight_value)            AS profit
    FROM   order_items_delivered
    GROUP  BY seller_id
),
seller_5stars AS (                 -- count distinct orders with 5‑star review
    SELECT oid.seller_id,
           COUNT(DISTINCT oid.order_id)          AS five_star_reviews
    FROM   order_items_delivered  oid
    JOIN   olist_order_reviews    r
           ON r.order_id = oid.order_id
          AND r.review_score = 5
    GROUP  BY oid.seller_id
),

/* --- pick the top seller for every metric -------------------------------- */
best_distinct_customers AS (
    SELECT 'highest_distinct_customers' AS achievement,
           seller_id,
           distinct_customers           AS metric_value
    FROM   seller_customer_cnt
    ORDER  BY distinct_customers DESC, seller_id
    LIMIT 1
),
best_profit AS (
    SELECT 'highest_profit'             AS achievement,
           seller_id,
           profit                        AS metric_value
    FROM   seller_profit
    ORDER  BY profit DESC, seller_id
    LIMIT 1
),
best_distinct_orders AS (
    SELECT 'highest_distinct_orders'    AS achievement,
           seller_id,
           distinct_orders              AS metric_value
    FROM   seller_order_cnt
    ORDER  BY distinct_orders DESC, seller_id
    LIMIT 1
),
best_5stars AS (
    SELECT 'most_5_star_reviews'        AS achievement,
           seller_id,
           five_star_reviews            AS metric_value
    FROM   seller_5stars
    ORDER  BY five_star_reviews DESC, seller_id
    LIMIT 1
)

/* --- final result -------------------------------------------------------- */
SELECT * FROM best_distinct_customers
UNION ALL
SELECT * FROM best_profit
UNION ALL
SELECT * FROM best_distinct_orders
UNION ALL
SELECT * FROM best_5stars;