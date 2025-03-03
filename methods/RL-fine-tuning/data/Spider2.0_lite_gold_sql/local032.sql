SELECT 'Highest_number_of_distinct_customers' AS Metric,
       seller_id,
       CAST(num_customers AS INTEGER) AS Value
FROM (
    SELECT oi."seller_id" AS seller_id,
           COUNT(DISTINCT o."customer_id") AS num_customers
    FROM "olist_order_items" AS oi
    JOIN "olist_orders" AS o ON oi."order_id" = o."order_id"
    GROUP BY oi."seller_id"
    ORDER BY num_customers DESC
    LIMIT 1
)
UNION ALL
SELECT 'Highest_profit' AS Metric,
       seller_id,
       ROUND(total_profit, 4) AS Value
FROM (
    SELECT "seller_id",
           SUM("price") AS total_profit
    FROM "olist_order_items"
    GROUP BY "seller_id"
    ORDER BY total_profit DESC
    LIMIT 1
)
UNION ALL
SELECT 'Highest_number_of_distinct_orders' AS Metric,
       seller_id,
       CAST(num_orders AS INTEGER) AS Value
FROM (
    SELECT "seller_id",
           COUNT(DISTINCT "order_id") AS num_orders
    FROM "olist_order_items"
    GROUP BY "seller_id"
    ORDER BY num_orders DESC
    LIMIT 1
)
UNION ALL
SELECT 'Most_5_star_ratings_in_delivered_orders' AS Metric,
       seller_id,
       CAST(num_5_star_ratings AS INTEGER) AS Value
FROM (
    SELECT oi."seller_id" AS seller_id,
           COUNT(*) AS num_5_star_ratings
    FROM "olist_order_items" AS oi
    JOIN "olist_orders" AS o ON oi."order_id" = o."order_id"
    JOIN "olist_order_reviews" AS orv ON o."order_id" = orv."order_id"
    WHERE o."order_status" = 'delivered' AND orv."review_score" = 5
    GROUP BY oi."seller_id"
    ORDER BY num_5_star_ratings DESC
    LIMIT 1
)