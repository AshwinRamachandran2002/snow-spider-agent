WITH delivered_items AS (
    SELECT
        oi.order_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.customer_id
    FROM olist_order_items AS oi
    JOIN olist_orders      AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
customer_map AS (
    SELECT customer_id,
           customer_unique_id
    FROM olist_customers
),
five_star_orders AS (
    SELECT DISTINCT order_id
    FROM olist_order_reviews
    WHERE review_score = 5
),

-- A) seller with most distinct customers
distinct_customers AS (
    SELECT di.seller_id,
           COUNT(DISTINCT cm.customer_unique_id) AS value
    FROM delivered_items di
    JOIN customer_map cm ON cm.customer_id = di.customer_id
    GROUP BY di.seller_id
),
max_distinct AS (
    SELECT 'most_distinct_customers' AS description,
           seller_id,
           value
    FROM distinct_customers
    WHERE value = (SELECT MAX(value) FROM distinct_customers)
    ORDER BY seller_id
    LIMIT 1
),

-- B) seller with highest profit
profits AS (
    SELECT seller_id,
           ROUND(SUM(price - freight_value), 4) AS value
    FROM delivered_items
    GROUP BY seller_id
),
max_profit AS (
    SELECT 'highest_profit' AS description,
           seller_id,
           value
    FROM profits
    WHERE value = (SELECT MAX(value) FROM profits)
    ORDER BY seller_id
    LIMIT 1
),

-- C) seller with most distinct orders
distinct_orders AS (
    SELECT seller_id,
           COUNT(DISTINCT order_id) AS value
    FROM delivered_items
    GROUP BY seller_id
),
max_orders AS (
    SELECT 'most_distinct_orders' AS description,
           seller_id,
           value
    FROM distinct_orders
    WHERE value = (SELECT MAX(value) FROM distinct_orders)
    ORDER BY seller_id
    LIMIT 1
),

-- D) seller with most 5‑star reviews
five_stars AS (
    SELECT di.seller_id,
           COUNT(*) AS value
    FROM delivered_items di
    JOIN five_star_orders fso ON fso.order_id = di.order_id
    GROUP BY di.seller_id
),
max_5stars AS (
    SELECT 'most_5_star_reviews' AS description,
           seller_id,
           value
    FROM five_stars
    WHERE value = (SELECT MAX(value) FROM five_stars)
    ORDER BY seller_id
    LIMIT 1
)

SELECT * FROM max_distinct
UNION ALL
SELECT * FROM max_profit
UNION ALL
SELECT * FROM max_orders
UNION ALL
SELECT * FROM max_5stars;