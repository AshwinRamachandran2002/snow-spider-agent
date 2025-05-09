WITH delivered_items AS (          -- items that belong to *delivered* orders
    SELECT 
        oi.order_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.customer_id
    FROM olist_order_items  oi
    JOIN olist_orders       o  ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
per_seller AS (                   -- aggregate the needed indicators per seller
    SELECT
        di.seller_id,
        COUNT(DISTINCT cu.customer_unique_id)                               AS distinct_customers,
        SUM(di.price - di.freight_value)                                    AS profit,
        COUNT(DISTINCT di.order_id)                                         AS distinct_orders,
        COUNT(DISTINCT CASE WHEN rv.review_score = 5 THEN di.order_id END)  AS five_star_reviews
    FROM delivered_items           di
    LEFT JOIN olist_customers      cu ON cu.customer_id = di.customer_id
    LEFT JOIN olist_order_reviews  rv ON rv.order_id   = di.order_id
    GROUP BY di.seller_id
),
max_customers AS (
    SELECT seller_id, distinct_customers
    FROM   per_seller
    ORDER BY distinct_customers DESC, seller_id
    LIMIT 1
),
max_profit AS (
    SELECT seller_id, profit
    FROM   per_seller
    ORDER BY profit DESC, seller_id
    LIMIT 1
),
max_orders AS (
    SELECT seller_id, distinct_orders
    FROM   per_seller
    ORDER BY distinct_orders DESC, seller_id
    LIMIT 1
),
max_five_star AS (
    SELECT seller_id, five_star_reviews
    FROM   per_seller
    ORDER BY five_star_reviews DESC, seller_id
    LIMIT 1
)
SELECT 'most_distinct_customers' AS achievement, seller_id, distinct_customers AS value
FROM   max_customers

UNION ALL
SELECT 'highest_profit',         seller_id, ROUND(profit,4)                 AS value
FROM   max_profit

UNION ALL
SELECT 'most_distinct_orders',   seller_id, distinct_orders                 AS value
FROM   max_orders

UNION ALL
SELECT 'most_five_star_reviews', seller_id, five_star_reviews               AS value
FROM   max_five_star;