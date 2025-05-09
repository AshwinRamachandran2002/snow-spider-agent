WITH delivered_orders AS (
    SELECT
        order_id,
        customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),

/* 1. number of distinct customer_unique_id per seller */
seller_customers AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT c.customer_unique_id) AS cnt_customers
    FROM olist_order_items  oi
    JOIN delivered_orders   d  ON d.order_id  = oi.order_id
    JOIN olist_customers    c  ON c.customer_id = d.customer_id
    GROUP BY oi.seller_id
),

/* 2. profit (price – freight) per seller */
seller_profit AS (
    SELECT
        oi.seller_id,
        SUM(oi.price - oi.freight_value) AS total_profit
    FROM olist_order_items  oi
    JOIN delivered_orders   d  ON d.order_id = oi.order_id
    GROUP BY oi.seller_id
),

/* 3. number of distinct orders per seller */
seller_orders AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS cnt_orders
    FROM olist_order_items  oi
    JOIN delivered_orders   d  ON d.order_id = oi.order_id
    GROUP BY oi.seller_id
),

/* 4. number of 5‑star reviews per seller */
seller_five_stars AS (
    SELECT
        oi.seller_id,
        COUNT(*) AS cnt_5stars
    FROM olist_order_items   oi
    JOIN delivered_orders    d  ON d.order_id = oi.order_id
    JOIN olist_order_reviews r  ON r.order_id = oi.order_id
    WHERE r.review_score = 5
    GROUP BY oi.seller_id
),

/* pick the best seller for each metric */
best_customers AS (
    SELECT 'Seller with most distinct customers' AS achievement,
           seller_id,
           cnt_customers AS value
    FROM seller_customers
    ORDER BY cnt_customers DESC, seller_id
    LIMIT 1
),
best_profit AS (
    SELECT 'Seller with highest profit' AS achievement,
           seller_id,
           total_profit AS value
    FROM seller_profit
    ORDER BY total_profit DESC, seller_id
    LIMIT 1
),
best_orders AS (
    SELECT 'Seller with most distinct orders' AS achievement,
           seller_id,
           cnt_orders AS value
    FROM seller_orders
    ORDER BY cnt_orders DESC, seller_id
    LIMIT 1
),
best_5stars AS (
    SELECT 'Seller with most 5‑star reviews' AS achievement,
           seller_id,
           cnt_5stars AS value
    FROM seller_five_stars
    ORDER BY cnt_5stars DESC, seller_id
    LIMIT 1
)

/* final result */
SELECT * FROM best_customers
UNION ALL
SELECT * FROM best_profit
UNION ALL
SELECT * FROM best_orders
UNION ALL
SELECT * FROM best_5stars;