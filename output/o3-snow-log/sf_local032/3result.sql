WITH delivered_order_items AS (
    SELECT 
        oi."seller_id",
        oi."order_id",
        o."customer_id",
        c."customer_unique_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"       o   ON oi."order_id" = o."order_id"
                                                                             AND o."order_status" = 'delivered'
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"    c   ON o."customer_id" = c."customer_id"
),
-- seller with the most distinct customer unique IDs
most_distinct_customers AS (
    SELECT 
        "seller_id",
        COUNT(DISTINCT "customer_unique_id") AS "metric_value"
    FROM delivered_order_items
    GROUP BY "seller_id"
    ORDER BY "metric_value" DESC NULLS LAST
    LIMIT 1
),
-- seller with the highest total profit (price – freight)
highest_profit AS (
    SELECT 
        "seller_id",
        SUM("price" - "freight_value") AS "metric_value"
    FROM delivered_order_items
    GROUP BY "seller_id"
    ORDER BY "metric_value" DESC NULLS LAST
    LIMIT 1
),
-- seller with the most distinct orders
most_distinct_orders AS (
    SELECT 
        "seller_id",
        COUNT(DISTINCT "order_id") AS "metric_value"
    FROM delivered_order_items
    GROUP BY "seller_id"
    ORDER BY "metric_value" DESC NULLS LAST
    LIMIT 1
),
-- seller with the most 5-star reviews
most_five_star AS (
    SELECT 
        doi."seller_id",
        COUNT(DISTINCT doi."order_id") AS "metric_value"
    FROM delivered_order_items                               doi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS" rev
         ON doi."order_id" = rev."order_id"
    WHERE rev."review_score" = 5
    GROUP BY doi."seller_id"
    ORDER BY "metric_value" DESC NULLS LAST
    LIMIT 1
)

SELECT "seller_id",
       "metric_value",
       'Most Distinct Customer Unique IDs'   AS "achievement"
FROM most_distinct_customers

UNION ALL

SELECT "seller_id",
       "metric_value",
       'Highest Profit (Price - Freight)'    AS "achievement"
FROM highest_profit

UNION ALL

SELECT "seller_id",
       "metric_value",
       'Most Distinct Orders'                AS "achievement"
FROM most_distinct_orders

UNION ALL

SELECT "seller_id",
       "metric_value",
       'Most 5-Star Ratings'                 AS "achievement"
FROM most_five_star;