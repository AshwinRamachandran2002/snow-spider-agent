WITH delivered AS (
    SELECT "order_id",
           "customer_id"
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
),
profit AS (
    SELECT oi."seller_id",
           SUM(oi."price" - oi."freight_value") AS total_profit
    FROM   "olist_order_items" AS oi
    JOIN   delivered           AS d  ON d."order_id" = oi."order_id"
    GROUP BY oi."seller_id"
),
customers AS (
    SELECT oi."seller_id",
           COUNT(DISTINCT cu."customer_unique_id") AS distinct_customers
    FROM   "olist_order_items" AS oi
    JOIN   delivered           AS d  ON d."order_id" = oi."order_id"
    JOIN   "olist_customers"   AS cu ON cu."customer_id" = d."customer_id"
    GROUP BY oi."seller_id"
),
orders AS (
    SELECT oi."seller_id",
           COUNT(DISTINCT oi."order_id") AS distinct_orders
    FROM   "olist_order_items" AS oi
    JOIN   delivered           AS d  ON d."order_id" = oi."order_id"
    GROUP BY oi."seller_id"
),
five_star AS (
    SELECT oi."seller_id",
           COUNT(DISTINCT r."review_id") AS five_star_reviews
    FROM   "olist_order_items"   AS oi
    JOIN   delivered             AS d  ON d."order_id" = oi."order_id"
    JOIN   "olist_order_reviews" AS r  ON r."order_id" = d."order_id"
    WHERE  r."review_score" = 5
    GROUP BY oi."seller_id"
)

SELECT 'Most distinct customer unique IDs' AS achievement,
       c."seller_id",
       c."distinct_customers"           AS value
FROM   customers AS c
WHERE  c."distinct_customers" = (SELECT MAX(distinct_customers) FROM customers)

UNION ALL
SELECT 'Highest profit',
       p."seller_id",
       ROUND(p."total_profit", 4)       AS value
FROM   profit AS p
WHERE  p."total_profit" = (SELECT MAX(total_profit) FROM profit)

UNION ALL
SELECT 'Most distinct orders',
       o."seller_id",
       o."distinct_orders"              AS value
FROM   orders AS o
WHERE  o."distinct_orders" = (SELECT MAX(distinct_orders) FROM orders)

UNION ALL
SELECT 'Most 5-star ratings',
       f."seller_id",
       f."five_star_reviews"            AS value
FROM   five_star AS f
WHERE  f."five_star_reviews" = (SELECT MAX(five_star_reviews) FROM five_star);