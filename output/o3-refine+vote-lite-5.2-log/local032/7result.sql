WITH delivered_items AS (
    SELECT 
        oi.order_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.customer_id
    FROM olist_order_items  AS oi
    JOIN olist_orders       AS o  ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
customers_per_seller AS (
    SELECT 
        di.seller_id,
        COUNT(DISTINCT c.customer_unique_id) AS metric_value
    FROM delivered_items      AS di
    JOIN olist_customers      AS c  ON c.customer_id = di.customer_id
    GROUP BY di.seller_id
),
profit_per_seller AS (
    SELECT 
        di.seller_id,
        SUM(di.price - di.freight_value)      AS metric_value
    FROM delivered_items AS di
    GROUP BY di.seller_id
),
orders_per_seller AS (
    SELECT 
        di.seller_id,
        COUNT(DISTINCT di.order_id)           AS metric_value
    FROM delivered_items AS di
    GROUP BY di.seller_id
),
five_stars_per_seller AS (
    SELECT 
        di.seller_id,
        COUNT(r.review_id)                    AS metric_value
    FROM delivered_items      AS di
    JOIN olist_order_reviews  AS r  ON r.order_id = di.order_id
    WHERE r.review_score = 5
    GROUP BY di.seller_id
),

max_customers AS (
    SELECT seller_id,
           metric_value,
           'most_distinct_customers' AS description
    FROM customers_per_seller
    ORDER BY metric_value DESC, seller_id
    LIMIT 1
),
max_profit AS (
    SELECT seller_id,
           metric_value,
           'highest_profit'          AS description
    FROM profit_per_seller
    ORDER BY metric_value DESC, seller_id
    LIMIT 1
),
max_orders AS (
    SELECT seller_id,
           metric_value,
           'most_distinct_orders'    AS description
    FROM orders_per_seller
    ORDER BY metric_value DESC, seller_id
    LIMIT 1
),
max_five_star AS (
    SELECT seller_id,
           metric_value,
           'most_five_star_reviews'  AS description
    FROM five_stars_per_seller
    ORDER BY metric_value DESC, seller_id
    LIMIT 1
)

SELECT * FROM max_customers
UNION ALL
SELECT * FROM max_profit
UNION ALL
SELECT * FROM max_orders
UNION ALL
SELECT * FROM max_five_star;