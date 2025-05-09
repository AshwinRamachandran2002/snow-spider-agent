WITH
  num_customers AS (
    SELECT i."seller_id", COUNT(DISTINCT o."customer_id") AS Value
    FROM "olist_order_items" i
    JOIN "olist_orders" o ON i."order_id" = o."order_id"
    GROUP BY i."seller_id"
    ORDER BY Value DESC
    LIMIT 1
  ),
  total_profit AS (
    SELECT "seller_id", ROUND(SUM("price"), 4) AS Value
    FROM "olist_order_items"
    GROUP BY "seller_id"
    ORDER BY Value DESC
    LIMIT 1
  ),
  num_orders AS (
    SELECT "seller_id", COUNT(DISTINCT "order_id") AS Value
    FROM "olist_order_items"
    GROUP BY "seller_id"
    ORDER BY Value DESC
    LIMIT 1
  ),
  num_5_star_ratings AS (
    SELECT i."seller_id", COUNT(*) AS Value
    FROM "olist_order_items" i
    JOIN "olist_orders" o ON i."order_id" = o."order_id"
    JOIN "olist_order_reviews" r ON o."order_id" = r."order_id"
    WHERE o."order_status" = 'delivered' AND r."review_score" = 5
    GROUP BY i."seller_id"
    ORDER BY Value DESC
    LIMIT 1
  )
SELECT 'Highest_number_of_distinct_customers' AS Metric, "seller_id", Value
FROM num_customers
UNION ALL
SELECT 'Highest_profit', "seller_id", Value
FROM total_profit
UNION ALL
SELECT 'Highest_number_of_distinct_orders', "seller_id", Value
FROM num_orders
UNION ALL
SELECT 'Most_5_star_ratings_in_delivered_orders', "seller_id", Value
FROM num_5_star_ratings;